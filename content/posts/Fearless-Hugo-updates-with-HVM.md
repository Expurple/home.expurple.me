+++
title = 'Fearless Hugo Updates With HVM'
tags = ["tech"]
date = 2025-12-15
summary = "Safe, automated, code-reviewed Hugo updates for your website."
+++

Two things happened on the same day that I posted ["Fearless Website Updates
With Hugo"]({{< ref "/posts/fearless-website-updates-with-hugo/" >}}):

- I discovered [`grouse`](https://github.com/capnfabs/grouse) - a tool for
  diffing the generated Hugo sites, very similar to my script from the previous
  post. You may prefer to adopt `grouse` instead.
- In the comments, [`u/McShelby`
  recommended](https://discourse.gohugo.io/t/fearless-website-updates-with-hugo/56371/2?u=expurple)
  me [`hvm`](https://github.com/jmooring/hvm) as a way to automate Hugo upgrades
  in my script.

`grouse` [doesn't support diffing staged
changes](https://github.com/capnfabs/grouse/issues/20) and doesn't offer me any
obvious benefits over a shell script. But `hvm` sparked my interest.

I tried it, and indeed, it works like a charm. After installing and configuring
`hvm`, now updating Hugo and reviewing the impact is as simple as `hvm use
latest && git add .hvm && ./review_staged_changes.sh`. This works with no
changes to my script[^no-changes] because `.hvm` is just a regular file in the
repo, tracked by Git. So, the selected Hugo version can be rolled back with `git
stash` just like any other change. Cool! Another problem solved.

[^no-changes]: Ok, I lied a little. Because of the way `hvm` works (shadowing
the `hugo` binary with a Bash function), I had to `source ~/.bash_aliases` in
the script. If `hvm` used something like a symlink in `PATH` instead, I wouldn't
have to do anything.
