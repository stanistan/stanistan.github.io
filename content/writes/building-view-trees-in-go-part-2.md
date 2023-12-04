+++
title = "Building view-trees: The basics [Part 2]"
date = 2023-12-04
+++

We laid our goals in the [part 1][part-1].

---

# Let's make something renderable

```go
import "html/template"

type RenderFunc func(r Renderable) (template.HTML, error)

type Renderable interface {
    Template() (*template.Template, error)
    TemplateData() (any, error)
}
```

Let's start with interfaces and type definitions of the concepts:

1. We want to be able to `Render` a `Renderable` struct into HTML,
   this can fail.
2. We also want the Renderable thing to give us all of the information
   it needs so we can render it. This can also fail.

This interface is small, let's see how far we can push this.

## First Implementation

```go
func Render(r Renderable) (template.HTML, error) {
    var empty template.HTML

    tpl, err := r.Template()
    if err != nil {
        return empty, err
    }

    data, err := r.TemplateData()
    if err != nil {
        return empty, err
    }

    var bs bytes.Buffer
    if err := tpl.Execute(&bs, data); err != nil {
        return empty, err
    }

    return template.HTML(bs.String()), nil
}
```

The implementation is small, too, but what good are components
if you can't compose them.

### Patches

{{ veun_diff(summary="Initial implementation", patch=1) }}

{{ veun_diff(summary="Testing rendering Person()", patch=2) }}


# Trees and Subviews

In order to bring the component into our tree composition view library,
we need to have `Renderable` objects have subtrees.

```go
_, _ := Render(ContainerView{
    Heading: ChildView1{},
    Body:    ChildView2{},
})
```

```mustache
<div>
    <div class="heading">{{ slot "heading" }}</div>
    <div class="body">{{ slot "body" }}</div>
</div>
```

## The POC

The basic idea is to leverage `template.FuncMap` to create a
`slot` function.

```go
func (v ContainerView) Template() (*template.Template, error) {
    return template.New("containerView").Funcs(template.FuncMap{
        "slot": func(name string) (template.HTML, error) {
            switch name {
            case "heading":
                return Render(v.Heading)
            case "body":
                return Render(v.Body)
            default:
                return template.HTML(""), nil
            }
        },
    }).Parse(`<div>
    <div class="heading">{{ slot "heading" }}</div>
    <div class="body">{{ slot "body" }}</div>
</div>`)
}
```

{{ veun_diff(summary="POC implementation and tests", patch=3) }}


### Alternate approach

Alternatively, we can directly inline the fields in the data so our template
looks more like this:

```mustache
<div class="heading">{{ render .Slots.Heading }}</div>
```

## Template compilation

*Refactor 1*: Making it so that we can do pre-compilation of the template,
we can pre-parse it. The immediate issue is that we don't have slots,
and the slot func is necessary to compile the tempalte. We can stub that out:

```go
func slotFuncStub(name string) (template.HTML, error) {
    return template.HTML(""), nil
}

func mustParseTemplate(name, contents string) *template.Template {
    return template.Must(
        template.New(name).
        Funcs(template.FuncMap{"slot": slotFuncStub}).
        Parse(contents),
    )
}

var containerViewTpl = mustParseTemplate("containerView", `<div>
    <div class="heading">{{ slot "heading" }}</div>
    <div class="body">{{ slot "body" }}</div>
</div>`)
```

And then update our `Template()` function:

```go
containerViewTpl.Funcs(template.FuncMap{
    "slot": func(name string) (template.HTML, error) {
        switch name {
        case "heading":
            return Render(v.Heading)
        case "body":
            return Render(v.Body)
        default:
            return template.HTML(""), nil
        }
    },
})
```

{{ veun_diff(summary="implementing this refactor", patch=4) }}

*Refactor 2:* We can clean up the real slot function so that it
is less brittle when views/slots are added and removed.

```go
func tplWithRealSlotFunc(
    tpl *template.Template,
    slots map[string]Renderable,
) *template.Template {
    return tpl.Funcs(template.FuncMap{
        "slot": func(name string) (template.HTML, error) {
            slot, ok := slots[name]
            if ok {
                return Render(slot)
            }
            return template.HTML(""), nil
        },
    })
}

// ... snip ...

return tplWithRealSlotFunc(containerViewTpl, map[string]Renderable{
    "heading": v.Heading,
    "body":    v.Body,
}), nil
```

At this point we've extracted common implementation details but have
kept our main interface the same, which is cool! Our base renderer
doesn't need to know much about anything else, doesn't need to know
about slots, or funcs, or where templates come from.

{{ veun_diff(summary="Patch implementing this slot refactor", patch=5) }}

## A `View{}`

This is generally all well and good, we might want to have
something produce a `Renderable` struct, in fact we might have a
struct that is represents a `Renderable` object, what if we could
capture the above pattern in a piece of data as well as behavior?

```go
type View struct {
    Tpl   *template.Template
    Slots map[string]Renderable
    Data  any
}

func (v View) Template() (*template.Template, error) {
    return tplWithRealSlotFunc(v.Tpl, v.Slots), nil
}

func (v View) TemplateData() (any, error) {
    return v.Data, nil
}
```

The container becomes representable in a different way and it
would have the equivalent outcome when rendered.

{{ veun_diff(summary="view.go implementation (and tests)", patch=6) }}

```go
View{
  Tpl: containerViewTpl,
  Slots: map[string]Renderable{
    "heading": ChildView1{},
    "body":    ChildView2{},
  }
}
```

But we still might want to have ContainerView be the thing we can
"render", how would we do both?

```go
type AsRenderable interface {
    func Renderable() (Renderable, error)
}

type Slots map[string]AsRenderable
```

And updating the `Render` function for the first time to take
`AsRenderable` instead gives us our first really big interface
change, but it unlocks something, too. A simpler way to build views:

```go
func (v ContainerView) Renderable() (Renderable, error) {
    return View{
        Tpl:   containerViewTpl,
        Slots: Slots{"heading": v.Heading, "body": v.Body},
    ), nil
}
```

{{ veun_diff(summary="AsRenderable implementation (and tests)", patch=7) }}

[part-1]: /writes/building-view-trees-in-go-part-1
