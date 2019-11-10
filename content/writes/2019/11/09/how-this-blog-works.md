+++
draft = true
title = "How this site works"
date = 2019-11-09

[taxonomies]
tags = ["meta"]

[extra]
include_toc = false
+++

Like lots of folk on the internet, I have a website that's powered by
a static site generator and hosted somewhere on the GitHub.

This post serves two functions:

1. It's something I can actually publish to get over the weird fear of putting
   text on the internet.

2. Some self documentation on how this works, because as I've gone back to this
   over the past few months to add some polish, or just, _make any kind of
   changes_, I've been surprised by things that I've done for myself in the
   past.

Here are some immediately relevant links:

- [The repo on github][site-repo]
- [Zola][zola] - the static site generator I use, which is written in [Rust][rust]

## Branches, or `the-details` vs `master`

Unlike the default github's repo-specific pages, you cannot use a `gh-pages` branch
to host a site for a _user_. You end up having to create a repository called
`<you>.github.io`, and whatever is on the `master` branch will end up getting served
to the world. ([source][github-pages-branch-docs])

Luckily, we can set a [default branch][default-branch] for the actual _editing_ of
the code and content, and for some reason, I decided to call it `the-details`.

Zola builds the static site into the `public/` directory at the root of the repo,
and I use a script to push everything in

### and sometimes there's a aprty

and when we party we party harder

#### And more

[site-repo]: https://github.com/stanistan/stanistan.github.io
[zola]: https://www.getzola.org
[rust]: https://www.rust-lang.org
[github-pages-branch-docs]: https://help.github.com/en/github/working-with-github-pages/about-github-pages#publishing-sources-for-github-pages-sites
[default-branch]: https://help.github.com/en/github/administering-a-repository/setting-the-default-branch
