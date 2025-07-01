+++
title = "Go Didn't Get Error Handling Right"
tags = ['error handling', 'tech']
date = 2025-07-01
lastmod = 2025-07-01
showToc = false
summary = "I've finally found a way to put this concisely!"
+++

I've finally [found](https://news.ycombinator.com/item?id=44419996) a way to put
this concisely:

> No, Go didn't get this right. Returning a tuple (a T *and* an error) isn't an
> appropriate tool when you want your function to return *either* a T *or* an
> error. It's a brittle hack that requires everyone to use a third-party linter
> on top. Otherwise, that tuple is handled incorrectly too frequently.
>
> All of that, because Go keeps ignoring a basic [feature from the
> 1970s](https://en.wikipedia.org/wiki/Tagged_union) that allows to you express
> the "or" relationships (and nullability).
>
> APIs that are easy to use incorrectly are bad APIs.

## Appendix

To be clear:

- It's a deep issue with the language capabilities that goes way beyond errors.
  It can't be fixed by just [changing the
  syntax](https://go.dev/blog/error-syntax).
- Exceptions don't have this issue, but they have [many other issues]({{< ref
  "/posts/rust-solves-the-issues-with-exceptions/#issues-with-exceptions"
  >}}). I don't recommend exceptions.
- I recommend the `Result`/`Either` types found in languages like Rust and
  Haskell.
- Go also got many other things wrong. Too many, in fact.
- Although, it got *some* things right and inspired progress in the field.

---

## Related reading

Other people's posts:

- ["Falling Into The Pit of
  Success"](https://blog.codinghorror.com/falling-into-the-pit-of-success/) - a
  design philosophy that's very influential on me. Similarly short.
- ["I want off Mr. Golang's Wild
  Ride"](https://fasterthanli.me/articles/i-want-off-mr-golangs-wild-ride) - a
  classic Go rant based on the same philosophy. Long, not limited to error
  handling, has specific code examples.

My other posts about error handling:

1. ["Rust Solves The Issues With Exceptions"]({{< ref
  "/posts/rust-solves-the-issues-with-exceptions/" >}})
2. ["Why Use Structured Errors in Rust Applications?"]({{< ref
  "/posts/why-use-structured-errors-in-rust-applications/" >}})
3. **"Go Didn't Get Error Handling Right"**

## Discuss

- [{{< icon "hackernews" >}} My original comment on Hacker
  News](https://news.ycombinator.com/item?id=44419996) (the entire comment
  section is good, by the way)
