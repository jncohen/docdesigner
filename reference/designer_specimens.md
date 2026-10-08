# Render a PDF specimen for every installed style

Renders the bundled specimen document once per style, then writes an
HTML index grouped by style set. Styles are rendered independently: one
failure does not stop the rest, and failures are reported rather than
thrown.

## Usage

``` r
designer_specimens(
  styles = NULL,
  output_dir = "rendered-examples/specimens",
  index = TRUE,
  open = interactive(),
  quiet = TRUE
)
```

## Arguments

- styles:

  Character vector of style ids. Defaults to every installed style, as
  reported by
  [`designer_styles()`](https://jncohen.github.io/docdesigner/reference/designer_styles.md).

- output_dir:

  Directory to write specimens and the index into.

- index:

  If `TRUE`, write `index.html` linking every specimen.

- open:

  If `TRUE`, open the index in a browser.

- quiet:

  Passed to
  [`rmarkdown::render()`](https://pkgs.rstudio.com/rmarkdown/reference/render.html).

## Value

A data frame of results, invisibly: one row per style with its status,
output path, render time, and any error digest.

## Details

Requires a working LaTeX installation (`xelatex`) and Pandoc. Run
[`designer_check()`](https://jncohen.github.io/docdesigner/reference/designer_check.md)
first if you are unsure.
