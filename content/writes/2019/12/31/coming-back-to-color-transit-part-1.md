+++
title = "Coming back to color-transit (part 1)"
date = 2019-12-31
+++

_Note:_ I'm writing this as an experiment in coming back to a side-project
that has long been sitting around, and quitetly.

Looking at it with old eyes and high level questions (of myself) like:

- Does it still work?
- Can I understand it?
- Can I still run it locally?
- Can I make changes to it?
- How long does all of that take?

## Background

{{ image(path="../static/images/color-transit-screenshot.png") }}

Four-ish years ago, I wanted to try writing a project in [ClojureScript][cljs].

A few years before that I wrote a bunch of Clojure and had just wanted
a brief and fun refresher project with the langauge, but trying a different
runtime.

I also wanted to play around with the canvas API, because I had never really
done much _drawing_. Why limit yourself to one thing a time, right?

__This project was [color-transit][repo-link].__ It's a single static page that
cycles through color graidents, and boy does it do that.

You can see it live [here][live-link]. This link was actually surprising to me:
_it's running on this domain._ In hindsight, of course it is, this is all github
pages... I just didn't immediately realize that any repo that has this `gh-pages`
branch would end up on this site. But here we are. Cool. Works as intended, I guess.

## First look back at the repo

Wow, there's like no `README` at all.

I was definitely not doing this project for any kind of reproducability, just a
playground.

It's using [`leiningen`][lein], which was the standard at the time when
building clj/s projects, I'm not really sure if that's still the thing people
use. Since then, or maybe even at that time, [`boot`][boot] was a thing that
started to exist. Both are mentioned in the clojure(script) docs.

The project uses [`lein-figwheel`][lein-figwheel] for live reloading, which
is pretty neato.

### Commits & Timeline

The first obvious thing I can see is that most of the work happened quickly,
On the day before Christmas, and then the day after.

The commits on the days following were cleanup and reorganization, and somehow
a few weeks later I came back to ship it to a `gh-pages` branch. I just checked
to see _why_ I decided to do this, maybe it was when the feature shipped, but
looking at the [docs][github-pages-docs], that wasn't it... I did this over two
years after the _last update_ to that documentation (Dec, 2013 vs Jan, 2016).

Also looking at the current way to [ship to the branch][script-link], dang this
is a mess compared to what I'm doing for _this specific site_. But it worked
as well as it needed to.

## Does it still work?

Yep. That's pretty cool- it's just some JS that's been hanging out on a CDN
for the past few years.

### Local development

Instead of installing everything (clojure and lein) locally, I am going to try
and run all of this in a [docker container][clojure-docker].

#### First attempt

The `Dockerfile`....

```Dockerfile
FROM clojure:slim-buster
WORKDIR /usr/app

COPY project.clj .
RUN lein deps
```

And then running it...

```sh
docker build -t color-transit .
docker run --rm -v "$PWD":/usr/app color-transit lein figwheel
```

Looking through the _checks notes_, hundreds of lines of stack trace, I see
`Caused by: java.lang.ExceptionInInitializerError: null`.

{{ details_snippet(summary="Full stack-trace", path="color-transit/trace01.txt") }}

#### Down to JDK8

Changing the base image to `clojure:openjdk-8-slim-buster` fixes the initial
`null` pointer exception, but now I'm getting another one.

{{ details_snippet(summary="Second stack-trace", path="color-transit/trace02.txt") }}

It's not all bad though, if I run `lien cljsbuild once` in the container, I get some
good news...

```
Compiling "resources/public/js/main.js" from ["src"]...
Successfully compiled "resources/public/js/main.js" in 2.4 seconds.
```

Nice.

#### Version mismatches & figwheel

My assumption here is that I needed to update/specify all of the correct
versions for Clojure, ClojureScript, and Figwheel. I looked up a working
example from [this flappy bird demo][flappy-bird-demo].


```diff
diff --git a/project.clj b/project.clj
index 644deab..babc3f0 100644
--- a/project.clj
+++ b/project.clj
@@ -1,9 +1,8 @@
 (defproject color-transit "0.1.0-SNAPSHOT"
-  :dependencies [[org.clojure/clojure "1.7.0"]
-                 [org.clojure/clojurescript "1.7.170"]]
-  :plugins [[lein-figwheel "0.5.0-1"]
-            [lein-cljsbuild "1.1.2"]]
-  :hooks [leiningen.cljsbuild]
+  :dependencies [[org.clojure/clojure "1.9.0"]
+                 [org.clojure/clojurescript "1.10.312"]]
+  :plugins [[lein-cljsbuild "1.1.4" :exclusions [org.clojure/clojure]]
+            [lein-figwheel "0.5.16"]]
   :clean-targets ^{:protect false} [:target-path "out" "resources/public/js"]
   :cljsbuild {
     :builds {
```

This ended up telling me that the app was running on port `3449`, so I needed to
udpate the command...

```sh
docker run -it --rm -v "$PWD":/usr/app -p 3449:3449 color-transit lein figwheel
```

Though this works, the issue is that it downloads all of the `figwheel` dependencies
each time it runs (for the first time).

The trick is to add this to the `Dockerfile`.

```Dockerfile
RUN lein figwheel :check-config
```

I found this looking around the source code looking for
"Figwheel: Cutting some fruit, just a sec..." and finding that I could run `:check-config`
to download all of the dependencies.

_Aside:_ Apparently there's an entirely new version called `figwheel-main`, but I'm not
going to go all the way over there just yet.

### How long did all that take?

To answer one of the questions I asked myself in the beginning... getting a dev
environment up and running for this took about two hours.

Getting a blog post out and running took another month.

- [The commit getting it to work](https://github.com/stanistan/color-transit/commit/b9a5a144f090fb2059d340a809e6f12bd6e23b14)

## The `gh-pages` script

Looking at this, it's obviously a bunch of stuff that I had copy pasted
from other places on the internet... all of the whitespace is a mixture
of tabs and spaces- and it just kind of works well enough.

## ClojureScript?

```
src/
└── color-transit
    ├── canvas.cljs
    ├── canvas_set.cljs
    ├── color.cljs
    ├── core.cljs
    ├── dims.cljs
    └── interval.cljs
```

Most of the effor here was going back to get this running and operational, and
I also wanted to jump into the `cljs` a bit to see if I can traverse it at all,
or if I could make some kind of substantial change and deploy it. But I don't
really want to be doing that. Let's dig into the meat of the "app."

### JS Wrappers

`interval`, `canvas`, `dims`... These are all wrappers around "native" JS methods
in order to have them appear to be, or operate as immutable values, like clojure
expects idiomatically.

For example:

```clj
(defn fill-rect
  [ctx x0 y0 x1 y1]
  (.fillRect ctx x0 y0 x1 y1)
  ctx)

(defn ctx
  "Apply f to the context of the canvas, return the canvas.
   This is useful for chaining ctx methods.
   (-> canvas
       (ctx fill-style ...)
       (ctx fill-rect ...))"
  [canvas f & args]
  (apply f (:ctx canvas) args)
  canvas)
```

These make it so that it's easier to chain methods, and apply transformations
to the canvas context in a real clojure-y way.

Functions that do mutation of global state, (like the window), have `!` at the
end. For example `full-screen!` or `start-app!`.

### The fun part

_or, how this entire thing actually works._

The app's html is defined in `public/index.html`, and when the it starts,
we create the canvas context using `query->Canvas`, this is a container that
holds the `2d` context of the `canvas` element in the `DOM`, as well as the
actual element, and dimensions, defined as:

```clj
(defrecord Canvas [el ctx w h])
```

The above js wrapping functions, operate on `Canvas` records.

When the app starts it creates a `CanvasSet`, which links the `Canvas` to the
`color-sets` that it will be running through. **The application state operates
pretty much solely on a `CanvasSet`**.

#### Startup

The app starts with a few pre-defined colors:

```clj
(let [colors [[0 10 0]
              [200 155 255]
              [40 40 40]
              [255 0 0]
              [0 255 255]
              [100 233 67]]]
  ;; ...
)
```

We take these colors (all `[r g b]` format), and randomize their order into `num-sets`.
This is stored in the `app-state`, and we can live inspect it using the `lein repl` that
get started with `figwheel` app.

```clj
dev:cljs.user=> (in-ns 'color-transit.core)
dev:color-transit.core=> (->> @app-state :canvas-sets first :color-sets (map :colors))
([[0 10 0] [100 233 67] [255 0 0] [0 255 255] [40 40 40] [200 155 255]]
 [[200 155 255] [0 10 0] [40 40 40] [255 0 0] [100 233 67] [0 255 255]]
 [[40 40 40] [0 255 255] [0 10 0] [200 155 255] [255 0 0] [100 233 67]])
```

In our start up we say we want `3` sets, and each one has a `shuffle`-d list of the
original colors provided. **The three sets correspond to three stops in the
generated gradient,** and the colors that they will be transitioning to.

An initial `color-set` looks like:

```clj
{ :colors colors
  :color-queue [ ]
  :current-color: (first colors) }
```

- `:colors` - are each of the colors in that _one_ gradient step we'll be
  fading through,
- `:color-queue` - a queue (FIFO), of colors that we'll be moving through
  in the fade,
- `:current-color` - what color are we currently displaying.

Our canvas drawer (in `core`) will only draw the `current-color`, and we
pre-compute the `queue` up front as infrequently as possible so that we
do as little work when drawing the gradient as possible.

All of that happens in `color/compute-next-state`.

#### Computing the color transitios

`compute-next-state` has two main branches of logic:

1. the first is when the queue is non-empty, we take the color at
   the head of the queue, and update `current-color` with it. This runs
   until the queue is drained.

2. the second is if both the initial state, and happens after the queue
   is drained... we generate a new one! Given the current color, and the
   next one in the `colors`, and the number of `steps` we want to be able
   to take from one color to the next, we compute them.

##### The maths

```clj
(defn delta [n1 n2 steps] (/ (- n2 n1) steps))
```

`delta` is simplified version of what the app does, where this operates on
one number, the app works on the destructured `[r g b]`.

```clj
(defn +delta [n n+ scalar]
  (-> (* scalar n+)
      (+ n)
      Math/floor))
```

Similarly, `+delta` increases `n` by the delta we computed earlier, `n+`,
scaled up by `scalar`, and then rounds it down.

We use these two functions to create the color queue.

Most of _everything_ else in the code is transforming the colors
into the gradient and canvas, and making sure it's running at a
specific interval in the browser.

### Wrapping up

Originally, I wasn't sure if I'd want to change _anything_ here, but
after spending the time with the codebase, I'd like to make the grandient
drawing _reactive_ to user parameterization in the UI.

So eventually, there'll be a second post, and updates to the app, and a
write up of the process.

...which will hopefully take less than a couple of months to finish...

[cljs]: https://clojurescript.org
[boot]: https://boot-clj.com
[clojure-docker]: https://github.com/Quantisan/docker-clojure
[flappy-bird-demo]: https://github.com/bhauman/flappy-bird-demo/blob/master/project.clj
[github-pages-docs]: https://guides.github.com/features/pages/
[live-link]: https://www.stanistan.com/color-transit/
[lein]: https://leiningen.org
[lein-figwheel]: https://figwheel.org
[repo-link]: https://github.com/stanistan/color-transit
[script-link]: https://github.com/stanistan/color-transit/blob/a18e9ecdece6cad0678994e1df731e047a8f8400/bin/make-gh-page-branch
