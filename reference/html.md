# Render plain HTML for web publishing

Produces body-only HTML suitable for copying into a CMS such as
WordPress. It does not try to reproduce the PDF layout.

## Usage

``` r
html(..., assets = TRUE, checklist = TRUE, body_only = TRUE)
```

## Arguments

- ...:

  Arguments passed to
  [`rmarkdown::html_document()`](https://pkgs.rstudio.com/rmarkdown/reference/html_document.html).

- assets:

  If `TRUE`, copy local image assets beside the HTML file and rewrite
  local image paths.

- checklist:

  If `TRUE`, write a short publishing checklist.

- body_only:

  If `TRUE`, keep only the HTML body content.

## Value

An R Markdown output format.
