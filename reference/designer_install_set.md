# Install a style set from GitHub

The canonical library is one repo (default `"jncohen/docdesigner"`)
holding every set under `inst/sets/<set>/`, the same layout the package
ships internally – installing `"academic"` or `"public"` pulls the
current GitHub state of a set that may already be bundled with your
installed package version, which is exactly the point: it lets a set get
updates between package releases. A single-set repo (`set.yml` at the
repo root) still works unchanged, for anyone publishing their own set
outside the canonical library.

## Usage

``` r
designer_install_set(
  set = NULL,
  repo = "jncohen/docdesigner",
  ref = "main",
  overwrite = FALSE
)
```

## Arguments

- set:

  The set to install: a subdirectory name inside `repo` (e.g.
  `"academic"`), or `NULL` if `repo` is a dedicated single-set repo with
  `set.yml` at its root.

- repo:

  A GitHub `owner/name` slug or a full clone URL. Defaults to the
  canonical docdesigner style-set library.

- ref:

  Branch or tag to install.

- overwrite:

  Replace an existing set of the same id.

## Value

The install path, invisibly.

## Details

Resolution order for `set.yml`, first match wins: `<set>/set.yml` (a
subdirectory named for the set), `inst/sets/<set>/set.yml`
(docdesigner's own repo layout), then `set.yml` at the repo root (a
dedicated single-set repo).
