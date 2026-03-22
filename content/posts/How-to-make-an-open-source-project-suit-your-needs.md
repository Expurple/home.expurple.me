+++
title = 'How to Make an Open-Source Project Suit Your Needs'
tags = ["tech"]
date = 2026-03-22
lastmod = 2026-03-22
summary = "To fork or not to fork? How to contribute substantial changes?"
+++

I want to share a recent thread from the [SeaQL Discord
server](https://discord.gg/Bpe8D9qS).

I feel like many people have faced similar problems when interacting with
open-source projects. So, my advice from that thread should be universally
applicable.

## The original Discord thread

Yesterday, someone
[posted](https://discord.com/channels/873880840487206962/900758376164757555/1484916155528253510):

> There are lot of things I really do like about sea-orm, and there are a lot of
> design flaws and potential issues, acknowledged. I'm developing a new product
> with somewhat advanced sea-orm use, and I'd like to contribute features I'm
> personally missing, to make things work, for me. I get that "sustainable
> open-source" is a pain, and it'll take ages for my PR's to get reviewed and
> accepted, which will inevitably cause detraction for my own initiatives. I'll
> be stuck in workaround loop, for no good reason.
>
> Thus, there are two ways I can see this going:
>
> 1. I'll fork sea-orm, burn some tokens and refactor it to the best of my
>    ability, focusing only on the features I really need.
> 2. I may contribute certain features, and wait for the maintainers to follow.
>
>
> Traction isn't that great, but I don't blame anyone... "The burnout is real".
> I'll probably start refactoring things, and backport some stuff, when/if
> necessary...

Quickly echoed by another member:

> I have the almost same problem. I am migrating an existing product, which
> needs more safety and various unsupported features from posters mostly. And
> clearly pushing features I need the normal way would take way too long,
> because of reviews. Currently, it  is enough to just keep a separate branch
> where all my feature branches  are merged. But something like a big refactor
> is basically impossible in my approach.

Answered by one of the maintainers:

> I agree that the current PR review process takes a long time. But the root
> cause is that we lack enough reviewers.
>
> The best approach is to keep large refactorings within your fork and merge
> smaller features upstream. This way you won't get blocked, and we can
> gradually adopt and improve upon the changes. If you feel that certain
> features have fundamental limitations, it's best to open a discussion first.

And then by me:

> I agree with @Huli. The best approach is forking SeaORM now and gradually
> upstreaming your fork later, without getting your work blocked on the reviews.
> My work project spent months on my SeaORM fork before I got it upstreamed and
> became a maintainer.
>
> If you later find that maintaining your fork is too much work, consider
> becoming a maintainer. So that you can put that effort into reviewing other
> people's PRs instead, and allow us to review and merge your changes faster.
> Collaborating on a single upstream copy is better for everyone in the long
> run.
>
> When I became a maintainer, I didn't have to commit to any reccurring
> responisibilities at all. I just keep contributing from time to time, like I
> always have. The contributions just shifted towards reviews and advice.

## How to switch a dependency to your fork

If you work with Rust and Cargo, switching a dependency to your fork is very
easy. You literally add a [`[patch]`
section](https://doc.rust-lang.org/cargo/reference/overriding-dependencies.html#the-patch-section)
to your `Cargo.toml` file:

```toml
[patch.crates-io]
foo = { git = 'https://github.com/my-username/foo.git', branch = "my-changes" }
```

There's probably an equivalent mechanism in other languages and build systems.

## The cost of forking in 2026

Recently (since Opus 4.5), LLMs have been blowing my mind again. We're at a
point where they can autonomously make decent changes in any unfamiliar
dependency.

The value of manual peer reviews, curation, having a community around a single
upstream copy, and not having to maintain your own is still there. But LLMs are
a great way to unblock yourself.

Go ahead, fork it, and make it work for you!

---

## Related reading

- ["The Pragmatic Open Source
  Contributor"](https://diurnal.st/2025/03/02/the-pragmatic-open-source-contributor.html).
  A great, more detailed guide from the point of view of a corporate employee
  who wants to contribute.
- ["How to maintain an Open Source
  project"](https://jyn.dev/how-to-maintain-an-open-source-project/). A great
  guide from the point of view of a maintainer.
- ["Two Kinds of Code
  Review"](https://matklad.github.io/2021/01/03/two-kinds-of-code-review.html).
  Another great guide from the point of view of a maintainer.

## Discuss

- [{{< icon "discord" >}} Start of the original Discord
  thread](https://discord.com/channels/873880840487206962/900758376164757555/1484916155528253510)
- [{{< icon "hackernews" >}} Hacker
  News](https://news.ycombinator.com/item?id=47476740)
