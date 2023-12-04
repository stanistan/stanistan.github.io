+++
title = "Building view-trees: Async Data Fetching [Part 4]"
date = 2023-12-06
draft = true
+++

Previously: [intro][part-1], [the basics][part-2], and [error handling][part-3].

---

There are cases where you'll fetch data for something up front, and pass
it down the view tree, meaning the views are all done and good, and
there are times when a view will request data for itself, meaning a
view constructor could be synchronous and waiting.

The below example is of a view constructor kicking off a simulated fetch
in a goroutine, based on how its configured the view either fails or
succeeds.

```go
type ExpensiveViewData struct {
    Title string `json:"title"`
}

type ExpensiveView struct {
    Data chan ExpensiveViewData
    Err  chan error
}

func NewExpensiveView(shouldErr bool) *ExpensiveView {
    errCh := make(chan err)
    dataCh := make(chan ExpensiveViewData)

    go func() {
        defer func() {
            close(errCh)
            close(dataCh)
        }()

        // do data fetching and either write to
        // one thing or the other
        time.Sleep(1 * time.Second)
        if shouldErr {
            errCh <- fmt.Errorf("fetch failed")
        } else {
            dataCh <- ExpensiveViewData{Title: "hi"}
        }
    }()

    return &ExpensiveView{Data: dataCh, Err:  errCh}
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

# `context.Context` and Cancellation

We're clearly missing a `context.Context` there, something that could do
cancellation in case of a timeout. In the span of some HTTP request (mostly
where this would be used), we would originally get it from the request itself,
but we have no method of propagating it down through view construction and data
fetching as of yet.

Our `Renderable` and `Tempalate/TemplateData` interface functions should both be
parameterized by a `context.Context`.

Then we can update our `Renderable` to something that is far more robust to
cancellations, timeouts, etc.

```go
func (v *ExpensiveView) Renderable(ctx context.Context) (Renderable, error) {
    select {
    case <-ctx.Done():
        return nil, ctx.Err()
    case err := <-v.Err:
        return nil, err
    case data := <-v.Data:
        return View{/*  */}, nil
    }
}
```

## An interesting example

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

## Passing context down the tree

*Note:* Because go contexts are copies, cancelling subtree renders must be done
through delegating-- we can also introduce a render middleware pattern:

```go
type RenderableDecorator func(AsRenderable) AsRenderable

func WithTimeout(timeout time.Duration) RenderableDecorator {
    return func(r AsRenderable) AsRenderable {
        return RenderableFunc(func(ctx context.Context) (Renderable, error) {
            ctx, _ = context.WithTimeout(timeout)
            return r.Renderable(ctx)
        })
    }
}

// WithRenderAborted is a RenderableDecorator.
func WithRenderAborted(r AsRenderable) AsRenderable {
    return RenderableFunc(func(ctx context.Context) (Renderable, error) {
        ctx, cancel := context.WithCancel()
        cancel()
        return r.Renderable(ctx)
    })
}

func WithErrorHandler(eh ErrorRenderable) RenderableDecorator {
    return func(r AsRenderable) AsRenderable {
        return FallibleView{Contents: r, ErrorRenderable: eh}
    }
}
```
