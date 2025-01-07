# [home.expurple.me](https://home.expurple.me)

The source code for my personal website.

## Build

It's a static site built using [Hugo](https://gohugo.io/) with
[Kayal](https://github.com/mnjm/kayal) theme.

There are no custom build steps, just standard Hugo workflow. See the
documentation linked above.

## Deploy

The site is deployed on Github Pages. See
[.github/workflows/hugo.yaml](./.github/workflows/hugo.yaml) for details.

For the comments to work, I also went through the [Giscus](https://giscus.app/)
confuguration guide. It requires a public Github repository with
[Discussions](https://docs.github.com/en/discussions/collaborating-with-your-community-using-discussions/about-discussions)
enabled. It can be any empty repository, even though I chose to use this main
repository with the website sources.

## Commenting on posts

Comments are powered by [Github
Discussions](https://github.com/Expurple/home.expurple.me/discussions) on the
repo. To comment, you need a Github account.

You can browse and comment either directly on Github, or using the
[Giscus](https://giscus.app/)-based comment widget on the website. It's
configured in
[./layouts/partials/comments.html](./layouts/partials/comments.html).

## License

The markdown writing in `content/` is licensed under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

The software part is licensed under the [MIT
License](https://opensource.org/license/mit). That includes Hugo `config/`,
custom templates, HTML, CSS, JS.

I reserve all rights to the other materials I own, just in case I forget to
explicitly license them here.
