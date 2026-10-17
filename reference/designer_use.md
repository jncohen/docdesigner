# Start a docdesigner document

Creates a small starter R Markdown file. Package defaults already know
where the bundled fonts, CSL and style sets live, so project-local
copies are only needed for users who want to edit those assets.

## Usage

``` r
designer_use(
  path = ".",
  template = c("pdf", "html"),
  file = NULL,
  overwrite = FALSE,
  local_assets = FALSE
)
```

## Arguments

- path:

  Destination directory. Defaults to current working directory.

- template:

  One of `"pdf"` or `"html"`.

- file:

  Optional output filename. Defaults to `<template>.Rmd`.

- overwrite:

  If `TRUE`, replace an existing starter file.

- local_assets:

  If `TRUE`, also copy the fonts, CSL file and style sets into the
  destination directory for local editing.

## Value

Invisibly returns the starter path.
