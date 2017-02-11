---
title: "Choosing the Perfect Tech Stack"
date: 2016-03-21
author: Derrick Reimer
tags: writing
---

Nothing quite compares to greenfield software development. The canvas is blank and you finally have the opportunity to do it "The Right Way" from the ground up. If you've been building web apps for a while, you've undoubtedly found yourself working with technologies that you'd never use again, given the luxury of a blank canvas. And if you follow the open source world, there's probably a brand-spanking-new boutique framework you've been itching to take for a spin.

With all the excitement of a blank canvas comes an equal amount of anxiety. You know you are one ill-advised choice away from being stuck with the "imperfect" tech stack. You have a hunch about what you want to use, but being the dutiful engineer that you are, you spend a few hours verifying your assumptions by Googling "Ruby vs Go" and "nodejs vs haskell" only to find yourself with net loss of clarity. (Don't do that.)

Take a deep breath, it doesn't have to be this hard.

READMORE

### Stick with what you know

I know you've heard it a million times and I'm going to repeat it because it's true: any modern web stack is perfectly suitable for most web applications. Don't get me wrong, I love a good "my language is better than your language" debate as much as the next engineer. And when you scour the web for objective comparisons of different technologies, that's exactly what you will find. But the truth is, that will lead you no closer to the "right" answer because there is no right answer.

If you're a Ruby developer, build it in Ruby. If you're a PHP developer, build it in PHP. Breaking ground on your new SaaS app is probably not the best time to decide to learn a new language or framework.

In the early planning stage for [Codetree](https://codetree.com), I considered using Sinatra instead of Ruby on Rails. At the time, some members of the Ruby community were espousing that Rails is too heavy and I was beginning to buy into the hype. I had visions of a perfectly clean codebase with just the components it needed and nothing more. It was going to be *great*. And then I came to my senses.

I had never built a Sinatra app before, I was probably going to move at least 20% slower, and my volume of Stack Overflow searches was probably going to double. After all, I had spent the last three years of my work life building Rails apps and polishing my skills with that framework.

My point is not that Rails is superior to Sinatra for **everyone**, but it definitely was for **me** when as I was trying to build and launch a profitable SaaS app.

### Favor stable over new

Dan McKinley (formerly with Stripe) wrote an [excellent piece](http://mcfunley.com/choose-boring-technology) about this concept that really helped solidify my thinking on the topic. Many other titans of the tech industry have expressed [similar sentiments](https://medium.com/s-c-a-l-e/github-scaling-on-ruby-with-a-nomadic-tech-team-4db562b96dcd#.e47y62lo8).

<blockquote>
<p>We don’t need to reinvent the wheel, we don’t need to write our own databases, we don’t need to start writing our own frameworks — because they’re all in domains that are usual. It’s a website, it’s web hosting. In the domains that are unusual, we fully embrace the need to write custom applications or build bespoke apps for that.</p>
<footer>
  <cite>&mdash; Sam Lambert, Director of Technology at GitHub</cite>
</footer>
</blockquote>

Remember that brand-new framework I mentioned before? Don't use it. Especially if it's a JavaScript framework -- it'll probably be obsolete in two months anyway.

But seriously, that last thing you want to do is introduce more variability into the system than is absolutely necessary. When you are building features, finding product-market fit, and trying to get to launch, the last thing you want to worry about is a flaw in the pre-1.0-with-almost-no-documentation database system you just adopted.

<div class="embedded-tweet">
  <blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">Here&#39;s to the sane ones, the PostgreSQL-users, the troubleshooters. The placers of square pegs in square holes.</p>&mdash; Stripe (@stripe) <a href="https://twitter.com/stripe/status/582679042261843968">March 30, 2015</a></blockquote>
</div>

What's great about this approach is you've certainly worked with a handful of these "stable" technologies before. They are battle-tested, actively maintained, and you can probably find a book on them published more than 20 years ago.

### Worry about scaling later

To say software developers have the tendency to over-engineer things is an understatement. It's in our nature and I don't think it's a bad thing when channeled correctly. Writing robust, well-factored code for the sake of maintainability and stability is great. Architecting your codebase to withstand the load of millions of users while building out your minimum viable product -- not so great.

I'm sure you have been told this before. I bet it was framed like this:

<blockquote>
<p>Don't put too much effort into over-architecting your code. Chances are you wont have many users anyway. Most startups fail.
</p>
</blockquote>

I actually think that's a really lousy way to look at it. I've never bought into such a cynical argument and the logic does not play out for me. If I'm to operate as if the business is going fail anyway, should I opt to skip writing tests?

No, the reason is that no matter how experienced you are, it is impossible to foresee the exact scaling challenges you are going to encounter until you make it there. This principle is articulated well by the Extreme Programming (XP) movement.

### There is no perfect stack

The irony of it all is there is no perfect tech stack. Stop striving for perfection.

Instead, stick with what you know and avoid shiny new technologies. That will put you in the best position to tackle scaling challenges as they arise.
