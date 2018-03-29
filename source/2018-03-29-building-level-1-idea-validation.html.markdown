---
title: "Building Level #1: Idea Validation"
date: 2018-03-29
author: Derrick Reimer
---

Over the past two weeks, I've had 21 conversations with people who are fed up with interruptive chat tools.

One sentiment, in particular, has been unanimous: everyone has expressed a willingness and desire to be involved in the process of solving this problem. In that spirit, this post is the first of many where I'll share details about the process of building Level.

READMORE

Like many who have ventured into startup land, I've learned what can happen when you assume that the problems _you_ are experiencing are the same as your target market is suffering.

My mission right now is to become as confident as possible that the product I want to build is going to resonate with my chosen niche of customers.

## Establishing the narrative

Before I could begin the validation process, I first needed to find people who are likely experiencing similar problems. My vehicle of choice for generating inbound interest was [a manifesto](http://www.derrickreimer.com/posts/the-war-on-developer-productivity/).

I spent over 10 hours writing, editing, rewriting parts, and refining some more. My Drip co-founder, Rob, played the role of editor. (If you find yourself crafting a piece like this, it helps tremendously to have a second set of eyes!)

The primary goal was to stir enough emotion in the reader to compel them to take action &mdash; in this case, to put their email address in the opt-in form with this call-to-action:

> If this resonates with you, I need your help! Drop your email address below to voice your support. I promise, no spam. I’ll keep you in the loop about new developments in my quest to solve this problem. 🌟🌟🌟

I published the manifesto on my final day at Drip (to uphold a public promise I made on my podcast) but opted to hold off actively promoting it until the following Monday when I would be available to engage with folks online.

The promotion went like this:

1. Post a tweet linking to the manifesto
2. Directly reach out to friends for a share on Twitter
3. Pour $100 into promoting the tweet
4. Share it on Hacker News and Reddit
5. Email my newsletter about it

In total, this effort drove:

- 2,300 uniques to the website
- 56 retweets
- 262 new subscribers
- A bunch of conversations

The Twitter Ads promotion was not very successful. It drove 27,000 impressions, but only 18 link clicks and 0 retweets. Next time, I would try configuring my audience rather than relying on Twitter to choose who to show the promoted tweet.

A week later, Basecamp founder David Heinemeier Hansson (DHH) serendipitously tweeted a link to the manifesto to his 286k followers:

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">“The single greatest threat to developer productivity in the modern workplace” <a href="https://t.co/yV2IehhCGh">https://t.co/yV2IehhCGh</a></p>&mdash; DHH (@dhh) <a href="https://twitter.com/dhh/status/973583032623009793?ref_src=twsrc%5Etfw">March 13, 2018</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
<br>
This tweet drove even more traffic than the initial promotion (but fewer email subscribers). As of today, 526 people have joined the list. Overall, I'm quite happy with the initial reception.

![Manifesto traffic](/images/manifesto-traffic.png)

## Talking to people

The next step was to learn more specifically about what's not working for folks. The manifesto was intentionally vague about how I'm thinking of solving the problem, so as not to introduce too much bias.

I considered emailing only a subset of the list to gauge the volume of response but decided to throw caution to the wind and send it to everyone. My goal was to book at least ten one-on-one conversations in the coming week. I was honestly not quite sure what to expect.

Here's the email copy:

```
Subject: May I ask a favor?

Hey {{ subscriber.first_name }},

It's been a whirlwind week! I officially launched the manifesto
to the world last Monday (March 5th). In case you forgot, it's the
one about The War on Developer Productivity.

You and 520 others have joined the movement so far! 🎉

Now, the real work begins. I have a bunch of ideas scribbled in my
notebook already, but I want to hear about your experience with chat
in the workplace.

What's working for you? What's not working for you?

This is your opportunity to help steer the product vision.

If you're game, click below to make your voice heard:

👉 Book 20 minutes to chat with Derrick [link]

Until next time,
Derrick
```

It turns out people were very eager to chat. Here are the email metrics:

- 80% open rate
- 30% click rate
- 8.6% conversion rate (42 bookings)

That's over 14 hours of conversations with potential customers!

I'm using [Calendly](https://calendly.com/) to manage scheduling and [Zoom](https://zoom.us/) for the video calls. I intentionally restricted them to afternoons to save my morning hours for creative work, which proved to be a wise choice.

The calls are a mix of free-form conversation and structured information gathering. It's ever-evolving, but here's what the questionnaire currently looks like:

- **May I record this call?** It's polite to ask first.
- **What is your company and what is your role?** This question helps me determine whether the person is a decision maker in their organization and helps me understand their perspective as either a maker, manager, or combo of the two.
- **How large is your team?** This one is important because, in my experience, chat tends to become increasingly chaotic as team sizes grow.
- **What tools do you use today?** I'm particularly interested in what the balance is between chat, project management, and email in their organization.
- **Why are you interested in Level? What problems do you want it to solve?** At this point, the conversation turns free-form.  My goal here is to understand the root of the problem they are experiencing.
- **What integrations do you use?** My goal with this question is to learn which integrations are essential and gauge their level of satisfaction with them.
- **Would you be willing to switch?** The idea here is to assess how entrenched they are in their current tools and what the most significant hurdles would be for switching. If the person is a not decision maker, I phrase this a bit differently.
- **Do you pay for your current tool?** This one helps me gauge their willingness to pay for Level.

I'm about halfway through the scheduled calls right now and it has been time well spent. There are a handful of ideas that keep surfacing over and over again. These are already helping to shape my assumptions about how the product ought to work. Hearing the words people use to describe their problems will help me craft impactful copy once I begin marketing the product.

My friend Ben reminded me, "Your first five customers are probably in that group." I am enjoying building personal connections with fans of the mission &mdash; one of the many advantages of being small in an industry full of giants.

## Next steps

I've been working on a prototype in my spare time over last few months, mostly to play with a new technology stack (more details on that in a future post). To avoid introducing unnecessary inertia, I will likely start with a fresh repository and harvest parts from the prototype as needed.

Before getting too deep into writing code, I'm planning to work with my designer to nail down some concrete UI flows. I'm a fan of the design-first approach, and I'm eager to share more details with folks to keep the feedback cycle tight.

Until next time!
