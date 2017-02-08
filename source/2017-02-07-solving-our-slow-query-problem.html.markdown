---
title: "Solving Our Slow Query Problem"
date: 2017-02-07
author: Derrick Reimer
tags: tech
---

One of the core features of Drip is the ability to segment your subscriber database by tags, custom fields, events performed, campaign and workflow subscriptions, and so on.

As our Postgres dataset has grown into the multi-terabyte size range, these ad-hoc segmentation queries have become increasingly expensive to run, especially for accounts with many thousands of subscribers and millions of subscriber events.

There's really nothing magical going on under the covers. The subscriber filter in Drip works like this:

- Accept a blob of JSON from the UI that describes the criteria
- Parse the JSON data into granular conditions
- Transform the conditions into an SQL query, using a splash of [Arel](https://github.com/rails/arel)
- Execute the query and return the results

A query for "subscribers who are tagged with 'Customer'" translates approximately to:

```sql
SELECT s.* FROM subscribers s
INNER JOIN tags t ON t.subscriber_id = s.id
WHERE t.value = 'Customer'
```

A more complex query could have many different joins against large tables, and the fact that these complex queries can be generated on the fly by the user makes them particularly challenging to optimize.

## To shard, or not to shard?

The largest tables in the Drip database are the `deliveries` and `subscriber_events` tables, each nearing a billion records. A subscriber query with even a single join against one of these tables is often prohibitively slow, depending on the size of the customer's account.

The problem lies in the fact it is not feasible to hold all database indexes in RAM needed to make all the possible ad-hoc query combinations performant. Common strategies for tackling this problem include partitioning large tables by some logical key, or sharding the database entirely (using a plugin like [Citus Data](https://www.citusdata.com/)).

We explored these approaches in depth, along the way asking ourselves these questions:

- How much developer time will it require?
- How much will it cost to host?
- How many new technologies will be introduced?
- How strongly are we locked in to the approach once adopted?

Deeply ingrained in our engineering culture is an [aversion to risk](TODO: insert link to boring tech article), especially when that risk lies outside of our zone of competitive advantages. We will gladly make calculated bets when it comes to building cutting-edge marketing automation features, but much less so when it making choices about our underlying database technologies.

We determined that sharding would carry high development price tag, increase our hosting cost by an order of magnitude, and introduce a high degree of vendor lock-in. Partitioning large tables would carry similar development costs and would limit our ability to run queries that need to span all the partitions (which is part of what makes Drip so powerful).

## "Always fast" is a pipe dream

We came to another important realization as we evaluated our options. It's feasible that the largest Drip customer may someday have millions of subscribers and hundreds of millions of `deliveries` and `subscriber_events` to their name. Even if we sharded our database by account and gave this customer their own dedicated shard, their segmentation queries would _still_ be vulnerable to slowness.

Abandoning the goal of trying to make every possible query combination run quickly allowed us to reframe the question. Instead of asking "how can we make these queries always run quickly?", we started asking "how can minimize the pain our customer experience when accomplishing the task of segmenting their subscriber database?"

This led to a key observation: segments tend to be long-lived and reused many times. For example, the criteria that defines who belongs in a "Customer" segment is unlikely to change. Once defined, the user is likely to reference that segment in many different scenarios, such as when sending a broadcast email targeted to existing customers, or within a workflow decision to send customer down a different journey than non-customers.

In its current form, complex segments were guaranteed to run slowly every time they were viewed. If we could reduce that slowness to just the first time a segment is built, that would dramatically improve the user experience.

## Live caching to the rescue

We had long assumed that it was not feasible to cache the results of a segmentation query, because the tolerance threshold for stale results is extremely tight. Unlike analytics data, an invalid segment cache could result in someone receiving an email they shoudn't have, or worse, getting pruned from a subscriber database erroneously.

Questioning our initial assumption, we realized that it _is_ possible to keep the cached results fresh in realtime, provided that "recheck" segment membership anytime a subscriber event occurs. More over, we could piggyback off of our automation engine infrastructure to process these rechecks without significant development effort.

With a strategy in hand, the next step was to choose the technology for storing this cached data. The natural choice was [Redis](https://redis.io/). There were a number of qualities about Redis that made is particularly attractive:

- We are already using it aggressively for our `Rails.cache` and our [Sidekiq](http://sidekiq.org) queues
- We know how to deploy it and the potential pitfalls
- Redis sets are [countable in `O(1)` time](https://redis.io/commands/scard)
- Redis sets can be created and deleted quickly -- much quicker than deleting and inserting large batches of records in a PostgreSQL table
- Redis sets can never contain duplicate members, so pushing the same value into a set multiple times will never result in duplication

The final piece of the puzzle was crafting the user experience. Here's the flow that we settled on:

- When a user build a segment, we attempt to run the query and return the results right away. If it the query finishes within a few seconds, great!
- If the query is taking a while, then display a message to the user that we are going to compute it in the background and email them when it's ready.
- Kick off a background process that will attempt to run the SQL query with a much longer timeout. If the query finishes before timing out, stick the results in a Redis set and let the user know it's ready.
- If the query is taking a _really_ long time, fallback to a "looping" strategy where we pull out each subscriber in the account and check to see if the subscriber belongs in the segment.

## Deployment

We deliberately chose to roll out segment caching gradually. The initial version was built as an entirely new subsystem in the codebase, so there was very little risk of breaking existing segments. Rather than modify the existing `Segment` model, we created a new `LiveSegment` model with its own database table and domain logic. This allowed us to create `LiveSegment` records in many different customers' accounts and verify correctness without impacting any of their existing segments.

Once we were confident that cached segments were indeed staying in sync with the database, we migrated the caching code over to the `Segment` model and removed the transitional code. To ease with the migration, we made sure the old segment behavior remained in place if the `cached` flag was set to `false` on the segment record. In the event that a bug is discovered that a cached segment is not able to stay up-to-date, we can easily disable caching for that segment only and fallback to the old behavior.

## Moving forward

Subscriber segmentation is not the only area prone to slow queries and we've only begun to scratch surface on ways we can leverage Redis sets. In time, we plan to push more denormalized data into Redis when we need to count or check inclusion in large sets. There may come a time when it makes sense to shard our Postgres database, but until that day, Redis will be instrumental in keeping the app running fast.
