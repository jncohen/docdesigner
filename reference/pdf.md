# Designed PDF output format

Designed PDF output format

## Usage

``` r
pdf(
  ...,
  style = "minimal",
  doublespace = FALSE,
  title_layout = NULL,
  markup = NULL,
  version = NULL,
  changes_since = NULL
)
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

- title_layout:

  `"header"` (title block at the top of the first page), `"page"` (title
  and abstract on a page of their own) or `"thesis"` (a thesis title
  page and front matter). `NULL`, the default, uses the style's
  `title.layout` token.

- markup:

  A named list overriding the style's `markup.*` tokens for this render,
  e.g. `list(line_numbers = 0)` to drop line numbers from one printout.
  See
  [`designer_tokens()`](https://jncohen.github.io/docdesigner/reference/designer_tokens.md)
  for the keys.

- version:

  The version printed by the `stamp` running-head slot and by
  `warning: auto`. `NULL` (default): the git short hash of the
  document's last commit, with `+` when it has uncommitted changes, when
  the style prints a stamp. A string: printed as is. `FALSE`: none.

- changes_since:

  For `markup.changebars`: the version to mark changes against. A git
  tag, branch or commit, or a path to an earlier copy of the source.
  `NULL` (default): the latest git tag.

## Value

An R Markdown output format.
