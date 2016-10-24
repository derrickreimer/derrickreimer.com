---
title: "When To Build Your Own Billing Engine"
date: 2016-10-24
author: Derrick Reimer
tags: tech
---

Back when we started [Drip](https://www.drip.co) in 2012, it was customary to write your own recurring billing engine.

Fundamentally, a SaaS billing engine is simply a scheduled task that runs each month for each customer and hits a payment API to charge them. Layered on top that is the concept of pricing tiers, trial periods, failed charge retry, proration, annual plans, and invoice generation.

Most developers these days choose not to build their own billing engine, as free platforms like Stripe subscriptions promise to rid your application code of complex billing logic. It seems like a no-brainer, right?

At [Drip](https://www.drip.co), we discovered that many of our billing needs actually fall outside the "sweet spot" of recurring billing solutions on the market today. Rather than shoehorning into Stripe subscriptions, it was simpler to manage the recurring aspect of billing ourselves alongside all the other custom logic we were implementing.

If your application shares similar billing characteristics as Drip, you may also find that building your own billing engine is the simpler option.

READMORE

## Metered plans

Drip's pricing tiers are fundamentally based on the number of subscribers in your account. At the time of writing, the "Starter" plan allows up to 100 subscribers, the "Basic" plan allows up to 2,500 subscribers, and so on. The highest published plan level we have is our "Business" plan for $149, but it doesn't stop there. When your usage exceeds 12,500 subscribers, we utilize a step function to determine your price:

```
amount = $149 + $35 * ceil((subscriber_count - 12,500) / 5,000)
```

We actually split that calculation into multiple steps, so that we can also generate a unique name for the plan and figure out the subscriber limit:

```
factor = ceil((subscriber_count - 12,500) / 5,000)
amount = $149 + $35 * factor
subscriber_limit = 12,500 + (5,000 * factor)
name = "Enterprise-#{factor}"
```

Theoretically, there are an infinite number of possible Drip plans: Enterprise-1, Enterprise-2, ... , Enterprise-100, and so on.

Another characteristic of Drip's billing engine is plan auto-adjustment. As soon as a customer exceeds the limits of their current plan, we automatically move them to a plan that fits their usage (and send them an email letting them know what happened).

Most billing platforms assume you have a discrete set of plans. While it is possible to programmatically create new plans in Stripe using the API, for example, it is still up to you to compute the plan amount in your own code. This is a big leak in the abstraction and requires your application to have deep knowledge about your pricing tiers.

## Grandfathering and price testing

We've raised prices several times over the past few years as Drip has become a more valuable platform. We are strong believers that (in most cases) you should not raise prices for existing customers -- a concept often referred to as "grandfathering". For Drip, this means making sure that if a customer gets auto-upgraded, the plan we put them on will be computed based on what the pricing structure was when they became a customer.

To make this happen, we introduced the concept of **versioned billing**. When a customer signs up, they are assigned a version number corresponding to whatever pricing is currently advertised. Each version has its own:

- Set of standard pricing tiers
- Formula for computing "enterprise" tiers
- Subscriber and broadcast sending limits

This guarantees that existing customers will never be impacted by new pricing changes (unless their version is modified). With versioning in place, you are free to experiment with new pricing structures and even A/B test them against each other without worrying about impacting existing customers.

## Annual plans

Collecting a year's worth of revenue from your customers (in exchange for a nice discount) is an excellent way to improve your cash flow and fund your growth drivers, especially if you are a self-funded company. Yet, annual billing is major challenge to pull off for companies with metered plans. This is likely why it's difficult to find any other email marketing provider with similar market positioning as Drip that offers annual plans.

Here's the challenge: suppose a customer decides to buy an annual plan while they are on our $49 plan. The customer has just paid $490 for their next year of service and does not expect to get billed for another twelve months. But if we are doing our job right, this customer is successful with Drip and cruises over the subscriber limit of the $49 plan in no time. This leaves us with a few options:

- Charge the customer right away for the prorated difference
- Eat the difference and charge the customer at the higher plan level next year

Neither of these choices are acceptable. Some of the most successful Drip customers have been known to climb three (or more) pricing tiers in the span of one month. Attempting to charge prorated amounts would make for very messy bookkeeping and might actually result in the customer getting charged more often than if they were on monthly billing. (Customers often upgrade to annual to make their bookkeeping simpler).

To overcome these obstacles at Drip, we implemented a credit-based system. When a customer upgrades to annual, they "buy" a certain amount of credit at a discounted rate. At the moment, one year of the $49 plan costs $490 and the customer is given $588 of credit on their subscription. The customer is still billed on a monthly basis, but instead of charging their credit card, we deduct their current plan amount from their credit balance.

If they get auto-upgraded, no problem -- we will just end up chipping away at their credit balance faster. This means the customer may have to end up paying again before one year has passed, but at least we are charging them at the latest possible point instead of every time they exceed their limits.

## Keeping everything in sync

When I was building [Codetree](https://codetree.com), I decided to use Stripe subscriptions because the pricing structure was much simpler than Drip's. One of the trickiest parts to manage was keeping the Codetree database in sync with the data stored in Stripe.

At a minimum, you must install a webhook to consume events from Stripe so that you will know when your subscriptions transition to different states. Although Stripe's webhooks are well-documented, I still had to write a fair amount of code to ensure that payloads were being processed correctly.

I also had to write code to handle registration, plan changes, cancellations, reactivations, and manual adjustments (like one-off trial extensions). Implementing that functionality in Drip's custom billing engine was notably simpler, because it did not involve hitting an external API for every task.

---

The objective here is not to criticize existing billing platforms, but rather to challenge the assumption that it is always easier to reach for an existing platform than build your own.

If you have a discrete set of plans that do not auto-adjust and you anticipate your business model to remain fairly stable, then adopting a platform like Stripe subscriptions is probably the way to go. But if your business model resembles Drip's, it's worth considering giving yourself the flexibility of controlling the whole billing process.
