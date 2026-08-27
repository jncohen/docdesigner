# Scaffold a new style

Writes a commented `format.yml` starter, seeded from an existing style
so you change only what differs.

## Usage

``` r
designer_new_style(id, from = "minimal", path = ".", complete = TRUE)
```

## Arguments

- id:

  New style id.

- from:

  Existing style to copy tokens from.

- path:

  Destination directory (a style bundle folder is created inside).

- complete:

  If `TRUE` (default), scaffold every token in the schema, one flat
  dotted key per line, as an editable reference. If `FALSE`, seed only
  the tokens the source style actually declares.

## Value

The new style directory, invisibly.
