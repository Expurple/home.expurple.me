+++
title = 'Fearless Website Updates With Hugo'
tags = ['tech']
date = 2025-12-14
lastmod = 2025-12-14
summary = 'Managing dependencies, reviewing generated HTML, diffing staged changes in 0.3 seconds.'
+++

Managing dependencies, reviewing generated HTML, writing a script for diffing
staged changes. Sounds fun?

## SSGs are complex and fragile

I use [Hugo](https://gohugo.io/) to make this website. Hugo is awesome. It has
allowed me to download a [theme](https://mnjm.github.io/kayal/) and start
writing in Markdown, instead of bothering with templates and styling
[^tweak-later]. It generates RSS feeds and other metadata like `sitemap.xml`,
helps with [content management](https://gohugo.io/content-management/), provides
a development server with hot reloading, and does many other useful things.

But when you use a full-blown [static site
generator](https://en.wikipedia.org/wiki/Static_site_generator) like Hugo (and
especially when you rely on a third-party theme!), you depend on a moving system
that you don't fully understand. Small config changes and routine software
updates can break your website in subtle and unexpected ways.

### Dependency updates are fragile

Apart from potential bugs, new Hugo releases regularly include intentional
breaking changes. For this reason, I always build the website with a specific,
tested version of Hugo. I update Hugo manually when I'm ready to re-test the
website and adapt to the changes. I recommend this to anyone using Hugo. Having
full control over the pace of change is one of the best features of static site
generators. [^statically-linked]

But this only allows you to control *when* the changes happen. Usually, you
still want to upgrade *eventually*. So, you still need a way to test the result.

The most obvious way of doing that is just browsing the updated website locally.
Messing around.

That's what I did when I tried upgrading from Hugo `0.131.0` to Hugo `0.132.0`.
Everything looked good until I clicked on the RSS link. If I hadn't done that, I
wouldn't have noticed that Hugo `0.132.0` breaks my RSS feed! [^theme-bug]

That's not something that you can notice when browsing the website normally. I
just got lucky.

### Any edits are fragile, really

If you just want to blog [^why-an-ssg], you're probably ready to say: "fuck it
then", stop fiddling with styles, and stop updating Hugo. Basically, to stop
making any unnecessary global changes to your blog.

That could help, indeed. But here's the problem. Due to the "G" in "Static Site
Generators", seemingly "local" changes can mess up other parts of your site too!

Changes in specific configs, templates, even in your content. In the end, that
RSS bug was triggered by a [specific post]({{< ref
"/posts/why-use-structured-errors-in-rust-applications/" >}}) with a `"`
character in the description. I could live in an alternative reality where I
updated Hugo first, and *then* published that post. I wouldn't expect such
destructive results from publishing a post!

Another example. While working on that same post (the 6th on my website), I
noticed that the list of posts shows only [5 posts per
page](https://github.com/Expurple/home.expurple.me/commit/c78d54d374fe73daccb43ac6655809793c5de47d)
by default, and ugly premature pagination kicks in after that. Luckily, I have a
habit of checking that page to see how the post summaries look in context. So, I
caught that issue in time.

I've always felt a little paranoid knowing that my manual testing can't cover
everything. I don't open every page and don't pay full attention to every line.
Instances like this made me more and more paranoid over time.

My inner software developer really wanted to get out, overengineer this blog,
and automate everything. And I'm finally letting that happen.

## Automation comes in

The basic issue is that I can't check every page on every update. **I want to
know when pages change**. I don't want to manually check my RSS feed every time
I update Hugo, update the theme, change a config, edit a template, or edit my
content. I want to see a list of changed pages, with a specific diff of the
changes. And then check only these changed pages in the browser, if needed.

### Writing a script

The basic idea is to simply diff the old and the new version of the generated
files.

But where do I get the old version from? If I just use whatever is lying around
since the last run, and I've switched to a different branch since, then I'm
going to see the extra diff between the branches! **I need the to-be-committed
diff specifically**. To get that, I'm going to generate both versions from
scratch: the staged version of the website, and the "clean" state of the current
branch before these changes.

With the help of `git stash`, it's very easy to temporarily "clean" the state.
We clean everything, generate the "old" version, restore the staged changes,
generate the staged version, and then restore the full unstaged local state that
I had.

In the end, after I run the script, the local state is unchanged. The result
looks as if the script has never touched Git in the first place! The only
observable effects are the generated output folders.

The whole thing takes around 0.3 seconds on my laptop. Tools like Git and Hugo
are great not just because they are fast, but because they are composable and
can be used to build other fast tools on top.

Now the only thing that's left is actually diffing the two output folders. I
don't like old-school `diff` output. I prefer an easier-to-navigate GUI with a
separate split view for every file, like in VSCode. I know that I can launch
`code --diff old.file new.file` to open a diff view comparing two files. It's
very convenient, but it can't compare folders. So, I use an
[extension](https://github.com/moshfeu/vscode-compare-folders) for that. I
haven't yet found a way to trigger the extension from the script. But opening it
manually in VSCode is fast enough, too.

Here's a permalink to [the current version of the
script](https://github.com/Expurple/home.expurple.me/blob/a674fad56fa24bdab575973844cf972ecda8aaa9/review_staged_changes.sh),
in case I move it later. To see the latest version, explore the
[repository](https://github.com/Expurple/home.expurple.me/?tab=readme-ov-file#homeexpurpleme)
starting from the README. I keep my workflow documented.

## The results

After writing this script, I finally got myself to [leap over several Hugo
versions in a few
days](https://github.com/Expurple/home.expurple.me/commits/?since=2025-06-26&until=2025-06-28),
fixing all the issues that were preventing the update. Detecting and debugging
these issues was much easier with the diff.

Now I check the diff on any major change, such as updating Hugo, updating the
theme, publishing new posts, editing configs or templates. I feel much more
confident and encouraged to make these changes. Even semi-automated testing can
do wonders for your velocity and mood.

I love Rust's ["fearless
concurrency"](https://blog.rust-lang.org/2015/04/10/Fearless-Concurrency/)
approach and using my PC "fearlessly" in general. I'm inspired by this idea. It
has become one of my main guiding principles.

## Outstanding problems / future ideas

- Better automation for Hugo updates. Even though Hugo updates are one of the
  main problems described in this post, my script doesn't support this scenario
  yet. Both Hugo invocations in the script use the same global Hugo version. For
  now, I manually do something like
  <!-- This comment acts as a blank line. Actual blank lines trigger https://github.com/mnjm/kayal/issues/62 -->
  ```bash
  hugo --destination public.bak --cleanDestinationDir

  # (manually update Hugo to the new version)

  hugo --destination public --cleanDestinationDir

  # (manually diff these two folders in VSCode)
  ```
  <!-- This comment acts as a blank line. Actual blank lines trigger https://github.com/mnjm/kayal/issues/62 -->
  It works well enough. The friction is low because my overall "diffing"
  workflow is already sorted out.
- [File format
  validation](https://discourse.gohugo.io/t/hugo-should-validate-output-formats/55248)
  (HTML, CSS, JS, RSS, sitemap.xml, robots.txt). Even though my script can show
  me the diff, I can still miss the issues in that diff when reviewing it. It
  would be nice to incorporate some automated linter or website validation tool.
  For example, that broken RSS feed wasn't even valid XML. If I didn't open it
  in the browser and notice it, the linter would've still caught it (if I used
  such a linter).
- CSS edits are "global". They don't show up in the diff of individual HTML
  pages. You need to manually find and check all the places where the rendering
  could change. Perhaps this could be solved by diffing the rendered UI image?
  Or using some dev tools to find the elements on my website that are affected
  by a change of a particular CSS selector?
- An interactive prompt to update the `lastmod` date when editing a post. I'm
  always a little scared of forgetting to do that, even though that's not a big
  deal. Why an interactive prompt rather than setting the date automatically?
  Because I don't want to bump the date on *every* change to the source file
  (like adding a new tag or changing markdown formatting).
- I'm yet to take a look at the biggest Hugo websites and see what they do.

[Making a website is
hard](https://blog.cathoderaydude.com/doku.php?id=blog:making_a_website_is_hard).
As fearless as I'd like to be, I still don't have the time and energy to find,
choose, and stitch together these tools. But it's still very nice that SSGs even
provide this "preview" output that can be diffed and validated, and doesn't
auto-update under my feet.

Eventually, I want to see Hugo website validation become a solved problem with a
recommended tool selection, [CI workflow
examples](https://discourse.gohugo.io/t/hugo-should-validate-output-formats/55248/5?u=expurple),
and so on. I'll post an update if I make any progress on that.

---

## Related reading

My favorite posts about the tradeoffs of SSGs in general:

- ["Static site generators"](https://fvsch.com/static-site-generators)
- ["making a website is
  hard"](https://blog.cathoderaydude.com/doku.php?id=blog:making_a_website_is_hard)
- ["7 Reasons to Use a Static Site
  Generator"](https://www.sitepoint.com/7-reasons-use-static-site-generator/)
- ["7 Reasons NOT to Use a Static Site
  Generator"](https://www.sitepoint.com/7-reasons-not-use-static-site-generator/)

Rust's "fearless" development philosophy:

- ["Fearless Concurrency with
  Rust"](https://blog.rust-lang.org/2015/04/10/Fearless-Concurrency/)
- ["Toward fearless cargo
  update"](https://predr.ag/blog/toward-fearless-cargo-update/)

## Discuss

- [{{< icon "discourse" >}}
  discourse.gohugo.io](https://discourse.gohugo.io/t/fearless-website-updates-with-hugo/56371)
- [{{< icon "reddit" >}}
  r/gohugo](https://www.reddit.com/r/gohugo/comments/1pm88e6/fearless_website_updates_with_hugo/?)
- [{{< icon "reddit" >}}
  r/webdev](https://www.reddit.com/r/webdev/comments/1pm880s/fearless_website_updates_with_hugo/?)
- [{{< icon "hackernews" >}} Hacker
  News](https://news.ycombinator.com/item?id=46261383)

[^tweak-later]: At least, initially! I've edited some styles and templates
since.

[^statically-linked]: [*Statically-linked*](https://en.wikipedia.org/wiki/Static_build#Static_building)
    generators like Hugo take this to the next level.

    You can just *stay* on an old version. All [Hugo
    releases](https://github.com/gohugoio/hugo/releases) from 12 years ago are
    still available as binaries that you can download and run. These old Hugo
    binaries will keep working *forever*, unless your OS changes in a radical
    way. They don't stop working if you update Python. They don't stop working
    if you update Node. The installation doesn't fail because it couldn't
    download some library. No bullshit like that.

    There's little to no security risk in staying on an old version of a static
    site generator. Being up-to-date matters when you have an online CMS (such
    as [Wordpress](https://en.wikipedia.org/wiki/WordPress)) that's exposed to
    the Internet.

[^theme-bug]: Actually, Hugo just exposed a
[bug](https://github.com/mnjm/kayal/pull/67) in my theme's template. But, as
always, I can rarely tell right away whether it's Hugo or the theme that's
responsible for an issue that I'm having.

[^why-an-ssg]: And if, like me, you still want to use a static site generator
instead of a cloud platform.
