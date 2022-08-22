+++
title = "Structuring side projects"
date = 2022-01-03
draft = true
+++

Over the past year or so, I've been using [go][1] as my primary programming
language. This is mostly because it's what I use for work, and now after two years (ish),
the one I'm most comfortable with as my daily driver.

This blog is shipped as a static website, but things like [present-me][2] are applications
running on servers running somewhere.

## The tools

I prefer simple tools over complex ones, which sometimes leads me to think that no tool,
or a tool that's just custom built and small for a purpose is better than a standard
alternative if it includes a different runtime.

I started with that intention, but eventually realized that I needed
a _system_ to managing change and increasing complexity in frontend components.

Introducing another runtime and build-system (`node`), while at first felt like
way too much, turned out to be something I would need for anything larger than,
well, a fully un-styled page, especially if I thought about being able to change
it over time.

### Hermit

First thing I need is something to manage the tools (and version), so of course, I use
another tool.  [hermit][3] is an open-source project from Cash which aims to make local
dependencies (without something like docker) easy to manage, and *ahem* hermetic.

I've found first installation  of hermit to be a bit confusing, but once the tool is
in place it really does wonders for local workflows. And makes managing different kinds
of tools (go and node) in a single project simple.

### Go static server

You can fairly trivially serve static content with Go. For something that is a simple webpage,
you might want to do a simple Apache configuration or Nginx, but then adding any other
behavior to the app becomes a bit more difficult.

```go
package main

import (
    "net/http"

    "github.com/gorilla/mux"
    "github.com/NYTimes/gziphandler"
)

func main() {
    // ...
    r := mux.NewRouter()
    // ... add routes for api like things
    // ... then serve the static page with GZIP
    r.PathPrefix("/").Handler(gzip.Handler(http.FileServer(http.Dir("/static"))))
    // ... then do the serving
}
```

### Nuxt

I really dont want to write any JavaScript starting out for a website. My preference is the
simplicity of HTTP verbs, static pages, and all logic happening in one place, on the
server, which I'd write in Go. But there's always the situta

I've used [Nuxt][5] because of the simplicity of the [Vue.js][6] application model, basically
it mostly reads like HTML. I want to start with the composition of the fully static website and
then have a nice way of

and it's possible that I want to write some frontend features
that I might need some client-side features, and that by default, I'd want to ship it
fully without a NodeJS server.

I might move to something more React flavored in the future.

### Tailwind

Well, [tailwind][4] is pretty good!

- the docs are incredible
- it's a standard tool used all over the place
- it's similar to CSS frameworks that I've used in the past (at Etsy)
- production performance

## Development

## Shipping

### Docker

### Google Cloud Run


[1]: https://go.dev
[2]: https://present-me.stanistan.dev
[3]: https://cashapp.github.io/hermit/usage/shell/
[4]: http://tailwindcss.com
[5]: http://nuxtjs.org
[6]: https://vuejs.org
