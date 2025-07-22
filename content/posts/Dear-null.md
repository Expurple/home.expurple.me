+++
title = 'Dear null'
tags = ["tech"]
date = 2025-07-22
lastmod = 2025-07-22
showToc = false
summary = "Yesterday, I got an SMS from my insurance company."
+++

Yesterday, I got an SMS from my insurance company:

> Dear null, your request for a refund has been approved. The amount will be
> added to your account within two days. Thank you for choosing our services!

It's 2025. We have advanced linters and unit-test frameworks for every popular
language. We have free CI tools. We have AI code reviews. We even have AI coding
agents that can write unit tests for you! It's easy to assume that these tools
would make null-checking a breeze.

Yet, we keep making these stupid mistakes. I open `github.com`, and the front
page greets me with a new [Hugo
release](https://github.com/gohugoio/hugo/releases/tag/v0.148.1) that fixes a
[nil panic](https://github.com/gohugoio/hugo/issues/13853) (for those who don't
know Go, it's a crash caused by a null value).

Let's face it. Those tools didn't save us. Half-measures don't work. We need
stricter, formal tools that are *guaranteed* to work. You probably get where I'm
going with this.

Use a language that has an `Option`/`Optional`/`Maybe` type and <u>strictly
disallows null values anywhere else</u>! Such languages are not confined to
academia anymore. Swift is widely used on Apple platforms. Rust is used in
production by Cloudflare, Amazon, Google, and Microsoft. Both aren't going away
at this point. I don't have any experience with Swift, but Rust's tooling is
mature and blows away even the tooling available for some of the more popular
languages (C++ and Python, I'm looking at you).

To cause a similar bug in a language like Rust, you'd have to go out of your way
and intentionally write something stupid like `customer.name.unwrap_or("null")`
or `impl Default for Customer` [^dont-impl-default]. You can't just put an
`Option` into a text SMS body. You need to convert that `Option` to text. They
are not the same thing.

In this case, you wouldn't even declare `Customer.name` as an `Option` in the
first place! Some values are not supposed to be optional. Most values, in fact.
Use a language that allows you to model the domain accurately.

Get the domain model out of your head. Get it out of external docs. Get it out
of the unit tests. Put it right into the code that represents it. Let the
compiler validate the model that you've designed.

---

## Related reading

- ["Go, nil, panic, and the billion dollar
  mistake"](https://www.reddit.com/r/golang/comments/18sncxt/go_nil_panic_and_the_billion_dollar_mistake/)
- ["Type Safety Back and
  Forth"](https://www.parsonsmatt.org/2017/10/11/type_safety_back_and_forth.html)
- ["Parse, don’t
  validate"](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/)

[^dont-impl-default]: **Please don't do that**. Even if you think that it would
be convenient for unit tests or omitting optional fields... just write a
function or a builder that does the same thing. There is no such thing as a
"default customer". Don't lie to yourself, to your colleagues, and to the
compiler. And don't let Golang gaslight you.

## Discuss

- [{{< icon "hackernews" >}} Hacker
  News](https://news.ycombinator.com/item?id=44646691)
