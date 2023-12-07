+++
title = "Building view-trees: http.Handler [Part 5]"
date = 2023-12-08

extra.toc = true
+++

Previously: [intro][part-1], [the basics][part-2], [error handling][part-3],
and [async data fetching][part-4].

---

## An Aside: Small Improvements

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

{{ veun_diff(patch=19) }}

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

{{ veun_diff(patch=20) }}

And our route definition can look more like this:

```go
mux := http.NewServeMux()

mux.Handle("/empty", HTTPHandler{
    RequestRenderableFunc(func(r *http.Request) (AsRenderable, error) {
        return nil, nil
    }),
})
```

### Testing

Of course we can write an HTTP server using the standard library, *but* Go also
provides `net/http/httptest`, where we can start a server and make requests
to it as if it were remote from our tests.

```go
srv := httptest.NewServer(mux)
// and we can make requests to srv.URL
```

{{ veun_diff(patch=21) }}

Our example above ended up unearthing a bug where that was not safe to do,
but it should be-- in our error handlers and the slot we allow for a view
to be `nil`.

{{ veun_diff(patch=22) }}

### More Funcs

We can add convenience constructors to the `HTTPHandler{RequestRenderable...}`
pattern, and this becomes a bit nicer to deal with.

```go
var empty = RequestRenderableFunc(
    func(r *http.Request) (AsRenderable, error) {
        return nil, nil
    },
)

mux.Handle("/empty", HTTPHandler{empty})
```

{{ veun_diff(patch=23) }}

## Composing RequestRenderables

I'm a big fan of interfaces that work well together and are self-consistent,
views/renderables compose well together -- this is how we get render trees, that
continue to maintain the same abstraction.

Turns out we have a very similar pattern available to us with `RequestRenderable`
types as well.

### Why

In a real world web application, you are going to end up up with standard a container
view at the top level signifying the `<html>...` and whatever application and page chrome
you need.

```go
var htmlTpl = MustParseTemplate("html", `<html><body>{{ slot "body" }}</body></html>`)

type html struct {
    Body  AsRenderable
}

func (v html) Renderable(_ context.Context) (Renderable, error) {
    return View{Tpl: htmlTpl, Slots: Slots{"body": v.Body}}, nil
}
```

Having each `RequestRenderable` be aware of which wrapper view is needed might be
annoying, and ends up making our functions less re-usable across different contexts.

But we can re-use the interface (again, similar to the middleware pattern).

```go
func HTML(renderable RequestRenderable) RequestRenderable {
    return RequestRenderableFunc(func(r *http.Request) (AsRenderable, error) {
        v, err := renderable.RequestRenderable(r)
        if err != nil {
            return nil, err
        }

        return html{Body: v}, nil
    })
}
```

Or more clearly:

```go
func HTML(renderable RequestRenderable) http.Handler {
    return RequestHandlerFunc( /* ... */ )
}
```

So we can:

```go
mux.handle("/html/empty", HTML(empty))
```

{{ veun_diff(patch=24) }}


## Fixing the abstraction

While this is _nice_, we've lost some functionality, and no longer have answers
to the questions:

- How will we redirect?
- What if we want to 404?
- What if we want to send back http response headers?
- What is our error handling strategy?

And real applications _need answers_ to these questions.

The current implementation will either fail (with panics, for now), or render a `200`.

I've played around with having this return an `Response` struct or something
like that, which would create different levels of composition with usage that
is something like this:

**Standard response, `200` with rendered view:**

```go
return Response(view), nil
```

**Rendered view with custom status code:**

```go
return Response(view, StatusCode(404)), nil
```

**An empty 404**

```go
return NotFoundResponse()
```

**Redirects**

```go
return RedirectResponse(301, toLocation)
```

If you squint above, the handler will actually be returning
something that implements an `http.Handler` and this is really powerful.

The problem with the approach is we lose the composability we need.

### http.Handler

Let's add _one more return variable_ to our `RequestRenderable`.

```go
type RequestRenderable interface {
    RequestRenderable(*http.Request) (AsRenderable, http.Handler, error)
}
```

To go back through our examples above usage would be:


**Standard response, `200` with rendered view:**

```go
return view, nil, nil
```

**Rendered view with custom status code:**

```go
return view, StatusCode(404), nil
```

**An empty 404:**

```go
return nil, http.NotFoundHandler(), nil
```

**Redirects:**

```go
return nil, http.RedirectHandler(toLocation, 301), nil
```

**Custom Response Headers:**

```go
return view, ResponseHeader(...), nil
```

This means we have the optionality of adding http handlers to our response
but _also_ have the types and flexibility to do view composition
in our request handers.

{{ veun_diff(patch=25) }}

{{ veun_diff(patch=26) }}

### Error Handling

We always come back to error handling, our implementation currently
has three places where we `panic`.

1. `RequestRenderable()` returns an error
2. `Render()` returns an error
3. `Write` fails

Our library already has hooks two of these to fail...

1. RequestRenderable composition can fully handle (1) and (2).
2. We can't really do anything else here-- maybe the connection went away,
   and we let it fail.


Let's make a really silly error view...

```go
var errorViewTpl = MustParseTemplate("errorView", `Error: {{ . }}`)

type errorView struct {
    Error error
}

func (v errorView) Renderable(_ context.Context) (Renderable, error) {
    return View{Tpl: errorViewTpl, Data: v.Error}, nil
}

func newErrorView(_ context.Context, err error) (AsRenderable, error) {
    return errorView{Error: err}, nil
}
```

And leverage our `ErrorRenderable` interface to do some composition.

```go
func WithErrorHandler(eh ErrorRenderable) func(RequestRenderable) RequestRenderable {
    return func(renderable RequestRenderable) RequestRenderable {
        return RequestRenderableFunc(func(r *http.Request) (AsRenderable, http.Handler, error) {
            v, next, err := renderable.RequestRenderable(r)
            if err != nil {
                v, err = eh.ErrorRenderable(r.Context(), err)
                return v, nil, err
            }

            html, err := Render(r.Context(), v)
            if err != nil {
                v, err = eh.ErrorRenderable(r.Context(), err)
                return v, nil, err
            }

            if len(html) == 0 {
                return nil, next, nil
            }

            return nil, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
                if next != nil {
                    next.ServeHTTP(w, r)
                }

                _, _ = w.Write([]byte(html))
            }), nil
        })
    }
}
```

This is cool and all, but it's _basically_ the same thing as our `HTTPHandler`, but
with an ErrorRenderable provided. So I don't like it.

So maybe let's make that part of a base handler, and also include a default error
handler instead.

First, let's make `HTTPHandler` a function instead of a struct, this eliminates the
need for `RequestHandlerFunc`.

{{ veun_diff(patch=27) }}

### Adding the error delegate option

Let's add the field to our (now private) `handler`, and make it something that
we can add to the `HTTPHandler`. In this case, I prefer to have them be optional
configurations, meaning we should be adding them as so:

```go
type HandlerOption func(h *handler)

func HTTPHandler(r RequestRenderable, opts ...HandlerOption) http.Handler { /* ... */ }

type handler struct {
    Renderable   RequestRenderable
    ErrorHandler ErrorRenderable    // <- this is new
}
```

And we can replace the `panic` calls with `handleError(ctx, err, ResponseWriter)`
which will either do error degation-- using our `handleRenderError`, or
write out at `500 Internal Server Error`.


{{ veun_diff(patch=28) }}

## Putting it together

From the tests in the patches, we can see that making a handler is now pretty
simple, by building up the few pieces we've put together, we have a pretty
robust little library.

```go
import (
    "net/http"

    . "github.com/stanistan/veun"
)

type myServer struct {
    // some db contections and contexts
}

func (s *myServer) SomePageHandler(r *http.Request) (AsRenderable, http.Handler, error) {
    // Stuff...
}

func main() {
    http.Handle("/some-page", HTML(s.SomePageHandler))
}
```

This is compatible with middleware, any router that works with `http.Handler`
functions, and can do response headers, redirects, custom error pages,
and cancellation/deadlines.


[part-1]: /writes/building-view-trees-in-go-part-1
[part-2]: /writes/building-view-trees-in-go-part-2
[part-3]: /writes/building-view-trees-in-go-part-3
[part-4]: /writes/building-view-trees-in-go-part-4
[http-handler]: https://pkg.go.dev/net/http#Handler
