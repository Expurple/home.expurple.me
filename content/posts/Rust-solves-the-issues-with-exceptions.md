+++
title = 'Rust Solves The Issues With Exceptions'
date = 2024-11-30
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

Exceptions make this (and similar) patterns suffer so badly. They're not
"uncommon" enough to justify the pain. And, as we'll see later, "common" error
propagation can still be ergonomic without exceptions! They're not worth the
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
{{< /collapse >}}

### Unchecked exceptions

Traditional unchecked exceptions are dynamically typed "result" values. Any
function can throw (or not throw) any exception. This makes programs
unpredictable. Especially, the control flow. Almost any line of code can throw
an exception, interrupt the current function, and start unwinding the stack.
Potentially leaving your data in an inconsistent, half-way modified state. But
programmers can't always keep [exception
safety](https://en.wikipedia.org/wiki/Exception_safety) in mind and get it right
on their first try. No one wraps every line in a `try-catch`. The result is
unpredictable, unreliable programs with poor error handling. ["Unhappy
paths"](https://en.wikipedia.org/wiki/Happy_path#Unhappy_path) are more
important than they seem:

> Almost all (92%) of the catastrophic system failures are the result of
incorrect handling of non-fatal errors explicitly signaled in
software.[^failures-paper]

Unchecked exceptions aren't reflected in the type system, but they are still
part of a function's contract. Many style guides recommend manually [documenting
the
exceptions](https://www.analyticsvidhya.com/blog/2024/01/python-docstrings/#h-sections-in-docstrings)
that each public function throws. But soon these docs will get out-of-date
because the compiler doesn't check[^unchecked-pun] the docs for you. Callers
can't rely on these docs' accuracy. If callers want to avoid surprise crashes,
they always have to remember to manually `catch Exception`. And you know [how
that
goes](https://squareallworthy.tumblr.com/post/163790039847/everyone-will-not-just)...

### Checked exceptions in Java

[Checked
exceptions](https://en.wikipedia.org/wiki/Exception_handling_(programming)#Checked_exceptions)
seem like a reasonable reaction to the issues with unchecked exceptions. But the
implementation in Java is very flawed. It makes people (ab)use unchecked
exceptions so much that there are entire discussions on using only unchecked
exceptions, as does every other language with exceptions. I found the following
root causes:

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

## Solutions in Rust

Rust gracefully solves these issues by having:

- A [clear
  separation](https://doc.rust-lang.org/book/ch09-03-to-panic-or-not-to-panic.html#to-panic-or-not-to-panic)
  between:
    - "Expected" return values that must be handled explicitly.
    - Unrecoverable[^recover-panic] panics that act as assertions and indicate a
      bug in the program.
- Ergonomic sum types that are used consistently in the standard library.
- A standard generic
  [`Result`](https://doc.rust-lang.org/std/result/enum.Result.htmlt) type with
  methods like
  [`map_err`](https://doc.rust-lang.org/std/result/enum.Result.html#method.map_err)
  to help in typical scenarios like adding context to errors.
- A compact [`?`
  operator](https://doc.rust-lang.org/book/ch09-02-recoverable-errors-with-result.html#a-shortcut-for-propagating-errors-the--operator)
  to convert and propagate errors. It makes "dumb" error propagation as
  ergonomic as when using exceptions.
- Ergonomic, exhaustive pattern matching, complemented by:
    - More syntax sugar like [`if
      let`](https://doc.rust-lang.org/rust-by-example/flow_control/if_let.html),
      [`while
      let`](https://doc.rust-lang.org/rust-by-example/flow_control/while_let.html),
      [`let-else`](https://doc.rust-lang.org/rust-by-example/flow_control/let_else.html).
    - The
      [`#[non_exhaustive]`](https://doc.rust-lang.org/reference/attributes/type_system.html)
      attribute to solve the API stability problem where necessary. It's not
      unchecked, it still forces callers to handle unknown error variants from
      the future!

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
- [Error Handling in Rust](https://nrc.github.io/error-docs/intro.html)

## Discuss

- [r/rust](https://www.reddit.com/r/rust/comments/1h3kdye/rust_solves_the_issues_with_exceptions/?)
- [r/ProgrammingLanguages](https://www.reddit.com/r/ProgrammingLanguages/comments/1h3khye/rust_solves_the_issues_with_exceptions/?)
- [Hacker News](https://news.ycombinator.com/item?id=42283549)

[^failures-paper]: [Simple Testing Can Prevent Most Critical Failures: An
Analysis of Production Failures in Distributed Data-intensive
Systems](https://www.eecg.toronto.edu/~yuan/papers/failure_analysis_osdi14.pdf)

[^unchecked-pun]: Get it? Exceptions stay *unchecked*! 🥁

[^recover-panic]: Actually, there are some workarounds, like using
[std::panic::catch_unwind](https://doc.rust-lang.org/std/panic/fn.catch_unwind.html)
or doing the work on a [separate
thread](https://doc.rust-lang.org/std/thread/fn.spawn.html). That's what all
popular web frameworks do to avoid crashing the entire process when one of the
requests panics. But the process still crashes if the target doesn't support
unwinding or the project is built with [`panic =
"abort"`](https://doc.rust-lang.org/cargo/reference/profiles.html#panic)
setting.

[^dyn-err]: There are "easier" [alternative
approaches](https://doc.rust-lang.org/rust-by-example/error/multiple_error_types/boxing_errors.html)
that erase the type, like `Box<dyn Error>`.

[^thiserror]: *Man*, and third-party libraries are *so good*. But I promised not
to get into detail with those...
