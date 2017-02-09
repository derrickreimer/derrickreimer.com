---
title: "Solving Our Slow Query Problem"
date: 2017-02-09
author: Derrick Reimer
tags: tech
---

One of the core features of Drip is the ability to segment your subscriber database by tags, custom fields, events performed, campaign and workflow subscriptions, and so on.

As our Postgres dataset has grown into the multi-terabyte size range, these ad-hoc segmentation queries have become increasingly expensive to run, especially for accounts with many thousands of subscribers and millions of subscriber events.

There's really nothing magical going on under the covers. The subscriber filter in Drip works like this:

- Accept a blob of JSON from the UI that describes the criteria
- Parse the JSON data into individual conditions
- Transform the conditions into an SQL query with the help of [Arel](https://github.com/rails/arel)
- Execute the query and return the results

A query for "subscribers who are tagged with 'Customer'" roughly translates to:

```sql
SELECT s.* FROM subscribers s
INNER JOIN tags t ON t.subscriber_id = s.id
WHERE t.value = 'Customer'
```

A more complex query could have many different `JOIN` clauses with large tables, and the fact that these complex queries can be generated on the fly by the user makes them particularly challenging to optimize.

READMORE

## To shard, or not to shard?

The largest tables in the Drip database are the `deliveries` and `subscriber_events` tables, each nearing a billion records. A subscriber query with even a single `JOIN` against one of these tables is often prohibitively slow, depending on the size of the customer's account.

The problem is rooted in the fact it is not feasible to hold all database indexes in RAM needed to make all the possible ad-hoc query combinations performant. Common strategies for tackling this problem include partitioning large tables by some logical key, or sharding the database entirely (using a plugin like [Citus Data](https://www.citusdata.com/)).

We explored these approaches in depth, along the way asking ourselves these questions:

- How much developer time will it require?
- How much will it cost to host?
- How many new technologies will be introduced?
- How strongly are we locked in to the approach once adopted?

Deeply ingrained in our engineering culture is an [aversion to risk](http://www.scalingsaas.com/posts/choosing-the-perfect-tech-stack/), especially when that risk lies outside of our zone of competitive advantages. We will gladly make calculated bets when it comes to building cutting-edge marketing automation features, but much less so when making choices about our database technologies.

We determined that sharding would carry a high development price tag, increase our hosting cost by an order of magnitude, and introduce a high degree of vendor lock-in. Partitioning large tables would carry similar development costs and would limit our ability to run queries that need to span all the partitions (which is part of what makes Drip so powerful).

## "Always fast" is a pipe dream

We came to another important realization as we evaluated our options. It's feasible that the largest Drip customer may someday have millions of subscribers and hundreds of millions of `deliveries` and `subscriber_events` to their name. Even if we sharded our database by account and gave this customer their own dedicated shard, their segmentation queries would _still_ be vulnerable to slowness.

Abandoning the goal of trying to make every possible query combination run quickly allowed us to reframe the question. Instead of asking "how can we make these queries always run quickly?", we started asking "how can we minimize the pain our customers experience when segmenting their subscriber database?"

Segments tend to be long-lived and reused many times. For example, the criteria that defines who belongs in a "Customer" segment is unlikely to change. Once defined, the user is likely to reference that segment in many different scenarios, such as when sending a broadcast email targeted to existing customers, or within a workflow decision to send customers down a different journey than non-customers.

In its current form, complex segments were guaranteed to run slowly every time they were viewed. If we could reduce that slowness to just the first time a segment is built, that would dramatically improve the user experience.

## Live caching to the rescue

We had long assumed that it was not feasible to cache the results of a segmentation query because it is unacceptable to ever return stale results. Unlike analytics data, which can be a few hours behind realtime without much consequence, an invalid segment cache could result in someone receiving an email they shouldn't have, or worse, getting pruned from a subscriber database erroneously.

Questioning our initial assumption, we realized that it _is_ possible to keep the cached results fresh in realtime, provided that we "recheck" segment membership anytime a subscriber event occurs. With a strategy in hand, the next step was to choose the technology for storing this cached data. We considered using Postgres, but ultimately settled on [Redis](https://redis.io/).

The [sorted](https://redis.io/commands#sorted_set) and [unsorted](https://redis.io/commands#set) set data types are the killer features that made us choose Redis:

- They are [countable in `O(1)` time](https://redis.io/commands/scard), meaning they take the same amount of time to count regardless of the number of members
- They can be created and deleted much more quickly than inserting and deleting large batches of records in Postgres
- They will never contain duplicate members, even if the same member is "added" multiple times

The final piece of the puzzle was crafting the user experience. Here's the flow that we settled on:

- When a user builds a segment, attempt to run the query and return the results right away. If the query finishes within a few seconds, great!
- If the query is taking a while, display a message to the user that we are going to compute it in the background and email them when it's ready.
- Kick off a background process that will attempt to run the SQL query with a much longer timeout. If the query _still_ times out (some queries are so complicated they will run for hours without completing), fallback to a "looping" strategy where we pull out each subscriber in the account and check to see if the subscriber belongs in the segment.
- Send the user an email with a link when the segment is ready to view. From that point forward, the cached segment will load instantaneously.

## Deployment

We deliberately chose to roll out segment caching gradually. The initial version was built as an entirely new subsystem in the codebase, so there was very little risk of breaking existing segments. Rather than modify the existing `Segment` model, we created a new `LiveSegment` model with its own database table and domain logic. This allowed us to create `LiveSegment` records in many different customers' accounts and verify correctness without impacting any of their existing segments.

Once we were confident that cached segments were indeed staying up-to-date, we migrated the caching code over to the existing `Segment` model. We made sure the old behavior remained in place if the `cached` flag is set to `false` on the segment record so we can easily disable caching for specific segments if a bug is discovered.

Since this use of Redis is distinct from our ephemeral caching (segment cache data needs to stick around indefinitely) and Sidekiq queues, we spun up a dedicated cluster of Redis servers that we call our "persistent Redis" store -- more details on that to come in a future post.

## Moving forward

Subscriber segmentation is not the only area prone to slow queries and we've only begun to scratch surface on ways we can leverage Redis sets. In time, we plan to push more denormalized data into Redis when we need to count or check inclusion in large sets. There may come a time when it makes sense to shard our Postgres database, but until that day, Redis will be instrumental in keeping the app running fast.
