# Validate a style file against the schema

Reads a flat dotted-key `format.yml` and reports unknown keys, bad
values, and tokens the current engine does not yet implement.
Cross-token rules (declared in `schema.yml` under `rules:`) are reported
as warnings.

## Usage

``` r
designer_validate_style(style)

# S3 method for class 'docdesigner_validation'
print(x, verbose = FALSE, ...)
```

## Arguments

- style:

  A style id, a style directory, or a path to a `format.yml`.

- x:

  A `docdesigner_validation` object from `designer_validate_style()`.

- verbose:

  List every not-yet-implemented token instead of summarising.

- ...:

  Unused; present for S3 `print` compatibility.

## Value

A data frame of issues, invisibly. Printed as a report.
