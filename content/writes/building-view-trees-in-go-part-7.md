+++
title = "Building view-trees: What's up with Renderables [Part-7]"
date = 2024-01-04
+++

Previously: [intro][part-1], [the basics][part-2], [error handling][part-3],
[async data fetching][part-4], [http.Handler][part-5], and [more][part-6].

---

## _hmmm_

Ok, so I'm starting here not knowing exactly where I want to go,
and then using this to move forward. Going forward can mean staying
where we are with our design.

Following up on the [last post][part-6], there still is something that
doesn't feel right with the design of the library.

Mainly, the difference between the following interface functions:

- `Renderable(context.Context) (Renderable, error)`
- `RequestRenderable(*http.Request) (AsRenderable, error)`
- `ErrorRenderable(context.Context, error) (AsRenderable, error)`

For the first one, we covered that it's useful for us to have something
that is representalbe this way– _fine_. For the second and third however,
we have two things that seem different but are closely related.

1. We don't need to pass a context for `RequestRenderable` becuase a `Request`
   has a context, otherwise I'd be passing `func(ctx, r)`.
2. We _might_ not need to pass an `err` to `ErrorRenderable` since
   a context can have a [`CancelCause`][cancel-cause], but either way
   we come from a place of `context` and `value`.


It brings up the question, and one of the reasons I punted on errors
after solving errors: Should they be unified?

- Should the library follow the principle: everything only gets a
`context.Context`, implying the existence of a `*veun.Error` which
has a `Context` interface similar to that of `*http.Request`?

- Should the library follow the principle: only pass a context and
you use that to determine your current state to know what kind of
renderable you are producing ala `ctx.Err()` and `ctx.Cause()`? One
can attach arbitrary values to `Context` and/or create different
ones for different use cases.

## Exploration

Writing our own `context.Context` wrapper would mean that the interface
implementor would have to dispatch on some kind of switch statement...

```go
func(ctx veun.Context) (AsRenderable, error) {
    switch ctx.Type() {
    case veun.Request:
        // ... extract the request
    }
}
```

The above feels like code that would be fairly error prone. There's
another way to represent a similar thing, and it's really not bad
at all.

```go
func(ctx veun.Context) (veun.AsRenderable, error) {
    return ctx.Renderable(veun.R{
        Request: func(r *http.Request) (veun.AsRenderable, http.Handler, error) {
            // ctx, and r are available here
        },
        Error: func(err error) (veun.AsRenderable, error) {
            // ctx and err are available here
        },
    })
}
```

I'd need to explore the _calling_ code and how rendering and composition
would work in practice actually. Another thing to keep in mind is is if
`veun.R` (for renderable) is also an `AsRenderable`?

A thing that's nice is if we add _more_ factory types then it's easy to
extend the struct. A thing that isn't so nice is that it encodes the kinds
of things you need to do in the library and doesn't give more flexibility
to try other ways of executing it.

### `veun.Error` tho

Let's try out a hypothetical `*veun.Error` that's similar in structure
and interface to `*http.Request`.

```go
struct Error { Err error /* ... */ }

func (e *Error) Context() context.Context { /* ... */ }

func (e *Error) WithContext(ctx context.Context) *Error { /* ... */ }

func (e *Error) Error() string { return e.Err.Error() }

func (e *Error) Unwrap() error { return errors.Unwrap(e.Err) }
```

I'm not really sure we'd need the `WithContext` here, but why not, let's
keep it consistent.

Also we are fulfilling the `Error` and `Unwrap` interfaces for errors.

## 🤔 Does any of this actually help?

While looking at errors, in my implmentations and tests, I kept coming back
to a couple of things. Renaming `RequestRenderable`, `ErrorRenderable`, `Renderable`,
`View`, etc.

# Re-View, a pivot

At first when starting to write this post, I wanted to explore errors and contexts.
A couple of different things I tried were interesting but _not good enough_ or not
useful enough, or not intuitive enough. And just repeating `Renderable` really was the
thing to _fix_.

There's an adage in go that is something like: return structs and accept
interfaces, and in our prior situation we were just throwing around interfaces,
this meant for concrete implementations, there was always wrapping and unwrapping.

In the search for the _right_ ergnomic and naming I've moved around
the and renamed the library code _a whole bunch_.

### Template

In our original implementation, we were returning a `View` struct which was
`Renderable`. And in a lot of the writing, I was referring to `View` and `Renderable`
as interchangeable concepts.

I've since separated that out for things to be renderable to HTML [here][htmlrenderable],
and there's also the `Div` functions we can construct using `veun.Raw`.

**Concepts:**

- `View`
- `ViewForError`
- `ViewForRequest`

These are the interface functions we're building, `Template` is an implmentation detail
of directly using a `html/template`.

## Views

```go
type MyView struct { /* fields elided */ }

func (v MyView) View(ctx context.Context) (*veun.View, error) {
    return veun.V(veun.Template{
        Tpl:   someTpl,
        Data:  nil,
        Slots: veun.Slots{ /* ... */ },
    }).WithErrorHandler(someErrorHandler), nil
}
```

A few things jump out from the new implementation of the (now called)
`AsView` interface: `veun.V`, `veun.Template`, and `*veun.View`.

`*veun.View` is an opaque type, and can only be constructed (in a useful way),
by `veun.V`. This _constructor_ combines `HTMLRenderable` and `ErrorHandler`.

We're not doing duck-typing by whether or not the error handler interface
is attached to `MyView`, we're doing it based on wether or not an error
handler was explicitly attached to the `*View` constructed.

This allows us to conitnue to return `nil` (also ergonomic for construction).

_Aside:_ We _are_ doing duck-typing inside of `V` but afterwards we get a
concrete implementation.

### View constructors

Other types, like `ViewForRequest`, and `ViewForError` return an `AsView`.

### Rendering

I made an explicit decition to change `Render` to a function that accepts an `AsView`,
and the rendering to be opaque behind and `HTMLRenderable` encapsulated by
a `View`.

In the prior version it was actually a bit confusing on what you can call render
on and what you can't, where you'd get error handling and where you wouldn't. I
wanted to remove that kind of ambiguity and make it simpler to do more.

# "veun/vhttp"

I moved all of the http related types and functions to the `vhttp` package. It's
called `vhttp` since you're using it in conjunction with the `net/http` standard
library and otherwise you'd be import/aliasing it.

We've got `vhttp.Handler`, `request.Handler`, and a package of middleware that
can be useful for use with standard `mux`.

## What it looks like

Given a `MyView` like we wrote above that renders something, we can have it be
created by an HTTP request.

```go
import (
    "context"
    "net/http"

    "github.com/stanistan/veun"
    "github.com/stanistan/veun/vhttp"
    "github.com/stanistan/veun/vhttp/request"
)

func (v MyView) View(_ context.Context) (*veun.View, error) {
    return veun.View(/*...*/), nil
}

func MyViewRequestHandler() request.Handler {
    return request.HandlerFunc(func(r *http.Request) (veun.AsView, http.Handler, error) {
        // - We can extract data from the request.
        // - We can push up an error
        // - or we can do something with the response, like a 404, or anything.
        return MyView{}, nil, nil
    })
}

func main() {
    // ...
    mux.Handle("/some/path", vhttp.Handler(MyViewRequestHandler()))
    // ...
}
```

## Demo

I'm working on a demo webserver where there are examples of different ways
of doing composition, routing, redirects, errors, etc, and the kinds
of patterns that become possible and useful when you have all of this
in one place.

- website: [veun-http-demo.stanistan.com][demo-server]
- source: [github/veun-http-demo][veun-http-demo]

In the future, I'd like to actually build (or rebuild) something using the
library as well as better document the different components that are part
of the demo server.

[part-1]: /writes/building-view-trees-in-go-part-1
[part-2]: /writes/building-view-trees-in-go-part-2
[part-3]: /writes/building-view-trees-in-go-part-3
[part-4]: /writes/building-view-trees-in-go-part-4
[part-5]: /writes/building-view-trees-in-go-part-5
[part-6]: /writes/building-view-trees-in-go-part-6

[cancel-cause]: https://pkg.go.dev/context#CancelCauseFunc
[htmlrenderable]: https://github.com/stanistan/veun/blob/64f2cc1aee66ff6d0317c751db1abd683ca3b37e/veun.go#L12-L15
[demo-server]: https://veun-http-demo.stanistan.com
[veun-http-demo]: https://github.com/stanistan/veun-http-demo
