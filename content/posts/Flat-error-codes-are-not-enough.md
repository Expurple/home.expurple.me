+++
title = 'Flat Error Codes Are Not Enough'
tags = ['error handling', 'rust', 'tech']
date = 2026-04-12
lastmod = 2026-04-12
summary = "Why you need nested, structured error data."
+++

## The case for flat error codes

I'm writing this in pushback against ["Stop Forwarding Errors, Start Designing
Them"](https://fast.github.io/blog/stop-forwarding-errors-start-designing-them/)
and [other similar
ideas](https://www.reddit.com/r/programming/comments/1qodfji/designing_error_types_in_rust_applications/o2tvjpi/).
Those suggest that you only need one concrete `Error` type per library, with two
fields:

1. An error message, meant for the user.

    Along the call graph, this string should accumulate high-level business
    context to avoid reporting a cryptic low-level error like `"No such file or
    directory"`. This is already a common practice in Go and Rust.

2. A flat `ErrorCode`/`ErrorKind` enum, meant for robust programmatic error
   handling and recovery.

    There should be just one such enum per library. It should be mininal. It
    shouldn't expose every specific low-level error that your library might
    encounter. Instead, only expose the level of detail that's relevant to the
    calling libraries' error-handling logic. The detailed reporting for the user
    is already covered by the error message.

The main benefit is that you satisfy both the human and the machine, while
keeping your codebase clean and minimal.

## The case for nested error data

Flat error codes might work in your own application code, where you rarely need
complex error recovery. In the Rust community, many application devs already
[return a string with no specific "error code" at
all](https://docs.rs/anyhow/latest/anyhow/). (Although, personally, [I'm against
that]({{< ref "/posts/why-use-structured-errors-in-rust-applications/"
>}})).

But I don't see how flat error codes can work in high-level, IO-heavy libraries
that *do* need to provide enough detail for recovery.

Consider the following example from my work codebase:

```rust
use sea_orm::*;
use sea_orm::sqlx::*;

fn human_message(db_err: &DbErr) -> Option<&'static str> {
    match db_err {
        DbErr::Query(RuntimeErr::SqlxError(Error::Database(database_error))) => {
            let constraint_name = database_error.constraint()?;
            match database_error.kind() {
                ErrorKind::UniqueViolation => humanize_unique_violation(constraint_name),
                ErrorKind::ForeignKeyViolation => humanize_fk_violation(database_error.message()),
                ErrorKind::CheckViolation => humanize_check_constraint_violation(constraint_name),
                _ => None,
            }
        }
        // More match arms here...
    }
}
```

Basically, there's a database driver library
[`sqlx`](https://github.com/launchbadge/sqlx). Then, there's
[`sea_orm`](https://github.com/SeaQL/sea-orm/), built on top of it. It exposes a
deep hierarchy of error types:

1. High-level ORM methods return `sea_orm::DbErr`.
2. When caused by a database interaction (IO), it provides an `sqlx::Error` with
   all the details.
3. When caused by an error returned from the DBMS itself, it provides an
   `sqlx::DatabaseError`.
4. Finally, `sqlx::DatabaseError` stores the raw DBMS error privately. It knows
   how to parse and categorize it. I use that in my application to provide
   human-readable error messages wherever I rely on database constraints for
   validation.

If `sea_orm` didn't nest and expose anything from `sqlx`, it would have to
duplicate all of that functionality in its own error types, or drop it. Either
outcome would be very unfortunate.

And even if `sea_orm` exposed or copy-pasted all "error codes" from `sqlx`, that
still wouldn't be enough for my use case. It's not enough to know that I
violated a CHECK constraint. I need other structured data, like the name of the
constraint. Otherwise, I would have to parse that back from the error message.
Which is obviously inferior.

## Related reading

I tackle a very similar "flat vs nested enums" tradeoff in ["Designing Error
Types in Rust Applications"]({{< ref
"/posts/designing-error-types-in-rust-applications/" >}}).

See also my other posts about [error handling]({{< ref "/tags/error-handling/"
>}}).

## Discuss

- [{{< icon "reddit" >}} The Reddit comment thread that prompted this
  post](https://www.reddit.com/r/programming/comments/1qodfji/designing_error_types_in_rust_applications/o2tvjpi/)
- [{{< icon "reddit" >}}
  r/rust](https://www.reddit.com/r/rust/comments/1sjg9h2/flat_error_codes_are_not_enough/?)
- [{{< icon "reddit" >}}
  r/programming](https://www.reddit.com/r/programming/comments/1sjg9v6/flat_error_codes_are_not_enough/?)
- [{{< icon "hackernews" >}} Hacker
  News](https://news.ycombinator.com/item?id=47740223)
