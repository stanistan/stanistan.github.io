+++
title = "Building view-trees: Error Handling [Part 3]"
date = 2023-12-05
+++

Previously: [intro][intro], and [the basics][the-basics].

---

We have a bunch of assumptions about what things can fail
and which ones cannot.

Right now, any error will bubble all of the way out of the render
pipeline, and template rendering will fail. If a slot render fails,
the same thing will happen. Any template parsing can/will bubble up
as well, any data fetching, anything that happens during the
`Renderable` call.

There are a few ways we can build and execute Render. The views
either populate data top down, or they fetch data lazilly,
they can do validation, they can not, each of these can fail.

## Handling errors, `err != nil`

Something that can eventually be rendered, something that is `AsRenderable`
should also be able to handle its own error failure, or handle
a failure lower down in the tree.

Handling errors will introduce another refactor to
our renderer, but will keep our UX/API *small* and opt-in.

### Marker interfaces (duck typing yo)

```go
type ErrorRenderable interface {
    ErrorRenderable(err error) (AsRenderable, error)
}
```

And our logic to handle the error is pretty simple:

- Check to see if we actually have an error handler
  - If we don't we bubble up the error.
- Check to see if the erro handler wants to handle
  the error itself.
  - Returning an error means we want to buble it up.
  - Returning `nil` for the `AsRenderable` means we
    don't care about this error at all. OK to move on.
- Try to render the thing.


```go
func handleRenderError(err error, with any) (template.HTML, error) {
    var empty template.HTML

    if with == nil {
        return empty, err
    }

    errRenderable, ok := with.(ErrorRenderable)
    if !ok {
        return empty, err
    }

    r, err := errRenderable.ErrorRenderable(err)
    if err != nil {
        return empty, err
    }

    if r == nil {
        return empty, nil
    }

    return Render(r)
}
```

_Note:_ It is definitely the case here that if our error
handler fails to render and it is `ErrorRenderable` as well
we'll keep trying.

### Fallible Views!

With this in hand, and a quick change to the `Render` function to
call this instead of returning an error, we get some neat behavior,
and an example of composition based _delegation_.

```go
type FallibleView struct {
    Contents     AsRenderable
    ErrorHandler func(err error) (AsRenderable, error)
}

func (v FallibleView) Renderable() (Renderable, error) {
    return v.Contents.Renderable()
}

func (v FallibleView) ErrorRenderable(err error) (AsRenderable, error) {
    return v.ErrorHandler(err)
}
```


[intro]: /writes/building-view-trees-in-go-part-1
[the-basics]: /writes/building-view-trees-in-go-part-2
