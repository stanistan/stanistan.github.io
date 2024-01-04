+++
title = "Building view-trees: Intro [Part 1]"
date = 2023-12-01
+++

When I was at Etsy, we built a server-side component library called
View Trees, but also called `neu` (because this was quicker to type).

This is referenced in this [Code As Craft][cac] blog post, which is about
extending/updating the framework to output server-rendered JSX components.

After futzing around with [Vue][vue] in present-me, and then reading more about
similar-to-neu approaches for doing client-side interaction (like [htmx][htmx],
and others) based on server side rendering I wanted to revisit this library,
but from a Go perspective.

---

This is going to be a series of posts describing an iterative approach to
building this out, aming to explain why things look and the way they do through
specific problems and solutions to them.

**Things to keep in mind**

- In Go, we have built-in templates with the [`html/template`][1]
  package, and a standard way of compiling and rendering templates.
  We're not introducing a new templating language. And want to leverage
  the way folks already write their templates, but give them different
  ways to compose them (not inclusion, not inheritence).
- There are standard HTTP handlers in the `net/http` package, try
  to integrate with that using middleware (and other standard patterns)
  and not introduce any http routing or anything else.
- We want to make the interfaces small, and the composition simple and obvious.
- Errors are recoverable!

## How does go do templates?

The idiomatic way to render HTML templates is to write some data
to a buffer via `tpl.Execute`:

```go
import "html/template"

contents := `<div>Hi, {{ .Name }}</div>`
tpl := template.Must(template.New("hi").Parse(contents))

var bs bytes.Buffer
err := tpl.Execute(&bs, map[string]string{"Name": "Stan"})
```

The above snippet is an extremely simplified version of what you would
do. Idiomatically, one would expect template compilation from external
files that are embedded into your binary and compiled and a named type
for the template data, error handling, and maybe writing to
an `http.ResponseWriter`.

# Where are we going?

```go
html, err := Render(PersonView(Person{Name: "Stan"}))
```

Conceptually, what we have is piece of data, let's say a `Person` struct,
and an html view of that that knows how to take that data and render
it into HTML. We can, of course, just make a function that does this
for the use case above.

But what we want is something like this:

- A `Render` function that render's a view.
- A view that is parameterized by a struct.
- Outputting valid HTML.

The larger semantic difference is we are lifting the way we desribe
our data inputs and views into being first-class "objects" (structs
that can possibly have behaviors and guarantees) so we can leverage
the language to do composition, parameterization, polymorphism,
etc... so we can do things like components :)

---

### Next:

- [The basics][part-2]
- [Error handling][part-3]
- [Async data fetching][part-4]
- [http.Handler][part-5]
- [Updating the base interface][part-6]
- [What's up with Renderables][part-7]


[cac]: https://www.etsy.com/codeascraft/mobius-adopting-jsx-while-prioritizing-user-experience
[1]: https://pkg.go.dev/html/template
[htmx]: https://htmx.org/
[vue]: https://vuejs.org/
[part-2]: /writes/building-view-trees-in-go-part-2
[part-3]: /writes/building-view-trees-in-go-part-3
[part-4]: /writes/building-view-trees-in-go-part-4
[part-5]: /writes/building-view-trees-in-go-part-5
[part-6]: /writes/building-view-trees-in-go-part-6
[part-7]: /writes/building-view-trees-in-go-part-7
