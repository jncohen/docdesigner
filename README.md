# docdesigner

`docdesigner` provides three user-facing R Markdown outputs:

- `docdesigner::pdf` for designed PDF documents.
- `docdesigner::html` for plain body HTML that can be pasted into WordPress or another CMS.
- `docdesigner::snapshot` for the official Snapshot PDF layout, with optional plain HTML companion output.

The goal is short YAML and predictable behavior. Package defaults know where the bundled template, fonts, CSL, slides, and styles live.

See [USER-MANUAL.md](USER-MANUAL.md) for the full user manual, style gallery, and guide to creating styles.

## Minimal YAML

Designed PDF:

```yaml
---
title: "Document Title"
author: "Your Name"
output:
  docdesigner::pdf:
    style: policy
---
```

Plain HTML:

```yaml
---
title: "Article Title"
author: "Your Name"
output:
  docdesigner::html
---
```

Official Snapshot:

```yaml
---
title: "Finding-Forward Headline"
author: "Your Name"
snapshot_feature: "figures/chart.png"
snapshot_data_note: "Data: source note."
output:
  docdesigner::snapshot:
    html: true
---
```

## Starters

Create a starter file from R:

```r
docdesigner::designer_use(template = "pdf")
docdesigner::designer_use(template = "html")
docdesigner::designer_use(template = "snapshot")
```

RStudio users can also choose the package templates from **File > New File > R Markdown > From Template**.

## Updating Local Template Copies

Most documents use bundled package assets automatically. Updating the package updates the default TeX template, fonts, CSL, and style bundles.

If a project deliberately keeps local editable copies, refresh them from the installed package:

```r
docdesigner::designer_update_templates()
```

Or pull the latest assets from GitHub:

```r
docdesigner::designer_update_templates(source = "github", branch = "main")
```

## Styles

Styles apply to general PDFs. Snapshot has one official style and does not expose a style choice.

```r
docdesigner::designer_styles()
docdesigner::designer_style("methods")
docdesigner::designer_gallery()
```

Built-in styles live under:

```text
inst/styles/
  policy/
    style.yml
  methods/
    style.yml
  demography/
    style.yml
```

A style bundle is a directory with a `style.yml` file:

```yaml
name: methods
label: Methods
description: Computational social science and methods journals
fontset: methods
accent: "003DA5"
highlight: tango
maincolumns: 1
numbersections: true
link_citations: true
```

Users can experiment with a local style bundle by passing its directory path:

```yaml
output:
  docdesigner::pdf:
    style: "path/to/my-style"
```

## Optional YAML

Most documents should not need template, font, or CSL paths in YAML. Use optional fields only when the document needs them.

Common metadata:

```yaml
subtitle: "Subtitle"
date: "`r format(Sys.Date(), '%B %d, %Y')`"
abstract: |
  Short abstract.
keywords:
  - keyword one
  - keyword two
bibliography: references.bib
csl: default.csl
```

Snapshot publishing fields:

```yaml
snapshot_feature: "figures/chart.png"
snapshot_feature_caption: "Caption text."
snapshot_byline_name: "Author Name"
snapshot_byline_title: "Title"
snapshot_byline_affiliation: "Affiliation"
snapshot_byline_bio: "Short bio."
snapshot_code_url: "https://github.com/..."
snapshot_license: "cc-by-nc-sa-4.0"
snapshot_data_note: "Data: source note."
```

## Repository Layout

- `R/` contains package functions.
- `inst/templates/`, `inst/fonts/`, `inst/csl/`, and `inst/slides/` contain bundled runtime assets.
- `inst/styles/` contains modular PDF style bundles.
- `inst/rmarkdown/templates/` contains RStudio starter templates.
- `examples/` contains fuller source examples and fixtures.
- `rendered-examples/` is created by `Rscript run-tests.R` and is ignored by Git.
- `tests/` contains lightweight automated checks for `R CMD check`.
