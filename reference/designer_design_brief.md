# The design constraint brief

Generates a Markdown document that states docdesigner's token vocabulary
as hard design constraints: the colour roles, the bundled fonts, the
named scale steps (space, rule weight, margin, width), the bounded type
scale, and the five `title.layout` archetypes. Give this to whoever
designs a new style, before they start, so the result is something
[`designer_import_html()`](https://jncohen.github.io/docdesigner/reference/designer_import_html.md)
can actually translate rather than a design that merely resembles one.

## Usage

``` r
designer_design_brief(path = NULL)
```

## Arguments

- path:

  If given, write the brief to this file. Otherwise return it as a
  character vector of lines.

## Value

Character vector of Markdown lines, invisibly if `path` is given.

## Details

This is generated from `inst/engine/schema.yml`, not hand-maintained, so
it cannot drift from what the engine actually accepts the way a
hand-written brief would as the schema evolves.
