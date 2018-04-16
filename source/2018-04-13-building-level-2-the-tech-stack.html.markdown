---
title: "Building Level #2: The Tech Stack"
date: 2018-04-13
author: Derrick Reimer
description: "Learn about how I'm using Elixir, Elm, GraphQL, Tailwind CSS, and more in Level."
---

For the last nine months, I've been building a prototype of Level.

The reason is two-fold: I needed an environment in which to play with product ideas swirling around in my head, and I wanted to gain experience with some new technologies.

I've long been a proponent of [choosing "boring" technologies](/posts/choosing-the-perfect-tech-stack/), especially when starting a new project that already has inherent risk. However, that doesn't mean you should _never_ learn new languages and frameworks, especially if the new stack appears to fit the problem space better.

Building the prototype was a way for me to gain confidence in my technology choices. Although it is not a perfect implementation of the product, it's a close enough approximation to get a feel for where pieces of the stack shine and where things get a little hairy.

READMORE

Elm's promise of painless refactoring and zero runtime errors looks very appealing. But what does it feel like to write front-end code in a functional language? And how does the Elm Architecture scale for a single-page app with a significant amount of state to manage?

These types of questions are not able to be answered by implementing "Hello World" or running through getting started tutorials. I had to get my hands dirty to find out for myself.

After months of experimentation, I now feel confident that I have the Level stack nailed down.

## Elixir & Phoenix

Elixir initially appealed to me for many reasons:

- The syntax feels like Ruby.
- It is inherently more performant than Ruby, given the same quantity of system resources.
- It's a functional language with immutable data structures and powerful pattern matching. (I've personally grown a bit weary from mutability over the years.)
- It has a native test framework, vibrant package ecosystem, and build tooling.
- The community is active.
- It is excellent at [handling many simultaneous connections](http://phoenixframework.org/blog/the-road-to-2-million-websocket-connections).
- Erlang (the underlying language) powers large portions of global telecommunication infrastructure and has been around for decades.

Fervent support from [thoughtbot](https://thoughtbot.com/services/elixir-phoenix), an industry leader that I highly respect, also encouraged me to give it a try:

> Elixir/Phoenix is now my default choice for greenfield web applications. I would only choose to use Rails in cases where necessary libraries for a project did not yet exist in Elixir. And even then, I’d consider writing them.
>
> &mdash; Derek Prior

Phoenix is the de-facto web framework in the Elixir world, for good reasons. It's blazing fast, and its tooling feels quite similar to Rails.

One of trickiest parts of the functional paradigm is figuring out how to organize your code. A few months into my experimentation period, the team released [Phoenix 1.3](http://phoenixframework.org/blog/phoenix-1-3-0-released) which centered around improving project structure with [contexts](https://hexdocs.pm/phoenix/contexts.html). This release gave me much needed clarity on how to design a maintainable functional codebase.

## Elm

Most of the time, I'm a proponent of server-side rendered HTML for web applications. I'm of the mind that client-side rendering is usually unnecessary and only overcomplicates the architecture.

Here are my key criteria for determining whether it makes sense to consider building a single-page app:

- Is the core of application real-time?
- Will the application remain open for hours at a time without page refreshes?
- Is microsecond performance critical for most interactions?
- Is there a significant amount of state shared between most pages?

For Level, the answer to all of these is yes.

It's not _impossible_ to service all these requirements with a healthy dose of caching and frameworks like [Turbolinks](https://github.com/turbolinks/turbolinks). But, I believe there is a threshold beyond which it becomes more complicated to stick with the server-side approach once the amount of state becomes sufficiently complex.

Choosing a front-end framework is an act of gambling. I've witnessed many colleagues invest in the hottest new frameworks, only to see them become abandoned. I can imagine how many millions of dollars companies have wasted on rewrites.

As you might imagine, I was not looking forward to rolling the dice for Level. Then I discovered [Elm](http://elm-lang.org/).

Elm is a Haskell-inspired functional language that compiles into JavaScript. It is famously impossible to generate a runtime exception in Elm because of the type system and compiler. Writing Elm feels almost nothing like writing JavaScript (and I'm personally not sad about that).

A big selling point for me is that there is no need for external frameworks (like React) in the Elm world. The core libraries know how to render HTML and perform all the various tasks you need for web apps (like making HTTP requests). In fact, the Elm Architecture was a big inspiration for Redux, the state management library for JavaScript.

The most prominent risk with Elm is the question of longevity: will Elm be around for the long haul? It's hard to say for sure, but there is an ever-growing list of well-resourced companies using Elm in production, and the creator has spoken at length about his long-term vision for the language.

## GraphQL

GraphQL is an API query language developed by Facebook. It works a bit differently than typical REST APIs:

- Operations take place through a single endpoint
- Queries specify what fields they want to be returned
- You can fetch related nodes in a single call (hence the "graph")
- It has a type system

I'll use an example to demonstrate the power of GraphQL.

Say you have a `Post` resource that belongs to a `User` and you want to list out all posts with their associated user's name. The GraphQL query might look something like this:

```
{
  posts {
    body
    user {
      name
    }
  }
}
```

And the response would look like this:

```
{
  "data": {
    "posts": [{
      "body": "Hello Jane!",
      "user": {
        "name": "John Doe"
      }
    }, {
      "body": "Hi John!",
      "user": {
        "name": "Jane Doe"
      }
    }]
  }
}
```

To perform a similar operation with a standard REST API, you might hit a `/posts` endpoint that returns an array of data like this:

```
[{
  "id": 123456,
  "user_id": 54321,
  "body": "Hello Jane!",
  "title": "Greetings",
  "inserted_at": "2018-04-12T12:00:00Z"
}, ...
]
```

To get the user's name, we would then need to hit a `/users/:user_id` route for each user and receive back all the data for each user (even though we only care about their name).

Since this results in a lot of roundtrips, a typical way to mitigate this is to include a portion of the related user's data in the post payload:

```
[{
  "id": 123456,
  "user_id": 54321,
  "body": "Hello Jane!",
  "title": "Greetings",
  "inserted_at": "2018-04-12T12:00:00Z",
  "user": {
    "name": "John Doe"
  }
}, ...
]
```

The problem with this approach is that it _couples_ your API design to your specific use cases. As more use cases stack up, the tendency is to continue adding more fields to the payload until it becomes a bloated mess.

Furthermore, it's impossible to envision all the ways users will want to crawl their data, which is one of the reasons why leading platforms like GitHub, Shopify, and Facebook have begun adopting GraphQL for their public APIs.

I have found GraphQL to be a delight to work with, and Elixir support via the [Absinthe](http://absinthe-graphql.org/) library is fantastic.

## Miscellanea

I'd be remiss if I didn't mention a few other key dependencies:

- [PostgreSQL](https://www.postgresql.org/) for data storage
- [Tailwind CSS](https://tailwindcss.com/) for building the design system
- [Yarn](https://yarnpkg.com/en/) for managing node dependencies

I could probably write several thousand more words about the various technologies in Level, but alas I must go forth and build!

If you're interested, [take a spin through the actual Level codebase on GitHub](https://github.com/levelhq/level)!
