+++
title = "State of present-me [July 2023]"
date = 2023-07-16
+++

Earlier this year I started working on a new version of [present-me](https://prme.stanistan.com). 

After shipping the [first version][1], it was time to test it out. I convinced 
some very patient folks on my team to give it a shot for some large PRs and we hit
some roadblocks... quickly.

1. The diffs were actually wrong 
2. It was easy to fully break the page/UI 
3. The post presentation format wasn't useful in practice 

There were unrelated things that I wanted to change (a full frontend rewrite)
and try (nuxt with a go backend) that got me much further along into being able 
to actually fix the issues laid out above.

### This is a full rewrite!

{{ image(path="../static/images/present-me-2023-01.png") }}

- What used to be a static website is now a SPA using [Nuxt][nuxt]. This may change in the 
  future, but I wanted to write components in a component friendly framework. Also, I 
  wanted a frontend framework. 

- For styling, now using [tailwindcss][tailwindcss] for utilities.

- Diff and syntax highlighting is now using [prismjs on the client][prismjs]. It used to be
  goldmark rendering on the server. Prism has a syntax highlihting package that can do
  diffs + syntax highlighting so you get richer formatting.

- Diff rendering now matches what GitHub does for their PRs instead of rendering the full
  `diff_hunk` that the API returns. 

- Now using a components to render the UI instead of plain markdown formatting. This fixed 
  a pretty eggregious issue where if you had a diff embedded in your diff the markdown would
  break in spectacular ways.

- New bespoke slides (`v0` really). Raw markdown formatting currently removed. Not sure if 
  it needs to exist at all.

- The website is minimally responsive. And the design is more familiar to what gh does.

[1]: /writes/present-me
[nuxt]: https://nuxtjs.com
[tailwindcss]: http://tailwindcss.com
[prismjs]: https://prismjs.com
