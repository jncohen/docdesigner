# Update local docdesigner assets

Refreshes editable local copies of the LaTeX template, fonts, CSL file,
and style manifests. Most projects do not need local assets; use this
only when a project deliberately keeps editable or frozen copies.

## Usage

``` r
designer_update_templates(
  path = ".",
  source = c("installed", "github"),
  branch = "main",
  overwrite = TRUE
)
```

## Arguments

- path:

  Destination directory.

- source:

  `"installed"` copies assets from the installed package; `"github"`
  downloads assets from the repository.

- branch:

  GitHub branch or tag when `source = "github"`.

- overwrite:

  Whether to replace existing local files.

## Value

Invisibly returns `path`.
