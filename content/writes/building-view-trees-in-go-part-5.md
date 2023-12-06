+++
title = "Building view-trees: http.Handler [Part 5]"
date = 2023-12-10
+++

Previously: [intro][part-1], [the basics][part-2], [error handling][part-3],
and [async data fetching][part-4].

---

## Small Improvements

Before we go forward, let's make some small quality of life improvements.

### Parsing templates from separate files

We've had all of our templates be inlined in strings before. This is
fine for testing, but when we're building an app, we'll want to have
something in place for loading/embedding our templates diffently.

{{ veun_diff(patch=15) }}

```go
import "embed"

var (
    //go:embed templates
    templatesFS embed.FS
    templates   = MustParseTemplateFS(templatesFS, "templates/*.tpl")
)
```

If our templates are malformed, this will panic during startup or test
time.

```go
View{
    // ...
    Tpl: templates.Lookup("my_view.tpl"),
}
```

### Others

#### Slots can be nil views

{{ veun_diff(patch=16) }}

This is a design decision, but we allow a view to be empty/nil and then
we don't render it. We might want to move this into `Render`, but
this can be here as well.

#### Documentation

{{ veun_diff(patch=17) }}

#### More meaningful library errors

{{ veun_diff(patch=18) }}

## The HTTP Server

In Go, there is one fundamental interface for serving an HTTP endpoint,
[`http.Handler`][http-handler]. In practice, you can either make a type
that implements `ServeHTTP(...)` or use `http.HandlerFunc` to make a
function into a handler. For us, with views and renderables, this is
a bit too low level. We want:

- Something that can produce views based on a request.
- Something that will allow us to do redirects and 404s.
- To integrate well with standard http handlers and middleware.
- To have short meaningful routes.
- To maintain flexibility and composability.
- TO NOT build our own router.

### Views are a function of requests and routes

In the simplest case, a view/renderable can be produced by a request.
We keep our the views simple and they don't know anything about
where their inputs come from.


```go
import "net/http"

type MyViewFromRequest(r *http.Request) (MyView, error) {
    return MyView{}, nil
}
```

This is a good start and we can have a handler that works with
this.

Keep `panic` everywhere for error handling because we don't really
know what else to do :(

```go
http.Handle("/some_route", func(w http.ResponseWriter, r *http.Request) {
    view, err := MyViewFromRequest(r)
    if err != nil {
        panic(err)
    }

    html, err := Render(r.Context(), view)
    if err != nil {
        panic(err)
    }

    _, err = w.Write([]byte(html))
    if err != nil {
        panic(err)
    }
})
```

Squinting, the only thing that is specific to that route (that isn't part of
the rendering behavior) is `MyViewFromRequest`.

And we can extract it into an interface and function type that can
produce either a view or error out.

```go
type RequestRenderable interface {
    RequestRenderable(r *http.Request) (AsRenderable, error)
}

type RequestRenderableFunc func(*http.Request) (AsRenderable, error)

func (f RequestRenderableFunc) RequestRenderable(r *http.Request) (AsRenderable, error) {
    return f(r)
}
```

We still need a handler that can do something with this...

```go
type HTTPHandler struct {
    r RequestRenderable
}

func (h HTTPHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
    view, err := h.r.RequestRenderable(r)
    if err != nil {
        panic(err)
    }

    html, err := Render(r.Context(), view)
    if err != nil {
        panic(err)
    }

    _, err = w.Write([]byte(html))
    if err != nil {
        panic(err)
    }
}
```

And our route definition can look more like this:

```go
http.Handle("/some_route", HTTPHandler{RequestRenderableFunc(MyViewFromRequest)}
```

**TODO** First patch/snippet here would be great.

[part-1]: /writes/building-view-trees-in-go-part-1
[part-2]: /writes/building-view-trees-in-go-part-2
[part-3]: /writes/building-view-trees-in-go-part-3
[part-4]: /writes/building-view-trees-in-go-part-4
[http-handler]: https://pkg.go.dev/net/http#Handler
