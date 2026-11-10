# docdesigner style specification

This file used to hold a hand-written token reference. It drifted from
the engine (nested keys, raw lengths, wrong implementation status) and
has been retired so that it cannot mislead.

- **How to write a style, and what makes a good one:** the *Creating a
  style* article, `vignettes/creating-styles.Rmd`, published at
  <https://jncohen.github.io/docdesigner/articles/creating-styles.html>.
  Its token reference is generated from the schema each time the site is
  built.
- **The vocabulary itself:** `inst/engine/schema.yml`, the single source
  of truth, or
  [`docdesigner::designer_tokens()`](https://jncohen.github.io/docdesigner/reference/designer_tokens.md)
  in R.
- **Checking a style:**
  `docdesigner::designer_validate_style("path/to/style")`.
