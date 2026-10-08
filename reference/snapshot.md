# Render an official Snapshot

Snapshot is a fixed official PDF layout. It can also write a plain HTML
companion for web publishing.

## Usage

``` r
snapshot(
  ...,
  html = TRUE,
  template = dd_template(),
  latex_engine = "xelatex",
  html_file = NULL,
  html_assets = TRUE,
  html_checklist = TRUE
)
```

## Arguments

- ...:

  Arguments passed to
  [`rmarkdown::pdf_document()`](https://pkgs.rstudio.com/rmarkdown/reference/pdf_document.html).

- html:

  If `TRUE`, write a plain HTML companion file.

- template:

  LaTeX template path. Defaults to the bundled template.

- latex_engine:

  LaTeX engine for the PDF. Defaults to `xelatex`.

- html_file:

  Optional companion HTML filename.

- html_assets:

  If `TRUE`, copy local images referenced by the HTML file.

- html_checklist:

  If `TRUE`, write a short publishing checklist.

## Value

An R Markdown output format.
