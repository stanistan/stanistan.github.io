+++
title = "Building view-trees: Updating the base interface [Part 6]"
date = 2023-12-13
+++

Previously: [intro][part-1], [the basics][part-2], [error handling][part-3],
[async data fetching][part-4], and [http.Handler][part-5].

---

We have a thing that kind of works and in building out our interfaces and types
we end up with something that is just a bit more complicated than we need, and
a bit too specific, or not specific enough.

Our concepts [include][pkg-dev-1]: Renderables, AsRenderables, Views, ErrorRenderables,
RequestRenderables, RequestHandlers. To be fair this isn't a ton, but it has a smell,
and it's a lot to type.

I have questions like:

- Why do we have both an `AsRenderable` and `Renderable`?
- Why do most of our `Renderable` functions return `View`?
- Are these the same?
- Why do we _always_ need a `template` in order to render something?

Do we need both interfaces and interface factories (which is what we have and that
feels bad)?

## Renderable, but like, to HTML

The `Renderable` interface should probably only be, this gives us the ability
to render strings, or have some async calls that just return html, or something
else.

```go
type Renderable interface {
    RenderToHTML(ctx context.Context) (template.HTML, error)
}

type RenderableFunc func(context.Context) (template.HTML, error)
```

{{ veun_diff(patch=30) }}

Leaving the template bits to be an implementation detail of the
specific _kind_ of Renderable.

```go
type TemplateRenderable struct {
    Template *template.Template
    Data     any
}

func (t TemplateRenderable) RenderToHTML(ctx context.Context) (template.HTML, error) {
    // the content of our `render` function
}
```

Where a `View` can defer to be `TemplateRenderable` but with `Slots`.

### Lists

Removing the need for a template also gives us the ability to concatenate, and
potentially make some views cheaper to construct.

```go
type Views []AsRenderable

func (vs Views) Renderable(_ context.Context) (Renderable, error) { return vs, nil }

func (vs Views) RenderToHTML( /*........
```

### &lt;div /&gt;

Or maybe you wanted to do something like:

```go
func Div(contents AsRenderable) AsRenderable {
    return RenderableFunc(func(ctx context.Context) (template.HTML, error) {
        inner, out := Render(ctx, r)
        if err != nil {
            return inner, err
        }

        return template.HTML("<div>") + inner + template.HTML("</div>"), nil
    })
}
```

But this doesn't really seem that great at all, and feels like we're
leaking our implementation. We have the flexibility to do this, but
we're losing our delcarative composability.

We can:
1. make a `Raw` type that is a string wrapper, and
2. reuse `Views` to elide the inner call to `Render`

```go
type Raw string

func (r Raw) RenderToHTML(_ context.Context) (template.HTML, error) {
    return template.HTML(r), nil
}

func Div(contents AsRenderable) AsRenderable {
    return RenderableFunc(func(_ context.Context) Renderable {
        return Views{
            Raw("<div>"), contents, Raw("</div>"),
        }
    })
}
```

{{ veun_diff(patch=32) }}

And now since we're no longer doing any render call, we
can make it even clearer:

```go
func Div(contents AsRenderable) AsRenderable {
    return Views{
        Raw("<div>"), contents, Raw("</div>"), // NICE :boom:
    }
}
```

{{ veun_diff(patch=31) }}

## Errors

I'm not going to get to revisiting errors here just yet.

---

## Next:

- [What's up with Renderables][part-7]

[part-1]: /writes/building-view-trees-in-go-part-1
[part-2]: /writes/building-view-trees-in-go-part-2
[part-3]: /writes/building-view-trees-in-go-part-3
[part-4]: /writes/building-view-trees-in-go-part-4
[part-5]: /writes/building-view-trees-in-go-part-5
[part-7]: /writes/building-view-trees-in-go-part-7
[pkg-dev-1]: https://pkg.go.dev/github.com/stanistan/veun@v0.0.0-20231218164211-f427fa0ee981
