+++
title = 'Rust Solves The Issues With Exceptions'
tags = ['error handling', 'tech']
date = 2024-11-30
lastmod = 2025-06-08
draft = false
+++

A small topic that's too big to fit in a larger Rust post.

## Disclaimers

- Rust isn't the only language that doesn't have exceptions and handles errors
  by value. But error handling in languages like Go is flawed in its own way.
  Here, I don't discuss these other implementations and use Rust as a specific
  *successful* example of exception-free error handling.
- I use Java for most examples of exceptions because it lets me discuss checked
  exceptions as well. For unchecked exceptions, this shouldn't matter because
  the implementation is very similar in most popular languages.
- I ignore third-party libraries and discuss common, "idiomatic" mechanisms
  provided by the language.

## Issues with exceptions

### Exceptional flow

Just like a return value, an exception is a value.

Just like a return value, an exception is "a result of calling the function".

Despite this, exceptions introduce a special `try-catch` flow which is separate
from normal `return`s and assignments. It prevents ergonomic [function
composition](https://en.wikipedia.org/wiki/Function_composition_(computer_science)).
You can't pass the "result" of a throwing function *directly* into another
function, because the return value is passed only when the first function
completes successfully. Thrown exceptions aren't passed *in* and propagate *out*
instead. This is a very common error-handling pattern, and I get why people want
to automate it.
But when you need to pass the error data into the second function, Java makes
you write a verbose `try-catch` block and cook a [home-made
`Result`](https://www.reddit.com/r/java/comments/1935m0r/is_there_a_result_type_in_java/)
type:

```java
// We're given `GReturned g(X x) throws GException` and `f(/* result of g??? */)` which we control.
// Let's generously assume that we also control the definitions of `GReturned` and `GException`.
// This allows us to avoid extra wrapper objects and implement a sealed interface directly.
// As far as I know, this is the most simple and performant implementation of sum types in Java.
sealed interface GResult permits GReturned, GException {}
class GReturned implements GResult { /* ... */ }
class GException extends Exception implements GResult { /* ... */ }

GResult gResult;
try {
    gResult = g(x);
} catch (GException gException) {
    gResult = gException;
}
f(gResult);
```

Compare the snippet above to our original idea, which works as intended if `g`
can't throw:

```java
f(g(x));
```

Exceptions hurt most error-handling patterns. Even very common ones, like
rethrowing a wrapper exception. As you'll see in the next section, this pain
isn't even necessary to have convenient propagation. Exceptions aren't worth the
cost.

{{< collapse
summary="Can you guess why I used an intermediate variable instead of calling `f(g(x))` and `f(gException)` in `try-catch`?"
open=false
>}}

```java
try {
    f(g(x));                       // <- If `f` also happens to throw `GException` and does this when `g` didn't...
} catch (GException gException) {  // <- then this will catch `GException` from `f`...
    f(gException);                 // <- and then call `f` the second time! 💣
}
```

This is a great example of why automatic error propagation is tricky and may
lead to bugs. In Rust, the equivalent of that buggy `f(g(x))` expression would
look like `f(g(x)?)?`, clearly marking both points where a jump / early return
happens and making the bug easier to notice.

And this buggy expression wouldn't even compile! `f` accepts a `Result`, but in
Rust, the "successful" value doesn't implicitly convert into a `Result`. It
needs to be explicitly wrapped: `f(Ok(g(x)?))?`. This is the real, working
equivalent of that Java's `f(g(x))`. It looks ridiculous! It immediately
indicates a fishy situation, and eventually leads us to the right solution:
`f(g(x))?`. Thanks to [u/sasik520](https://www.reddit.com/user/sasik520) for
[pointing this
out](https://www.reddit.com/r/rust/comments/1kx0ak8/why_use_structured_errors_in_rust_applications/munxqay/).

{{< /collapse >}}

### Even "typical" error wrapping is unergonomic

Exceptions always force you to write a whole special `try-catch` block that
can't be abstracted away:

```java
try {
    h();
} catch (InnerException e) {
    throw new WrapperException(e);
}
```

Meanwhile, Rust's error propagation is abstracted into a [`?`
operator](https://doc.rust-lang.org/book/ch09-02-recoverable-errors-with-result.html#a-shortcut-for-propagating-errors-the--operator)
that can perform the wrapping for you:

```rust
h()?;
```

This automatic conversion only works when `WrapperException` implements
`From<InnerException>`. But this is the most common case. And even in other
cases, this is still just a regular data transformation that can be expressed
concisely using regular functions:

```rust
h().map_err(WrapperException)?;
```

That's all it is. Error wrapping doesn't have to be more complicated than that.

### Unchecked exceptions

Traditional unchecked exceptions are dynamically-typed "result" values. Any
function can throw (or not throw) any exception. This makes programs
unpredictable.

Not only the "returned" error values are unpredictable, but especially the
control flow. Remember that exceptions aren't returned and assigned as "normal"
values. Almost any line of code can throw an exception, interrupt the current
function, and start unwinding the stack. Potentially leaving your data in an
inconsistent, half-way modified state. But programmers can't always keep
[exception safety](https://en.wikipedia.org/wiki/Exception_safety) in mind and
get it right on their first try. No one wraps every line in a `try-catch`. The
result is unpredictable, unreliable programs with poor error handling. ["Unhappy
paths"](https://en.wikipedia.org/wiki/Happy_path#Unhappy_path) are more
important than they seem:

> Almost all (92%) of the catastrophic system failures are the result of
incorrect handling of non-fatal errors explicitly signaled in
software. [^failures-paper]

Unchecked exceptions aren't reflected in the type system, but they are still
part of a function's contract. Many style guides recommend manually [documenting
the
exceptions](https://www.analyticsvidhya.com/blog/2024/01/python-docstrings/#h-sections-in-docstrings)
that each public function throws. But soon these docs will get out-of-date
because the compiler doesn't check [^unchecked-pun] the docs for you. Callers
can't rely on these docs' accuracy. If callers want to avoid surprise crashes,
they always have to remember to manually `catch Exception`. And you know [how
that
goes](https://squareallworthy.tumblr.com/post/163790039847/everyone-will-not-just)...

### Checked exceptions in Java

[Checked
exceptions](https://en.wikipedia.org/wiki/Exception_handling_(programming)#Checked_exceptions)
seem like a reasonable reaction to these issues with unchecked exceptions.
Potential errors are included in the method's signature (as they should) and
force the caller to acknowledge the possibility of an error (as they should).

But the actual implementation in Java is very flawed. There are entire
discussions on using only unchecked exceptions, as does every other language
with exceptions. I found the following root causes:

- Java's type system can't represent checked exceptions generically
  [^worm-rabbit]. You can't have an interface that throws an unknown, generic
  set of checked exceptions. An interface has to either:
    1. Throw no checked exceptions. This forces the implementors to wrap and
      rethrow these as an unchecked `RuntimeException`, losing type information.
      [`Runnable.run`](https://docs.oracle.com/javase/8/docs/api/java/lang/Runnable.html#run--)
      is an example of this.
    2. Throw a specific, made-up list of checked exceptions that may not make
      sense for all implementations. [`Appendable.append throws
      IOException`](https://docs.oracle.com/javase/8/docs/api/java/lang/Appendable.html#append-char-)
      is an example of this.
- Throwing a new checked exception from a method is always a breaking change.
  Because of this, libraries with a stable API might decide to throw an
  unchecked wrapper instead. Callers can still catch and handle it, because...
- Unchecked exceptions are recoverable. No wonder people go against the
  ["official"
  recommendations](https://docs.oracle.com/javase/tutorial/essential/exceptions/runtime.html)
  and use them for recoverable errors! The `try-catch` mechanism is the same for
  all exceptions. You're always just one `extends RuntimeException` away from
  pleasing the compiler without a big refactoring. Which is needed, because...
- [The lack of union types and type
  aliases](https://langdev.stackexchange.com/a/485/6542) infamously forces the
  programmer to update the `throws` clause in *every* method all the way up the
  stack (until that exception is covered by a `catch` that swallows or wraps
  it).

If we had a type system that solves these issues, checked exceptions would be a
pretty good deal! Definitely better than unchecked exceptions that we see today
in most popular languages.

But even improved checked exceptions would still suffer from the general issues
with exceptions (described in the [beginning](#exceptional-flow) of the post).
Now, let's see how Rust solves all these issues for good.

## Solutions in Rust

Rust gracefully solves these issues by having:

- Errors as "normal" return values that work with "normal" assignments and
  function calls.
- ["Sum types"](https://en.wikipedia.org/wiki/Tagged_union) that allow
  expressing things like "this is **either** a value **or** an error" or "this
  is **one of** these possible errors". Rust
  [`enum`](https://doc.rust-lang.org/rust-by-example/custom_types/enum.html)s
  are like sealed interfaces, but much more ergonomic, efficient (no
  indirection), and flexible (you can't implement interfaces for types that you
  don't control).
- Exhaustive [pattern
  matching](https://doc.rust-lang.org/rust-by-example/flow_control/match.html)
  that forces the programmer to handle every possible case (including errors, if
  the possibility of an error is indicated in the type).
- A standard generic
  [`Result`](https://doc.rust-lang.org/std/result/enum.Result.htmlt) type with
  methods like
  [`map_err`](https://doc.rust-lang.org/std/result/enum.Result.html#method.map_err)
  to help in typical scenarios like adding context to errors.
- A rich type system that allows handling errors generically without losing type
  information. The `E` in `Result<T, E>` is the prime example of this.
- A compact [`?`
  operator](https://doc.rust-lang.org/book/ch09-02-recoverable-errors-with-result.html#a-shortcut-for-propagating-errors-the--operator)
  to convert and propagate errors. It makes error propagation as ergonomic as
  when using exceptions (and more ergonomic when you need to wrap the error).
  But it's also explicit and visible in a code review, as we've discussed in the
  section about a tricky `f(g(x))`.
- More syntax sugar like [`if
  let`](https://doc.rust-lang.org/rust-by-example/flow_control/if_let.html),
  [`while
  let`](https://doc.rust-lang.org/rust-by-example/flow_control/while_let.html),
  [`let-else`](https://doc.rust-lang.org/rust-by-example/flow_control/let_else.html).
- The
  [`#[non_exhaustive]`](https://doc.rust-lang.org/reference/attributes/type_system.html)
  attribute to solve the API stability problem where necessary. It's not
  unchecked, it still forces callers to handle unknown error variants from the
  future! [^base-exception]
- Unrecoverable [^recover-panic]
  ["panics"](https://doc.rust-lang.org/book/ch09-01-unrecoverable-errors-with-panic.html)
  that are [clearly
  separated](https://doc.rust-lang.org/book/ch09-03-to-panic-or-not-to-panic.html#to-panic-or-not-to-panic)
  from the "normal" value-based error handing (everything described above).
  Panics are used as:
    1. Assertions that indicate a bug in the program when hit.
    2. Intentional
       "[`eprintln`](https://doc.rust-lang.org/std/macro.eprintln.html) +
       cleanup + [`exit`](https://doc.rust-lang.org/std/process/fn.exit.html)"
       for cases where the author of the code made a judgement call that the
       application (the caller) is unable (or wouldn't want to) recover from the
       current situation. [^oom-panic]

## Rust's own issues

It would be unfair to end the post here and declare that Rust has the best error
handling because it solves all issues found in another language. Rust's approach
inevitably brings in some new, different issues:

- When your function can encounter multiple different errors *and* you want to
  preserve concrete type information [^dyn-err], Rust makes you manually define
  a wrapper enum and implement the conversions. This is necessary because Rust
  doesn't have [anonymous unions](https://github.com/rust-lang/rfcs/issues/294).
  But the boilerplate isn't too bad and even built-in solutions like `?`
  eliminate some of it [^thiserror].
- There's also a more specific issue with those wrapper enums. Sometimes, they
  tend to grow and be shared across multiple functions, where not every function
  actually returns every error variant. This undermines the benefits of
  exhaustive pattern matching and types-as-documentation, leading to...
  [hand-written docs that list the errors that the function can
  return](https://docs.rs/rust_xlsxwriter/0.79.4/rust_xlsxwriter/worksheet/struct.Worksheet.html#errors-1)!
  Sounds familiar, huh? The experimental `terrors` library does a great job of
  [describing this
  issue](https://github.com/komora-io/terrors?tab=readme-ov-file#motivation).
- Moving around bloated return values and explicitly checking those [can
  sometimes hurt
  performance](https://www.reddit.com/r/rust/comments/k5wk7r/is_rust_leaving_performance_on_the_table_by/gehe5b2/).
  But this can be solved by boxing the error, using output parameters or
  callbacks, or using global variables. Besides, `Result` and other enums are
  often "free" in terms of memory, due to [niche
  optimizations](https://www.0xatticus.com/posts/understanding_rust_niche/).
  Some errors may even be represented as [zero-sized
  types](https://dev.to/hoonweedev/whats-the-use-of-zero-sized-types-in-rust-4e83).
- Even though Rust supports local (non-propagating) error handling much better
  than languages with exceptions, it's still not perfect and can over-emphasize
  the "stop on the first error" pattern. Reporting multiple errors at once isn't
  supported just as well and may require third-party libraries or verbose
  in-house solutions. I discuss this issue in more detail in [my in-house
  solution](https://github.com/expurple/multiple_errors) which you can use as a
  third-party library 😁
- As mentioned in [this post about
  .NET](https://eiriktsarpalis.wordpress.com/2017/02/19/youre-better-off-using-exceptions/),
  exceptions usually provide good insight into the origin of an error, with
  tools like stack traces and debugger breakpoints. Tracing the origin of an
  error *value* in Rust is a more demanding process that may require: manually
  enforcing best practices around logging and adding context to errors; manually
  [capturing](https://doc.rust-lang.org/std/backtrace/struct.Backtrace.html#method.capture)
  backtraces where necessary; longer debugging sessions. On the other hand,
  debugging runtime issues comes up way less often in Rust 🙃

In my opinion, these issues aren't nearly as fundamental and annoying as the
issues with exceptions. Now I *can* conclude that Rust has the best error
handling! 💥

---

## Related reading

Good articles that I haven't hyperlinked anywhere else in the post:

- [Checked exceptions: Java’s biggest
  mistake](https://literatejava.com/exceptions/checked-exceptions-javas-biggest-mistake/)
- [The Trouble with Checked Exceptions. A Conversation with Anders Hejlsberg,
  Part II](https://www.artima.com/articles/the-trouble-with-checked-exceptions)
- [Either vs Exception Handling](https://dev.to/anthonyjoeseph/either-vs-exception-handling-3jmg)
- [The Error Model](https://joeduffyblog.com/2016/02/07/the-error-model/)

My later post, diving deeper into the topic of error handling in Rust:

- [Why Use Structured Errors in Rust Applications?]({{< ref
  "/posts/why-use-structured-errors-in-rust-applications/" >}})

## Discuss

- [{{< icon "reddit" >}}
  r/rust](https://www.reddit.com/r/rust/comments/1h3kdye/rust_solves_the_issues_with_exceptions/?)
- [{{< icon "reddit" >}}
  r/ProgrammingLanguages](https://www.reddit.com/r/ProgrammingLanguages/comments/1h3khye/rust_solves_the_issues_with_exceptions/?)
- [{{< icon "hackernews" >}} Hacker
  News](https://news.ycombinator.com/item?id=42283549)

[^failures-paper]: [Simple Testing Can Prevent Most Critical Failures: An
Analysis of Production Failures in Distributed Data-intensive
Systems](https://www.eecg.toronto.edu/~yuan/papers/failure_analysis_osdi14.pdf)

[^unchecked-pun]: Get it? Exceptions stay *unchecked*! 🥁

[^worm-rabbit]: Shout-out to
[u/WormRabbit](https://www.reddit.com/user/WormRabbit) who has [pointed this
out](https://www.reddit.com/r/rust/comments/1h3kdye/rust_solves_the_issues_with_exceptions/lzsnn7g/)!
Originally, I missed this point and it wasn't in the post.

[^recover-panic]: Actually, there are some workarounds, like using
[std::panic::catch_unwind](https://doc.rust-lang.org/std/panic/fn.catch_unwind.html)
or doing the work on a [separate
thread](https://doc.rust-lang.org/std/thread/fn.spawn.html). That's what all
popular web frameworks do to avoid crashing the entire process when one of the
requests panics. But the process still crashes if the target doesn't support
unwinding or the project is built with [`panic =
"abort"`](https://doc.rust-lang.org/cargo/reference/profiles.html#panic)
setting. It also crashes when [a destructor panics in an already-panicking
thread](https://nrc.github.io/error-docs/rust-errors/panic.html#panic).

[^oom-panic]: E.g., most of the [Rust Standard
    Library](https://doc.rust-lang.org/std/index.html) APIs panic on
    [OOM](https://en.wikipedia.org/wiki/Out_of_memory) conditions because it's
    geared towards application programming and treats OOM as a situation that
    the application won't attempt to handle anyway.

    This is controversial because it doesn't always provide equivalent
    non-panicking APIs for other use cases. It should accommodate low-level use
    cases better. But the existence of a convenient panicking API is OK. It's
    more appropriate for most applications. A typical modern system with [memory
    overcommitment](https://en.wikipedia.org/wiki/Memory_overcommitment) will
    never report OOM on allocation anyway.

[^base-exception]: To be fair, the same result can be achieved in Java if you
    plan in advance and wrap all exceptions. You can throw exactly one checked
    exception, some base class. When you need to throw a new exception, you
    inherit a new child from that base class. This won't break the callers,
    because they are already forced to handle the parent. And the callers also
    have type information and nice autogenerated docs about the possible
    children. Thanks to [brabel](https://news.ycombinator.com/user?id=brabel)
    for [pointing this out](https://news.ycombinator.com/item?id=42288353).

    Although, the Rust solution still seems cleaner and produces fewer
    types/objects/boilerplate, considering that defining and rethrowing wrapper
    exceptions is pretty verbose in Java. Also, when you decide to make a
    breaking change and mark an enum as `#[non_exhaustive]`, it doesn't cause as
    much refactoring, compared to changing anything in the `throws` clause.

[^dyn-err]: There are "easier" [alternative
approaches](https://doc.rust-lang.org/rust-by-example/error/multiple_error_types/boxing_errors.html)
that erase the type, like `Box<dyn Error>`.

[^thiserror]: *Man*, and third-party libraries are *so good*. But I promised not
to get into detail with those...
