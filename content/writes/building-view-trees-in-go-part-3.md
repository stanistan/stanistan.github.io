+++
title = "Building view-trees: Error Handling [Part 3]"
date = 2023-12-05
+++

Previously: [intro][part-1], and [the basics][part-2].

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
  - Do we have something to render?
    - Try to do so!

_Note:_ It is definitely the case here that if our error
handler fails to render and it is `ErrorRenderable` as well
we'll keep trying.

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

{{ veun_diff(patch=9) }}

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

This starts to show the kind of thing we can do with composition and this
libary.

```go
func logWarningErrorHandler(err error) (AsRenderable, error) {
    log.Printf("something failed, but it's ok: %s", err)
    return nil, nil // we don't care for this example
}

html, err := Render(FallibleView{
    Contents:     someViewThatMightFailToRender,
    ErrorHandler: logWarningErrorHandler,
})
```

Or more realistically a situation where you're not sure what
you are rendering in some slot.

```go
func (v Container) Renderable() (Renderable, error) {
    return View{
        // ... snip ...
        Slots: Slots{
            "extra_content": FallibleView{
                Contents:     v.ContentFactory(),
                ErrorHandler: logWarningErrorHandler,
            },
        },
    }, nil
}
```

You can see this in action in the tests in the patch above where
we use `errors.Is(err, somethingKnown)` to do error bubbling or
handling.

Error handling is going to be much more important when we get
to doing _real things_ like data access.

---

### Next:

- [Async data fetching][part-4]
- [http.Handler][part-5]
- [Updating the base interface][part-6]
- [What's up with Renderables][part-7]


[part-1]: /writes/building-view-trees-in-go-part-1
[part-2]: /writes/building-view-trees-in-go-part-2
[part-4]: /writes/building-view-trees-in-go-part-4
[part-5]: /writes/building-view-trees-in-go-part-5
[part-6]: /writes/building-view-trees-in-go-part-6
[part-7]: /writes/building-view-trees-in-go-part-7
