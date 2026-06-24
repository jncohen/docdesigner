# docdesigner User Manual

`docdesigner` has three outputs:

- `docdesigner::pdf` creates a designed PDF document.
- `docdesigner::html` creates plain body HTML for WordPress or another CMS.
- `docdesigner::snapshot` creates the official Snapshot PDF and, by default, a plain HTML companion.

The main design principle is simple YAML. A field should appear in YAML only when it changes the document, identifies the document, or helps publishing.

## Start a Document

Create a starter:

```r
docdesigner::designer_use(template = "pdf")
docdesigner::designer_use(template = "html")
docdesigner::designer_use(template = "snapshot")
```

Or use RStudio:

```text
File > New File > R Markdown > From Template
```

## Updating Templates

Most projects should use bundled package assets. In that workflow, the update path is simply:

```r
# reinstall or update docdesigner
```

After the package is updated, documents using `docdesigner::pdf`, `docdesigner::html`, or `docdesigner::snapshot` use the updated bundled assets automatically.

If a project keeps editable local copies, refresh those copies from the installed package:

```r
docdesigner::designer_update_templates()
```

To pull the latest assets from GitHub instead:

```r
docdesigner::designer_update_templates(source = "github", branch = "main")
```

That updates:

- `docdesignertemplate.tex`
- `default.csl`
- `fonts/`
- `styles/`

## Minimal YAML

PDF:

```yaml
---
title: "Document Title"
author: "Your Name"
output:
  docdesigner::pdf:
    style: policy
---
```

HTML:

```yaml
---
title: "Article Title"
author: "Your Name"
output:
  docdesigner::html
---
```

Snapshot:

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

Snapshot has one official style. Do not add `style`, `fontset`, or `accent` to Snapshot YAML unless you are deliberately testing the template internals.

## Style Gallery

Styles apply to `docdesigner::pdf`. They do not apply to `docdesigner::html`, and Snapshot uses its official house style.

| Style | Visual Use | Fontset | Accent | Sections | Columns |
|---|---|---|---|---|---|
| `minimal` | Clean university preprint | `default` | `333333` | numbered | 1 |
| `policy` | Public policy report | `docdesigner` | `006A71` | unnumbered | 1 |
| `methods` | Technical or methods paper | `methods` | `003DA5` | numbered | 1 |
| `demography` | Social-science journal article | `demography` | `000000` | numbered | 1 |
| `humanities` | Essay or chapter style | `humanities` | `000000` | unnumbered | 1 |
| `economist` | Public data journalism | `docdesigner` | `B21F24` | unnumbered | 1 |
| `nature` | Scientific article style | `methods` | `2F6F8F` | numbered | 2 |
| `ssrn` | Working paper style | `demography` | `000000` | numbered | 1 |
| `atlantic` | Long-form public scholarship | `humanities` | `8F1D14` | unnumbered | 1 |
| `government` | Statistical bulletin style | `demography` | `2F4F3E` | numbered | 1 |

Inspect styles from R:

```r
docdesigner::designer_styles()
docdesigner::designer_style("policy")
docdesigner::designer_gallery()
```

Use a style:

```yaml
output:
  docdesigner::pdf:
    style: methods
```

## Creating Styles

A style is a folder with a `style.yml` file. Built-in styles live in:

```text
inst/styles/
  policy/
    style.yml
  methods/
    style.yml
```

Create a local style folder:

```text
my-style/
  style.yml
```

Write a manifest:

```yaml
name: my-style
label: My Style
description: A concise description of where this style should be used
fontset: methods
accent: "005EA8"
highlight: tango
maincolumns: 1
numbersections: true
link_citations: true
```

Use the local style by path:

```yaml
output:
  docdesigner::pdf:
    style: "my-style"
```

Style fields:

| Field | Required | Meaning |
|---|---:|---|
| `name` | yes | Machine-readable style name. Use lowercase letters, numbers, and hyphens. |
| `label` | yes | Human-readable name. |
| `description` | yes | Short explanation for galleries and documentation. |
| `fontset` | yes | One of `default`, `humanities`, `demography`, `methods`, or `docdesigner`. |
| `accent` | yes | Six-character hex color without `#`. |
| `highlight` | yes | Pandoc syntax highlighting style, such as `tango`, `kate`, or `pygments`. |
| `maincolumns` | yes | `1` or `2`. |
| `numbersections` | yes | `true` or `false`. |
| `link_citations` | yes | `true` or `false`. |

Keep style bundles declarative. They should describe a visual system, not add arbitrary R code.

## Optional YAML

Common fields:

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

## Diagnostics

Run:

```r
docdesigner::designer_check()
```

This checks package assets, style bundles, `rmarkdown`, Pandoc, and common LaTeX engines.
