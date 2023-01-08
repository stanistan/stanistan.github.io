+++
title = "Introducing: (pr)esent me"
date = 2021-04-13
aliases = [
    "/writes/2021/04/13/present-me"
]
+++

[(pr)esent-me][1] **is an experiment** to try to give the author of a Pull Request
a better way to convey why a changeset looks the way that it does, and how the
folks reading and reviewing it should approach it.

{{ image(path="../static/images/present-me-01.png") }}

## Why?

For small Pull Requests, the one line title, and description
are enough to convey context and intent for a change. They
can get reviewed quickly, merged seamlessly, everything is obvious.
This is great, ya done.

But when PRs get large, they start to fail as a means of review and communication.
Ya not done :(

When I look at a PR, I'll look at the title, then the patch, then sometimes
go back and read through the description after mentally accumulating some questions
before commenting to make sure I have all the context, but then I've lost my place.

I imagine that when I've submitted large PRs for folks to review the same kind of thing
happens. The fact that the changeset is just a changeset, ordered by file,
very much doesn't help the situation.

Even when I leave comments on the PR to provide context to specific parts of a change
and why it's important, they are ordered in the same way, some file happens to be
first. Then I have to rely on people not just to understand the context of the PR,
but also how I want to present it by annotating the comments themselves.

This is an entirely bad way to conveying information with too many implicit assumptions,
and too many ways for it to _not work_.

## What

[Present me][1] leverages the __Review__ feature on Github, allowing the grouping of
multiple comments to create an ordered presentation of annotated changes.

__How?__

{{ image(path="../static/images/present-me-02.png") }}

1. Create a PR as regular
2. Start a review of your own PR
3. Leave comments on your PR as part of the review.
   - _Comments prefixed with a number will be ordered that way_.
   - Submit your review: <https://github.com/stanistan/invoice-proxy/pull/3#pullrequestreview-625362746>
4. Go to [the website][1], you can put in the URL in the form above (including pullrequestreview),
   or if you put in the PR url (no fragment), it'll try to find the first review
   written by the author of the PR.
   - [generated post](https://present-me.stanistan.dev/stanistan/invoice-proxy/pull/3/625362746/post)
   - [generated slides](https://present-me.stanistan.dev/stanistan/invoice-proxy/pull/3/625362746/slides) using <https://revealjs.com>
   - [generated md](https://present-me.stanistan.dev/stanistan/invoice-proxy/pull/3/625362746/md)

[1]: https://present-me.stanistan.dev
