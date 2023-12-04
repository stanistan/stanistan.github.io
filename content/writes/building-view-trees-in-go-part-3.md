+++
title = "Building view-trees: Error Handling [Part 3]"
date = 2023-12-05
+++

Previously: [intro][intro], and [the basics][the-basics].

---

## Handling errors, `err != nil`

Above we have a bunch of assumptions about what things can fail
and which ones cannot. And any error should bubble all of the
way out of the render pipeline. Template rendering will fail
when rendering one of the slots fails. Any template parsing
can/will bubble up as well, any data fetching, anything that
happens during the `Renderable` call.

There are a few ways we can build and execute Render. The views
either populate data top down, or they fetch data lazilly,
they can do validation, they can not, each of these can fail.

### Marker interfaces (duck typing yo)

Something that can eventually be rendered, something that is `AsRenderable`
should also be able to handle its own error failure, or handle
a failure lower down in the tree.

Handling errors will introduce another refactor to
our renderer, but will keep our UX/API *small* and opt-in.

```go
type ErrorRenderable interface {
    // ErrorRenderable can return bubble the error
    // back up, which will continue to fail the render
    // the same as it did before.
    //
    // It can also return nil for Renderable,
    // which will ignore the error entirely.
    //
    // Otherwise we will attempt to render next one.
    ErrorRenderable(err error) (AsRenderable, error)
}

func handleRenderError(err error, with any) (template.HTML, error) {
    var empty template.HTML

    if with == nil {
        return empty, err
    }

    errRenderable, ok := with.(ErrorRenderable)
    if !ok {
        return empty, err
    }

    // we can delegate error handling here, if err is
    // returned we propagate up.
    r, err := errRenderable.ErrorRenderable(err)
    if err != nil {
        return empty, err
    }

    // if we ignore the error, we can move it along.
    if r == nil {
        return empty, nil
    }

    return Render(r)
}
```

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
