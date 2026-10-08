# Designed PDF output format

Designed PDF output format

## Usage

``` r
pdf(..., style = "minimal", doublespace = FALSE)
```

## Arguments

- ...:

  Passed to
  [`rmarkdown::pdf_document()`](https://pkgs.rstudio.com/rmarkdown/reference/pdf_document.html).

- style:

  A style from
  [`designer_styles()`](https://jncohen.github.io/docdesigner/reference/designer_styles.md)
  or a style directory path.

- doublespace:

  If `TRUE`, double-space the body text, as for a manuscript under
  review. Titles, headings, tables, captions, footnotes and code stay
  single-spaced. Overrides the style's `typography.line_height` for body
  text only.

## Value

An R Markdown output format.
