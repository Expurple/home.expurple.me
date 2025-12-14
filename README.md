# [home.expurple.me](https://home.expurple.me)

My personal website.

## Build

It's a static site built using [Hugo](https://gohugo.io/) with
[Kayal](https://github.com/mnjm/kayal) theme.

To build it, you only need to:

1. `git clone` with `--recursive` flag (downloads the theme as a git submodule).

2. [Install Hugo](https://gohugo.io/installation/) (at the right version! See
    below).

3. Follow the [Hugo documentation](https://gohugo.io/getting-started/) and work
    with Hugo as normal.

There are no more additional dependencies or custom build steps.

### Hugo version

To deal with breaking changes in Hugo, I only use and support one specific
version at time.

For reliable builds, I recommend installing the same Hugo version as I use.
Check the version in the [`.hvm`](./.hvm) file.

Choose an installation method that **won't** auto-update Hugo. If you use
[`hvm`](https://github.com/jmooring/hvm) (recommended), it will use the right
Hugo version automatically. Alternatively, you can pin Hugo in your package
manager, or sidestep the package manager and download the Hugo binary from
[Github releases](https://github.com/gohugoio/hugo/releases). This is the right
way to install unstable software.

Hugo has three ["editions"](https://gohugo.io/installation/linux/#editions) with
different feature sets. The minimal "standard" edition is enough to build this
website. Any edition should work.

## Deploy

The site is deployed on Github Pages. Deploy happens automatically on every push
to `master`. See [.github/workflows/hugo.yaml](./.github/workflows/hugo.yaml)
for details.

For the comments to work, I also went through the [Giscus](https://giscus.app/)
confuguration guide. It requires a public Github repository with
[Discussions](https://docs.github.com/en/discussions/collaborating-with-your-community-using-discussions/about-discussions)
enabled. It can be any (even empty) repository. But I've simply connected this
main repository.

## Commenting on posts

Comments are powered by [Github
Discussions](https://github.com/Expurple/home.expurple.me/discussions) on the
repo. To comment, you need a Github account.

You can either browse and comment directly on Github, or use the
[Giscus](https://giscus.app/) comment widget on my website. It's configured in
[./layouts/partials/comments.html](./layouts/partials/comments.html).

## My workflow

Before committing changes, I run
[./review_staged_changes.sh](./review_staged_changes.sh) to generate the old and
the staged version of the site and then manually review the diff in VSCode.

## License

The markdown writing in `content/` is licensed under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

The software part is licensed under the [MIT
License](https://opensource.org/license/mit). That includes Hugo `config/`,
custom templates, HTML, CSS, JS, shell scripts.

I reserve all rights to the other materials I own, just in case I forget to
explicitly license them here.
