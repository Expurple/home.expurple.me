+++
title = 'My Take on LLMs for Coding'
tags = ["tech"]
date = 2025-07-05
lastmod = 2025-07-16
showToc = false
summary = "Use LLMs for small, tedious tasks that you can review quickly."
+++

Originally written as an [HN
comment](https://news.ycombinator.com/item?id=44472692) on ["The Rise of
Whatever"](https://eev.ee/blog/2025/07/03/the-rise-of-whatever/):

> I disagree on LLMs being "worse than useless".
>
> Sure, "vibe coding" an entire app from a short prompt will always give you
> fragile, subtly broken nonsense. **Code is the spec**. In most cases, you
> can't meaningfully "compress" your requirements into a short informal prompt.
> **We need better formal languages for expressing requirements concisely and
> declaratively**! Think: Prolog, Haskell...
>
> **LLMs are good at small tasks that you can review much quicker than doing it
> yourself**. Something tedious, like doing some local refactoring, writing
> ad-hoc Bash scripts, SQL queries, FFmpeg commands. I use Bash and SQL
> regularly, but somehow I always have to google the exact syntax. I already use
> [ShellCheck](https://www.shellcheck.net/), by the way. It's a must, and it
> helps a lot when reviewing LLM output.
>
> I like the autocomplete feature too. It often saves time when writing
> repetitive or obvious code. `if bad_stuff {` usually autocompletes `return
> Err(BadStuff)` for me. `MyStruct {` initializer usually autocompletes the list
> of fields for me. I know that incorrect suggestions piss off some people and
> make it a net-negative for them. Incorrect suggestions are common, but they
> don't bother me in practice.

To clarify where I'm coming from. I've been using Copilot (Claude) in VSCode for
a month (full-time), and ChatGPT (sparingly) for two years before that. I mostly
write Rust.

Don't jump to conclusions after reading this post, or any other posts online.
Just try "vibe coding" yourself. Try autocomplete yourself. Try various tasks
yourself. It really doesn't take that much time to get the hang of it and form
your own opinion that's actually based on reality.

---

## Related reading

- ["AI Coding and The Peanut Butter & Jelly
  Problem"](https://iamcharliegraham.substack.com/p/ai-coding-and-the-peanut-butter-and)
- ["Why LLM-Powered Programming is More Mech Suit Than Artificial
  Human"](https://matthewsinclair.com/blog/0178-why-llm-powered-programming-is-more-mech-suit-than-artificial-human)
- ["The Rise of Whatever"](https://eev.ee/blog/2025/07/03/the-rise-of-whatever/)
  (the article that I'm commenting on, highly recommended)

## Discuss

- [{{< icon "hackernews" >}} My original comment on Hacker
  News](https://news.ycombinator.com/item?id=44472692) (the entire comment
  section is good)
