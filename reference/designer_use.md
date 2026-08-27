# Start a docdesigner document

Creates a small starter R Markdown file. Package defaults already know
where the bundled template, fonts, and CSL live, so project-local copies
are only needed for users who want to edit those assets.

## Usage

``` r
designer_use(
  path = ".",
  template = c("pdf", "html", "snapshot"),
  file = NULL,
  overwrite = FALSE,
  local_assets = FALSE
)
```

## Arguments

- path:

  Destination directory. Defaults to current working directory.

- template:

  One of `"pdf"`, `"html"`, or `"snapshot"`.

- file:

  Optional output filename. Defaults to `<template>.Rmd`.

- overwrite:

  If `TRUE`, replace an existing starter file.

- local_assets:

  If `TRUE`, also copy the template, fonts, and CSL file into the
  destination directory for local editing.

## Value

Invisibly returns the starter path.
