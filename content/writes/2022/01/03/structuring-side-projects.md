+++
title = "Structuring side projects"
date = 2022-01-03
draft = true

extra.toc = true
+++

Over the past couple of years, I've been using [go][1] as my primary programming
language. This is mostly because it's what I use for work the one I'm most
comfortable with as my daily driver.

This blog is shipped as a [static website][how-it-works], but things
like [present-me][2] are applications running on servers running somewhere.

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

First thing I wanted is something to manage the tools (and their versions), so of
course, I needed another tool. [hermit][3] is an open-source project from Cash which
aims to make local dependencies (without something like docker) easy to manage, and
*ahem* hermetic.

I've found first installation of hermit to be a bit confusing, but once the tool is
in place it really does wonders for local workflows. And makes managing different kinds
of tools (go and node) in a single project fairly seemless.

For packages that hermit doesn't support (like zola, this SSG), you can introduce your
own package manifest, which is only _kind of_ well documented (or was at the time I tried
out).

For completeness, after installing hermit you can add a `hermit.hcl` file in `bin/` to tell
your hermit installation to check _the current project_ (or env) for hermit packages.

```hcl
// bin/hermit.hcl
sources = [ "env:///", "https://github.com/cashapp/hermit-packages.git" ]
```

Here is my definition for zola:

```hcl
// zola.hcl
description = "A fast static site generator in a single binary with everything built-in."
binaries = ["zola"]
test = "zola --version"

linux {
  source = "https://github.com/getzola/zola/releases/download/v${version}/zola-v${version}-x86_64-unknown-linux-gnu.tar.gz"
}

darwin {
  source = "https://github.com/getzola/zola/releases/download/v${version}/zola-v${version}-x86_64-apple-darwin.tar.gz"
}

version "0.16.1" "0.15.2" {
  auto-version {
    github-release = "getzola/zola"
  }
}
```

### A static server (go)

You can fairly trivially serve static content with Go. For something that is
a simple webpage, you might want to do a simple Apache configuration or Nginx,
but then adding any other behavior to the app becomes a bit more difficult.

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

I really dont want to write any JavaScript starting out for a website. My preference
is the simplicity of HTTP verbs, static pages, and all logic happening in one place,
on the server, which I'd write in Go. But there's always the situtation where complexity
increases.

I've used [Nuxt][5] because of the simplicity of the [Vue.js][6] application model,
basically it mostly reads like HTML. I want to start with the guarantees and performance
of a fully static website and then have a nice way of adding complexity as needed.

I'm not using `node` on the backend here-- just using `nuxt generate` to end up building
a production bundle of files and using the JS ecosystem to manage builds/etc.

### Tailwind

Well, [tailwind][4] is pretty good, I've both enjoyed having a framework for writing CSS
and found it to be a bit frustrating.

It has great docs and builtins -- and when using a component-ish framework (like Vue), it
scales up really well. After starting out writing the CSS myself for present-me and this
blog like it's the early 2000s, I find myself wanting a better way of managing the
complexity of dependencies, utilities, etc.

I feel like this is probably because I'm not as disciplined with regards to maintaining
and authoring css/systems (with SASS or anything) given lack of practice.

## Development

If I'm only doing web-frontend development and don't need to iterate on the server/API
logic, I'll generally use `npm run dev` in that project directory, this is simple, and
generally it'll end up with it running at `localhost:3000`.

When I need to do server/api development I really like *save + refresh* iteration
lifecycle. For `go`, I use [`gow`](https://github.com/mitranim/gow).

### Proxies!

My go server, which generally embeds a static website has a configuration switch
that will instead run the routes as a reverse proxy instead of as an embed.

_Aside:_ I use [kong](https://github.com/alecthomas/kong) fairly often for CLI
interfaces, _also_ since it's something that we have use at cash, and it's a really
nice go-idiomatic way to build/parse/execute CLIs.


```go
type ContentServer struct {
    Serve        string `required:"" enum:"static,proxy" default:"static"`
    StaticDir    string `optional:"" default:"./static"`
    ProxyAddress string `optional:"" default:"http://localhost:3000"`
}

func (c *ContentServer) Handler() (http.Handler, error) {
    switch c.Serve {
    case "static":
        return http.FileServer(http.Dir(c.StaticDir)), nil
    case "proxy":
        remote, url := url.Parse(c.ProxyAddress)
        if err != nil {
            return nil, errors.Wrap(err, "invalid ProxyAddress")
        }

        proxy := httputil.NewSingleHostReverseProxy(remote)
        return proxy.ServeHTTP, nil
    default:
        nil, errors.Errorf("unknown serve type %s", c.Serve)
    }
}
```

In the first code example I have the file server w/ gzip, instead...

```go
package main

func main() {
    r := mux.NewRouter()

    // ... add routes for api like things
    r.PathPrefix("/api").Handler(apiHandler)

    // ... use kong to parse out the config.ContentServer struct
    var c *config.ContentServer
    contentHandler, _ := c.Handler() // of course handle errors
    r.PathPrefix("/").Handler(contentHandler)
    // ... then do the serving
}
```

Then I can, for example use `gow` to continually restart my webserver,
where I have `/api` routes and then a proxy pointing to `localhost:3000`,
which is where nuxt is running in development mode.

### What I want instead...

_(more proxies)_

Well, the above is _fine_ but if I have any kind of error with the server
the proxy fails and I get something fairly unhelpful when I go back to check
the browser window: nothing.

I want to have something that will monitor the server, and show me compile
errors if it fails.

## Shipping

### Docker

### Google Cloud Run


[1]: https://go.dev
[2]: https://present-me.stanistan.dev
[3]: https://cashapp.github.io/hermit/usage/shell/
[4]: http://tailwindcss.com
[5]: http://nuxtjs.org
[6]: https://vuejs.org
[how-it-works]: @/writes/2019/11/10/how-this-blog-works.md
