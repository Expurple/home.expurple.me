+++
title = 'Designing Error Types in Rust Applications'
tags = ['error handling', 'rust', 'tech']
date = 2026-01-27
lastmod = 2026-04-12
summary = 'How to manage your custom errors and minimize pain.'
+++

TL;DR: use an enum per function, instead of a global `Error` enum.

## The "Error Handling" series

This is the fourth post in my ["Error Handling"]({{< ref "/tags/error-handling/"
>}}) series.

I suggest reading ["Why Use Structured Errors in Rust Applications?"]({{< ref
"/posts/why-use-structured-errors-in-rust-applications/" >}}) before this one.
There, I

- define "structured errors";
- describe why error handling is different in libraries vs applications;
- discuss the tradeoffs of dynamic vs structured errors in applications; and
- make the case for structured errors.

## Library vs application needs

Now, as we've narrowed our focus down to structured errors, let's discuss why
application error types should be very different from library errors that you
commonly see:

- Libraries don't know all their callers and have to anticipate a wide range of
  use cases.
- This usually implies that libraries allow their callers to pattern-match
  specific error cases and programmatically extract the error details.
- Libraries care about backward compatibility of their public interface, which
  includes the error types.
- This implies that they should be
  [careful](https://www.reddit.com/r/rust/comments/1kx0ak8/why_use_structured_errors_in_rust_applications/muvblzn/)
  with exposing new error variants and details.
- But intentionally adding new variants and details shouldn't be a breaking
  change. Most library errors should be
  [`#[non_exhaustive]`](https://doc.rust-lang.org/reference/attributes/type_system.html#the-non_exhaustive-attribute).

{{< callout circle-info >}}
In this post, by "libraries" I mean "public, reusable libraries". For my
purposes, private libraries in a workspace still count as "application code".
{{< /callout >}}

Unless you expose structured error data to the outside world [^huge-codebase],
the situation in your app is exactly the opposite:

- You know every place where every function is called, and your needs at every
  call site.
- In most cases, you don't pattern-match specific errors and instead just
  propagate the error, perhaps with some additional context.
- You don't need to care about the stability and backward compatibility of your
  error types. You can freely refactor your entire codebase as necessary. Unless
  you have a huge codebase, it's easy to do.

Understanding this, let's finally discuss how you should define your error
types.

## Don't use one big enum for everything

In the Rust library ecosystem, it's common to see one big crate-level `Error`
enum that's returned from every function. There are fair reasons for this:

- It's the easiest option for the author. It keeps the code DRY, concise, and
  free from type conversions.
- It's easier to propagate. When you call multiple functions from a library, and
  they all return the same error type, you can just propagate it without
  creating your own wrapper enum.
- A single error type is easy to find.
- It doesn't "pollute" the docs and autocomplete suggestions with a long list of
  separate `*Error` types.
- It's easier to pattern match, because such enums are usually "flat". We'll
  discuss this in the next section.

See also how `BurntSushi` explains [choosing this approach for his `jiff`
library](https://github.com/BurntSushi/jiff/issues/8).

But you shouldn't blindly copy it in your application!

### Modularity

It's easy to see that lumping every possible error into one global enum is
anti-modular.

This works for smaller, "pure" libraries. They have a narrow and well-defined
scope.
[`rust_xlsxwriter::XlsxError`](https://docs.rs/rust_xlsxwriter/0.87.0/rust_xlsxwriter/enum.XlsxError.html)
is a "global" error enum with 33 variants, but it's still a cohesive description
of what can go wrong when writing an Excel file. [^split-xlsx]

Your application probably does more things (especially, IO), has much more
diverse error cases, and a greater number of cases overall. These cases don't
always overlap between multiple application features. Some cases are actually
handled locally inside some feature's module and shouldn't be public outside of
that.

When you ignore this, you get horror stories like a [single `match` statement
with 54 arms for every possible error in the
app](https://www.reddit.com/r/rust/comments/fdyfd6/is_pattern_matching_an_antipattern/fjytrq5/)
or a [1000-line error
enum](https://www.reddit.com/r/rust/comments/1kx0ak8/why_use_structured_errors_in_rust_applications/muxmimb/)
where lost people [accidentally add duplicate
variants](https://www.reddit.com/r/rust/comments/1kx0ak8/why_use_structured_errors_in_rust_applications/muymda3/).
In cases like that, one big enum actively hurts code quality.

["Modular Errors in Rust"](https://sabrinajewson.org/blog/errors) gives some
arguments for splitting library errors, too.

### Precise signatures

With a "catch-all" enum, the signature no longer accurately reflects the errors
that a function can return. It contains many irrelevant error variants that are
never returned in practice. To get a clear understanding of the function's
behavior, you have to either rely on fragile [hand-written
docs](https://docs.rs/rust_xlsxwriter/0.79.4/rust_xlsxwriter/worksheet/struct.Worksheet.html#errors-1)
or inspect the implementation. In that sense, a large enough "catch-all" enum
becomes weirdly similar to an opaque type like `anyhow::Error`.
[^big-enum-over-anyhow]

It's possible to be precise and exhaustive while also staying DRY, if you
extract common variants into separate types:

{{< collapse summary="Before" open=false >}}

```rust
#[derive(Debug, thiserror::Error)]
enum Error {
    #[error("a")]
    A,
    #[error("b")]
    B,
    #[error("c")]
    C,
}

/// ## Errors
///
/// - [Error::A] if ...
/// - [Error::B] if ...
fn foo() -> Result<(), Error> {
    // ..
}

/// ## Errors
///
/// - [Error::B] if ...
/// - [Error::C] if ...
fn bar() -> Result<(), Error> {
    // ..
}
```

{{< /collapse >}}

{{< collapse summary="After" open=false >}}

```rust
#[derive(Debug, thiserror::Error)]
#[error("b")]
struct BError;

#[derive(Debug, thiserror::Error)]
enum FooError {
    #[error("a")]
    A,
    #[error(transparent)]
    B(#[from] BError),
}

#[derive(Debug, thiserror::Error)]
enum BarError {
    #[error(transparent)]
    B(#[from] BError),
    #[error("c")]
    C,
}

fn foo() -> Result<(), FooError> {
    // ..
}

fn bar() -> Result<(), BarError> {
    // ..
}
```

{{< /collapse >}}

This makes the author maintain a bit more code, but liberates him from
maintaining hand-written docs without compiler assistance. The types give
callers more confidence than those docs, and allow to pattern match
exhaustively when needed. [^non-exhaustive]

## Flat vs nested enums

Let's evolve the last code example. There's now a higher-level function `foobar`
that calls `foo` and `bar` and propagates all their errors:

```rust
fn foobar() -> Result<(), FoobarError> {
    foo()?;
    bar()?;
    // ..
}
```

There are two different ways we could express `FoobarError`.

### Flat enums

{{< collapse summary="The \"flat\" implementation" open=false >}}

```rust
#[derive(Debug, thiserror::Error)]
enum FoobarError {
    #[error(transparent)]
    A(AError),
    #[error(transparent)]
    B(BError),
    #[error(transparent)]
    C(CError),
}

impl From<FooError> for FoobarError {
    fn from(foo_error: FooError) -> Self {
        match foo_error {
            FooError::A(a) => Self::A(a),
            FooError::B(b) => Self::B(b),
        }
    }
}

impl From<BarError> for FoobarError {
    fn from(bar_error: BarError) -> Self {
        match bar_error {
            BarError::B(b) => Self::B(b),
            BarError::C(c) => Self::C(c),
        }
    }
}

// This approach forces us to refactor the existing lower-level code
// and extract all "leaf" errors into separate types:

#[derive(Debug, thiserror::Error)]
#[error("a")]
struct AError;

#[derive(Debug, thiserror::Error)]
#[error("c")]
struct CError;

#[derive(Debug, thiserror::Error)]
enum FooError {
    #[error(transparent)]
    A(#[from] AError),
    #[error(transparent)]
    B(#[from] BError),
}

#[derive(Debug, thiserror::Error)]
enum BarError {
    #[error(transparent)]
    B(#[from] BError),
    #[error(transparent)]
    C(#[from] CError),
}
```

{{< /collapse >}}

In the "flat" style, each variant in the resulting enum corresponds to a "leaf"
error case (A-C). We erase all intermediate knowledge about `boo` and `bar`.
This is very similar to checked exceptions in Java. It's extremely verbose,
unfriendly to refactoring and doesn't preserve any intermediate context.

This approach has an advantage, though. It allows the calling code to easily
pattern match specific "leaf" errors (like `BError`) without knowing and
worrying about all their possible origins (whether it has originated from `foo`
or `bar`):

```rust
if let Err(FoobarError::B(b)) = foobar() {
    // Do something special with `b`...
}
```

This caller-side pattern matching is easy, robust, and future-proof.

But remember what I told you... applications very rarely pattern match specific
errors!

### Nested enums

In the "nested" style, the resulting variants are "higher-level" and directly
correspond to the `foo` and `bar` calls that are happening in the function body:

```rust
#[derive(Debug, thiserror::Error)]
enum FoobarError {
    #[error(transparent)]
    Foo(#[from] FooError),
    #[error(transparent)]
    Bar(#[from] BarError),
}
```

I've always preferred nested enums. Their tradeoffs make more sense in my
application:

- They are much easier to implement. This is self-evident if you compare the
  size of the two code examples.

- The variants correspond to the actual business actions that constitute
  `foobar` (`Foo` and `Bar`), rather than their internal details (like `B`).

- This makes `FoobarError` more compact, meaningful, and suitable for studying.

- This pattern is a lot more friendly towards adding context to errors, at both
  levels. The lower-level context (e.g., on `FooError::A`) is not lost. The
  higher-level context (e.g., on `FoobarError::Foo`) is per-function-call, which
  is very convenient and makes a lot of sense from the business standpoint.

- If you never pattern match errors, nested enums "localize" refactoring.
  Changes don't propagate many layers up. If you add a hypothetical
  `BarError::D`, you don't need to change anything in `FoobarError`. This stands
  in nice contrast to checked exceptions in Java.

You might have experienced a slight cognitive dissonance, as I called
per-function-call variants "high-level" and said that they don't expose
"internal details". After all, isn't your call graph an internal low-level
detail that's prone to change?

If we were talking about a stable public library with pattern-matching callers,
you'd be correct. But remember that we're talking about application error
handling. We don't need to preserve backwards compatibility, and the callers
basically never pattern match. As you refactor your code, you simply refactor
the error variants along with it. That creates a little friction, but also acts
as documentation and forces you to reconsider the context messages, which is
good.

### Workarounds for pattern matching nested enums

So, you optimize for maintainability and use nested enums everywhere. But then,
suddenly, you *do* need to match one specific "leaf" error and cover all of its
origins. What are your options?

1. Simply match nested cases and add unit tests:

   ```rust
   if let Err(FoobarError::Bar(BarError::B(b)) | FoobarError::Foo(FooError::B(b))) = foobar() {
       // Do something special with `b`...
   }
   ```

   Unless you write a huge, "deeply-exhaustive" [^deeply-exhaustive] `match`
   statement, this code won't catch future `BError`s if you add a new origin
   later.

   Nevertheless, I wrote a snippet like this at work, and it serves me fine.

2. Simply match the error message and add unit tests:

   ```rust
   if let Err(e) = foobar()
       && e.to_string().ends_with("b")
   {
       // Do something special with `e`...
   }
   ```

   This is another fragile yet pragmatic solution that I used at work once and
   it serves me fine.

3. If you need a future-proof solution at the cost of verbosity, you can
   implement `TryInto<BError>` for `FoobarError` and all its "inner" errors,
   using exhaustive matching:

   ```rust
   if let Err(Ok(b)) = foobar().map_err(BError::try_from) {
       // Do something special with `b`...
   }
   ```

   {{< collapse summary="Show verbose trait impls" open=false >}}

   ```rust
   impl TryFrom<FoobarError> for BError {
       type Error = FoobarError;

       fn try_from(foobar: FoobarError) -> Result<Self, Self::Error> {
           // Intentionally exhaustive match to make sure that we check every underlying case.
           match foobar {
               FoobarError::Foo(foo) => foo.try_into().map_err(FoobarError::Foo),
               FoobarError::Bar(bar) => bar.try_into().map_err(FoobarError::Bar),
           }
       }
   }

   impl TryFrom<FooError> for BError {
       type Error = FooError;

       fn try_from(foo: FooError) -> Result<Self, Self::Error> {
           // Intentionally exhaustive match to make sure that we check every underlying case.
           match foo {
               FooError::A => Err(FooError::A),
               FooError::B(b) => Ok(b),
           }
       }
   }

   impl TryFrom<BarError> for BError {
       type Error = BarError;

       fn try_from(bar: BarError) -> Result<Self, Self::Error> {
           // Intentionally-exhausive match to make sure that we check every underlying case.
           match bar {
               BarError::B(b) => Ok(b),
               BarError::C => Err(BarError::C),
           }
       }
   }
   ```

   {{< /collapse >}}

   I've never needed this yet.

## Other tips

### When to reuse an error type between multiple functions

The TL;DR of this post is "define an enum per function". However, I don't do
that every single time. Use your best judgement.

Sometimes, for example, I have a module that exports a single function, and that
function is split into several private helpers that return some subset of
errors. In that case, I wouldn't bother and would just return the "full" error
from the private helpers, unless I need a context message around them.

### Where to put error types

Don't define a global `error.rs`. Put an error type right above the function
that returns it. ["Error Handling in
Rust"](https://nrc.github.io/error-docs/error-design/error-type-design.html#naming)
and ["Modular Errors in Rust"](https://sabrinajewson.org/blog/errors) recommend
this too.

Methods are a little annoying, because `impl` blocks can't contain type
definitions. I usually put the errors right below an `impl` block.

### Don't create one-variant enums

You don't need "extensibility". Your app isn't a stable public library! You can
always refactor later.

Keep things simple. Just return the underlying type. Create a struct if you need
to wrap it, or if you construct a "leaf" error and there's nothing to wrap. Only
create an enum when you have two or more variants to propagate.

### `non_exhaustive`

Similarly, you don't need `#[non_exhaustive]` errors in an application. You are
always the caller and you can always refactor the `match` sites if you have any.
Being forced to do that may be a good thing. When it's not, you can add a
wildcard match arm (`_ => ..`) voluntarily.

### Naming error variants

Keep it concise. `FooErr::Bar` over `FooErr::BarErr`. Clippy has a
[lint](https://rust-lang.github.io/rust-clippy/master/index.html#enum_variant_names)
for this. Also recommended in ["Error Handling in
Rust"](https://nrc.github.io/error-docs/error-design/error-type-design.html#naming).

### Privacy of fields

This one's easy. By default, everything's naturally private. That's one of the
Rust's ["pits of
success"](https://blog.codinghorror.com/falling-into-the-pit-of-success/). You
write less code, and the compiler is able to perform better analysis, generate
more dead code warnings, etc. Application code rarely pattern matches errors, so
you rarely need to make the details public. When you do, you can quickly do this
on demand.

### Mixing `anyhow` and structured errors

Sometimes I notice people assuming that `anyhow::Error` is some sort of "dynamic
typing" that has to "infect" the stack all the way up, and there's no way to
make it "typed" again. This isn't true. You can isolate it and return to the
typed land at any level:

```rust
#[derive(Debug, thiserror::Error)]
enum CallerErr {
    // I intentionally omit `#[from]`
    // to avoid auto-capturing `anyhow::Error`s from other function calls.
    //
    // They should probably go to their own error variants
    // with their own context messages.
    #[error("callee failed: {0}")]
    DynamicCallee(anyhow::Error),
    // ..
}

fn typed_caller() -> Result<(), CallerErr> {
    // ..
    dynamic_callee().map_err(CallerErr::DynamicCallee)?;
    // ..
}

fn dynamic_callee() -> anyhow::Result<()> {
    // ..
}
```

Incremental rewrites from `anyhow` are quite easy. This is a common pattern as
applications mature.

## Only siths deal in absolutes

I made a lot of prescriptive statements in this post. This is how I lead my
project at work. But this is a nuanced topic, full of tradeoffs that depend on
your project. You don't have to follow my advice.

---

## Related reading

Good articles that I haven't linked anywhere else in the post:

- ["How to organize errors in large Rust
  projects"](https://kerkour.com/rust-organize-errors-large-projects) - an
  interesting alternative approach for web servers.
- ["Designing error types in
  Rust"](https://mmapped.blog/posts/12-rust-error-handling) - a good "basic"
  guide to designing library errors.

See also my other posts about [error handling]({{< ref "/tags/error-handling/"
>}}).

## Discuss

- [{{< icon "reddit" >}}
  r/rust](https://www.reddit.com/r/rust/comments/1qodf3o/designing_error_types_in_rust_applications/?)
- [{{< icon "reddit" >}}
  r/programming](https://www.reddit.com/r/programming/comments/1qodfji/designing_error_types_in_rust_applications/?)
- [{{< icon "hackernews" >}} Hacker
  News](https://news.ycombinator.com/item?id=46779507)

[^huge-codebase]: Or unless you have a widely used function in a huge codebase
where the callers could be considered an uncontrollable "outside world" from
your module's point of view.

[^split-xlsx]: `XlsxError` doesn't
    [over-expose](https://www.reddit.com/r/rust/comments/1kx0ak8/why_use_structured_errors_in_rust_applications/muxmimb/)
    irrelevant details. And, to quote
    [myself](https://www.reddit.com/r/rust/comments/1kx0ak8/why_use_structured_errors_in_rust_applications/muyfff8/):

    > From periodically skimming the method docs, I know that the returned error
    > subsets unpredictably overlap between the methods. So, it would be hard to
    > extract a meaningful separate subset that doesn't overlap with anything.

[^big-enum-over-anyhow]: To be fair, it still possesses some advantages of
structured errors, like DRY error messages, jump-to-variant-definition, reliable
pattern matching (although no longer exhaustive), autogenerated docs with all
possible variants (although there are extra, unused variants in the list).

[^non-exhaustive]: Keep in mind that we're talking about *application* error
handling. In a public library, you may want to mark these per-function enums as
`#[non_exhaustive]` to prevent breaking changes as the library evolves. In
application code, breaking changes are a smaller problem because the resulting
refactoring is entirely under your control and doesn't cause any downstream
trouble.

[^deeply-exhaustive]: Scanning into every intermediate enum down to every "leaf"
    variant to avoid missing the variants that we're interested in:

    ```rust
    let b: Option<BError> = match foobar() {
        Ok(()) => None,
        Err(foobar) => match foobar {
            FoobarError::Foo(foo) => match foo {
                FooError::A => None,
                FooError::B(b) => Some(b),
            },
            FoobarError::Bar(bar) => match bar {
                BarError::B(b) => Some(b),
                BarError::C => None,
            },
        },
    };
    if let Some(b) = b {
        // Do something special with `b`...
    }
    ```
