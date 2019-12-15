+++
draft = true
title = "Coming back to color-transit"
date = 2019-11-15
+++

_Note:_ I'm writing this as an experiment in coming back to a side-project
that has long been sitting quietly around.

With high level questions like:

- Does it still work?
- Can I understand it?
- Can I still run it locally?
- Can I make changes to it?
- How long does all of that take?

## Background

{{ image(path="../static/images/color-transit-screenshot.png") }}

Four-ish years ago, I wanted to try writing a project in ClojureScript.
A few years before that I wrote a bunch of Clojure and had just wanted
a brief and fun refresher with the langauge, but trying a different
runtime. I also wanted to play around with the canvas API. Why limit
yourself to one thing a time, right?

This project was [color-transit][repo-link]. It's a single static page that
cycles through color graidents, and boy does it do that. You can see it live
[here][live-link].

The first surprise is immediate to me: __it's running on this domain.__
Of course it is, though, this is all github pages, I just didn't immediately
realize that any repo that has this `gh-pages` branch would end up on this site.
But here we are. Cool. Works as intended, I guess.

## First look at the repo

Wow there's like no `README` at all. I was definitely not doing this project
for any kind of reproducability, just a playground.

It's using [`leiningen`][lein], which was the standard at the time when
building clj/s projects, I'm not really sure if that's still the thing people
use. Since then, or maybe even at that time, [`boot`][boot] was a thing that
started to exist. Both are mentioned in the clojure(script) docs.

The project uses [`lein-figwheel`][lein-figwheel] for live reloading.

### Commits

The first obvious thing I can see is that most of the work happened quickly,
On the day before Christmas, and then the day after.

The commits on the days following were cleanup and reorganization, and somehow
a few weeks later I came back to ship it to a `gh-pages` branch. I just checked
to see _why_ I decided to do this, maybe it was when the feature shipped, but
looking at the [docs][github-pages-docs], that wasn't it... I did this over two
years after the _last update_ to that documentation (Dec, 2013 vs Jan, 2016).

Also looking at the current way to [ship to the branch][script-link], dang this
is a mess compared to what I'm doing for _this specific site_. But I guess
it worked out.

## Does it still work?

Yep. That's pretty cool- it's just some JS that's been hanging out on a static
server for the past few years.

### Local development

Instead of installing everything (clojure and lein) locally, I am going to try
and run all of this in a [docker container][clojure-docker].

#### First attempt

```Dockerfile
FROM clojure:slim-buster
WORKDIR /usr/app

COPY project.clj .
RUN lein deps
```

And then:

```sh
# Should make the dependencies cached all good?
docker build -t color-transit .
docker run --rm -v "$PWD":/usr/app color-transit lein figwheel
```

This gives me a big nope, that looks like it's because my versions are incompatible
with the current version of Java.

#### Down to JDK8

Changing the base image to `clojure:openjdk-8-slim-buster` fixes the initial
`null` pointer exception, but now I'm getting some other weird one.

The fun part here is if I run `lein cljsbuild`, it actually builds the output
file and I can look at the prod/static version of the files, so that's great.

#### Updating figwheel

Apparently there's an entirely new version called `figwheel-main`, but I'm not
going to go all the way over there just yet.

Taking some of the version numbers from [this demo][flappy-bird-demo]
got it to work!

This ended up telling me that the app was running on port `3449`, so I needed to
udpate the command...

```sh
docker run -it --rm -v "$PWD":/usr/app -p 3449:3449 color-transit lein figwheel
```

Though this works, the issue is that it downloads all of the `figwheel` dependencies
each time. Fix is in the final `Dockerfile`.

#### Final Dockerfile

```Dockerfile
FROM clojure:openjdk-8-slim-buster
WORKDIR /usr/app

COPY project.clj .
RUN lein deps
RUN lein figwheel :check-config
```

### How long did all that take?

To answer one of the questions I asked myself in the beginning... getting a dev
environment up and running for this took about two hours.

[boot]: https://boot-clj.com
[clojure-docker]: https://github.com/Quantisan/docker-clojure
[flappy-bird-demo]: https://github.com/bhauman/flappy-bird-demo/blob/master/project.clj
[github-pages-docs]: https://guides.github.com/features/pages/
[live-link]: https://www.stanistan.com/color-transit/
[lein]: https://leiningen.org
[lein-figwheel]: https://figwheel.org
[repo-link]: https://github.com/stanistan/color-transit
[script-link]: https://github.com/stanistan/color-transit/blob/a18e9ecdece6cad0678994e1df731e047a8f8400/bin/make-gh-page-branch
