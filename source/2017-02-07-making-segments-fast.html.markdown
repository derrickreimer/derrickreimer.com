---
title: "Making Segments Fast"
date: 2017-02-07
author: Derrick Reimer
tags: tech
---

One of the core features of Drip is the ability to segment your subscriber database by tags, custom fields, events performed, campaign and workflow subscriptions, and so on.

As our Postgres dataset has grown into the multi-terabyte size range, these ad-hoc segmentation queries have become increasingly expensive to run, especially for accounts with many thousands of subscribers and millions of subscriber events.

There's really nothing magical going on under the covers. The subscriber filter in Drip works like this:

- Accept a blob of JSON from the UI that describes the criteria
- Parse the JSON data into granular conditions
- Transform the conditions into an SQL query, using a splash of [Arel](TODO: insert link)
- Execute the query and return the results

A query for "subscribers who are tagged with 'Customer'" translates approximately to:

```
SELECT DISTINCT(*)
FROM subscribers s
INNER JOIN tags t ON t.subscriber_id = s.id
WHERE t.value = 'Customer'
```

A more complex query could have many different joins against large tables, and the fact that these complex queries can be generated on the fly by the user makes them particularly challenging to optimize.

## To shard, or not to shard?

The largest tables in the Drip database are the `deliveries` and `subscriber_events` tables, each nearing a billion records. A subscriber query with even a single join against one of these tables is often prohibitively slow, depending on the size of the customer's account.

The problem lies in the fact it is not feasible to hold all database indexes in RAM needed to make all the possible ad-hoc query combinations performant. Common strategies for tackling this problem include partitioning large tables by some logical key, or sharding the database entirely (using a plugin like [Citus Data](TODO: insert link)).

We explored these approaches in depth, along the way asking ourselves these questions:

- How much developer time will it require?
- How much will it cost to host?
- How many new technologies will be introduced?
- How strongly are we locked in to the approach once adopted?

Deeply ingrained in our engineering culture is an [aversion to risk](TODO: insert link to boring tech article), especially when that risk lies outside of our zone of competitive advantages. We will gladly make calculated bets when it comes to building cutting-edge marketing automation features, but much less so when it making choices about our underlying database technologies.

We determined that sharding would carry high development price tag, increase our hosting cost by an order of magnitude, and introduce a high degree of vendor lock-in. Partitioning large tables would carry similar development costs and would limit our ability to run queries that need to span all the partitions (which is part of what makes Drip so powerful).

## "Always fast" is a pipe dream

We came to another important realization as we evaluated our options. It's very possible the largest Drip customer may someday have millions of subscribers and hundreds of millions of `deliveries` and `subscriber_events` to their name. Even if we sharded our database by account and gave this customer their own dedicated shard, their segmentation queries would _still_ be vulnerable to slowness.

Abandoning the goal of trying to make every possible query combination run quickly allowed us to reframe the question. Instead of asking "how can we make these queries always run quickly?", we started asking "how can minimize the pain our customer experience when accomplishing the task of segmenting their subscriber database?"

That reframing led to a key observation: **users often build segments that are long-lived and can be reused many times**.

For example, the criteria that defines who belongs in a "Customer" segment is unlikely to change. Depending on the nature of the business, it's typically along the lines of "has performed the 'Made a purchase' event". Once defined, the user is likely to reference that segment in many different scenarios, such as when sending a broadcast email targeted to existing customers, or within a workflow decision to send customer down a different journey than non-customers.
