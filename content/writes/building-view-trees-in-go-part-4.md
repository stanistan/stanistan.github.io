+++
title = "Building view-trees: Async Data Fetching [Part 4]"
date = 2023-12-06
+++

Previously: [intro][part-1], [the basics][part-2], and [error handling][part-3].

---

There are cases where we'll fetch data for something up front, and pass
it down the view tree, meaning the views are basically "pure functions",
all done; and there are times when a view will request data for itself,
meaning a view constructor could be waiting and blocking.

The below example is of a view constructor kicking off a simulated fetch
in a goroutine, based on how its configured the view either fails or
succeeds.

`ExpensiveViewData` is a placeholder for something that could
have come from some JSON API.

```go
type ExpensiveViewData struct {
    Title string `json:"title"`
}
```

The view holds data for success or error and `Renderable` checks for
which channel gets data first (this will block), either getting data,
or an error, and then completing the `Renderable` interface with which
ever.

```go
type ExpensiveView struct {
    Data chan ExpensiveViewData
    Err  chan error
}

func (v *ExpensiveView) Renderable() (Renderable, error) {
    select {
    case err := <-v.Err:
        return nil, err
    case data := <-v.Data:
        return View{/*  */}, nil
    }
}
```

The constructor (function) for our view, because we're simulating
work, is parameterized by `shouldErr`  and we kick off a goroutine
that waits for 1 second and then sends the message.

```go
func NewExpensiveView(shouldErr bool) *ExpensiveView {
    errCh := make(chan err)
    dataCh := make(chan ExpensiveViewData)

    go func() {
        defer close(errCh)
        defer close(dataCh)

        // do data fetching and either write to one thing or the other
        time.Sleep(1 * time.Second)
        if shouldErr {
            errCh <- fmt.Errorf("fetch failed")
        } else {
            dataCh <- ExpensiveViewData{Title: "hi"}
        }
    }()

    return &ExpensiveView{Data: dataCh, Err:  errCh}
}
```

{{ veun_diff(patch=10) }}

This works just fine, but what if we don't want this to be waiting for a second,
what if we have 10ms to do the work?

## Context and Cancellation

We need something that could do cancellation in case of a timeout.
We're missing [`context.Context`][context-docs].

Where this is mostly going to be used, in the span of an HTTP request,
we can grab this from the request itself, but our API has no method of
propagating it down through construction, render, and data fetching.

What we want is for our `select` to look like this:

```go
select {
case <-ctx.Done():
    return nil, ctx.Err()
case err := <-v.Err:
    return nil, err
case data := <-v.Data:
    return View{/*  */}, nil
}
```

And eventually, our API to look like this:

```go
func (v *ExpensiveView) Renderable(ctx context.Context) (Renderable, error) {
    // ...
}
```

So we have some changes to make.

| Before                  | After                           |
|-------------------------|---------------------------------|
| `Renderable()`          | `Renderable(Context)`           |
| `Template()`            | `Template(Context)`             |
| `TemplateData()`        | `TemplateData(Context)`         |
| `Render(AsRenderable)`  | `Render(Context, AsRenderable)` |

{{ veun_diff(patch=11) }}

{{ veun_diff(patch=12) }}

## Fallible and WithTimeout

Because we can do call delegation in our views and render, we can
force a situation where a subtree always stops rendering by
creating a view which explicitly cancels a subcontext and passes
it to the its subview.

```go
type ViewWithTimeout struct {
    Delegate AsRenderable
    Timeout time.Duration
}

func (v ViewWithTimeout) Renderable(ctx context.Context) (Renderable, error) {
    ctx, _ = context.WithTimeout(ctx, v.Timeout)
    return v.Delegate.Renderable(ctx)
}
```

And using the `FallibleView` from part-2 we can make sure that something
fetches and renders within a given time frame.

```go
view := FallibleView{
    Contents: ViewWithTimeout{
        Delegate: expensiveView(),
        Timeout: 100 * time.Millisecond,
    },
    ErrorRenderable: func(_ context.Context, err error) (AsRenderable, error) {
        return View{/* */}, nil
    },
}
```

{{ veun_diff(patch=13) }}

### Cleaning up, and examples of Context composition

We can make our own very similar `WithTimeout` function.

```go
func WithTimeout(r AsRenderable, timeout time.Duration) AsRenderable {
    // ...
}
```

This is just a function signature, but seeing this immediately makes me think
of ways that something can be extracted into a different kind of pattern.

HTTP middleware has the signature: `func(http.Handler) http.Handler`.

We can update our function to look like this:

```go
func WithTimeout(timeout time.Duration) func(AsRenderable) AsRenderable {
    return func(r AsRenderable) AsRenderable {
        // ...
    }
}
```

Is this actually useful? How would this be used in practice?

Probably _not_ by doing: `WithTimeout(timeout)(view)`, but if we had some way
of applying these, like: `Compose(view, WithTimeout(timeout))`, this might be ok.

Let's just save this idea for later...

### A Renderable function

Something that _is_ interesting here though is the part we gloss
over, (`// ...`). Sometimes we don't need a full struct, sometimes
we only need a closure, and the resulting code can be clearer and
simpler to reason about.

```go
type RenderableFunc func(context.Context) (Renderable, error)

func (f RenderableFunc) Renderable(ctx context.Context) (Renderable, error) {
    return f(ctx)
}
```

{{ veun_diff(patch=14) }}

And now to use it:

```go
func WithTimeout(timeout time.Duration) func(AsRenderable) AsRenderable {
    return func(r AsRenderable) AsRenderable {
        return RenderableFunc(func(ctx context.Context) (Renderable, error) {
            ctx, _ = context.WithTimeout(timeout)
            return r.Renderable(ctx)
        })
    }
}
```

_N.B._ Because go contexts are copies, cancelling subtree renders
**MUST BE** done through delegating.

```go
func WithErrorHandler(eh ErrorRenderable) func(AsRenderable) AsRenderable {
    return func(r AsRenderable) AsRenderable {
        return FallibleView{Contents: r, ErrorRenderable: eh}
    }
}
```

## Can we put it together?

```go
func Compose(r AsRenderable, fs ...func(AsRenderable) AsRenderable) AsRenderable {
    for _, f := range fs {
        r = f(r)
    }
    return r
}

r := Compose(r, WithTimeout(timeout), WithErrorHandler(eh))
html, err := Render(ctx, r)
```

Except for writing `AsRenderable` over and over and over again, that's not so bad,
and the usage is nice.

---

### Next:

- [http.Handler][part-5]
- [Updating the base interface][part-6]

[part-1]: /writes/building-view-trees-in-go-part-1
[part-2]: /writes/building-view-trees-in-go-part-2
[part-3]: /writes/building-view-trees-in-go-part-3
[part-5]: /writes/building-view-trees-in-go-part-5
[part-6]: /writes/building-view-trees-in-go-part-6
[context-docs]: https://pkg.go.dev/context
