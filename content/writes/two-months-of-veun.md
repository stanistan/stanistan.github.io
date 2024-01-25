+++
title = "veun: two months (or so) in"
date = 2024-01-25
+++

I've been working on a [demo-server][veun-http-demo] for the [veun][veun] library,
and this has been interesting. The goal of the demo is to have some real-world
facsimile of something that one would build and I wanted to figure out some of
the warts and patterns of using the library for this use case.

{{ image(path="../static/images/veun-http-demo-screenshot.png") }}

## A list of things in no particular order

- I've stopped actively updating the series on _how I'm building view-trees_.
  It's its own thing now.

- The demo-server is a practice in literate programming. I don't know
  why exactly, as this is a ton more work to get things to be ok, but having
  demo components with no real explanation didn't feel right. I knew what was possible,
  but wanted the server to be fully self-documenting as a demo.

  This is basically the only part of the demo repo that _isn't_ shown in the UI, but
  you can [read the `lit-gen` command source][lit-gen]. I may move this out to its
  own package.

- There's a `veun/el` package. Originally, the library was built only using templates.
  I wanted functional composition, and for testing and really small _renderable_ pieces,
  using `veun.Raw` was sufficient, but it felt _wrong_.

  The first version of the package was a function that looked like `el.El("h1")`, but eventually
  I added codegen so that you could do `el.H1()`. There is actually _no way_ to directly
  instantiate an HTML element that isn't already defined as a function. There's also
  support for void elements, and you can't add child nodes to them (because the type doesn't
  implement the functionality).

  The package also does HTML encoding for attributes (`el.Attrs`) and the text primitive `el.Text`,
  which `veun.Raw` does not.

  An added benefit of this is that it should be more performant to generate views using
  this package than going through template invocation in pathological cases: recursive
  tree views (which the demo nav is an example of). Going through recursive dynamic slot
  function dispatch in `text/template` is _slower_.

- Also added `veun/template`. The functions and types in this package were all originally
  in `veun`. After introducing `veun/el`, which I started using a lot more than expected,
  it felt like the right API decision to have both of these packages be separate.

- Built-in handlers.
  Something I think is elegant: [`handler.Checked`][handler-checked],
  and its [usage][handler-checked-usage]. Basically, `Checked` goes through a cascade of
  handlers and if any of them are 404s will go to the next one. This allows for a fall
  through of dynamic pages, static urls, and custom 404s while still being able to use
  built-ins like `http.HandlerNotFound()`.

  There are a couple of other ones, like `handler.OnlyRoot`, that are great for
  the `/` base case when using the standard libary's `http.ServeMux`.

- When adding the `<!DOCTYPE html>` to my server, I learned that my implementation of
  handler checked didn't write headers in the write order and this ended up serving
  all static files as `text/plain`, which was a fun bug to track down and [fix][checked-fix].

- When adding the `notFoundHandler` to the demo server, I realized that if the server
  was being crawled, rendering a 404 would be kind of expensive.

  I wanted this handler to be much closer to static and be doing as little compute as
  possible. This view isn't going to change for _every single not found request_.

  [Adding `MustMemo`][must-memo] was really useful here. The fact that `veun.Raw` is just a string that
  directly becomes `template.HTML` made it trivial to keep all of the interfaces working
  transparently.


[veun-http-demo]: https://veun-http-demo.stanistan.com
[veun]: https://github.com/stanistan/veun
[lit-gen]: https://github.com/stanistan/veun-http-demo/blob/main/cmd/lit-gen/main.go
[handler-checked]: https://github.com/stanistan/veun/blob/3dc2a4257076026ef008cebb78686717064d5c75/vhttp/handler/checked.go#L7-L19
[handler-checked-usage]: https://github.com/stanistan/veun-http-demo/blob/main/docs/cmd/demo-server/routes.go.md#closing-out-the-server
[checked-fix]: https://github.com/stanistan/veun/commit/3dc2a4257076026ef008cebb78686717064d5c75
[must-memo]: https://github.com/stanistan/veun/blob/main/memo.go
