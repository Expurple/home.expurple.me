+++
title = 'A Big Standard Library Is Overkill'
tags = ["rust", "tech"]
date = 2026-07-02
lastmod = 2026-07-02
showToc = false
summary = "Securing the supply chain without cementing the APIs."
+++

To solve the problems of "supply chain security" and "relying on a random person
in Nebraska", it's enough to maintain our libraries of interest under the same
"trusted" org that maintains the stdlib.

*Actually including all that code in the stdlib* is unnecessary and harmful,
because it imposes strict compatibility guarantees and keeps us stuck with an
old API even after a better one is discovered. See any standard datetime library
or any of Python's "dead batteries".

Examples of doing this right:

- [`golang.org/x/...`](https://go.dev/wiki/X-Repositories) repositories.
- Several prominent "third-party" Rust crates (such as
  [`libc`](https://github.com/rust-lang/libc),
  [`rand`](https://github.com/rust-lang/rand), and
  [`regex`](https://github.com/rust-lang/regex)) have been moved under the
  official [`rust-lang`](https://github.com/rust-lang/) org.

---

[The raw number of dependencies in a project is
meaningless](https://wiki.alopex.li/LetsBeRealAboutDependencies).

Having to specify your dependencies in a manifest and download them over the
internet is not a problem in itself.

Ecosystem fragmentation is a problem, but only for common, fundamental
interfaces. Those should be included in the standard library.

Relying on arbitrary third parties is a problem, but it can be solved without
pushing everything into the standard library.

One other solution is an audit database like
[`cargo-vet`](https://github.com/mozilla/cargo-vet) and
[`cargo-crev`](https://github.com/crev-dev/cargo-crev), where you can "delegate"
and automatically trust someone else's audits. You can trust one auditor instead
of many individual authors.

---

## Related reading

- [{{< icon "reddit" >}} A related "supply chain" thread that prompted this
  post](https://www.reddit.com/r/rust/comments/1sjh4no/no_one_owes_you_supplychain_security/)
- [LetsBeRealAboutDependencies](https://wiki.alopex.li/LetsBeRealAboutDependencies)

## Discuss

- [{{< icon "reddit" >}}
  r/rust](https://www.reddit.com/r/rust/comments/1ukxbe3/a_big_standard_library_is_overkill/?)
- [{{< icon "hackernews" >}} Hacker
  News](https://news.ycombinator.com/item?id=48752799)
