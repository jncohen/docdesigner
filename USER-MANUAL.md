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
- `sets/`

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

Snapshot has one official style. Do not add `style` or `accent` to Snapshot YAML unless you are deliberately testing the template internals.

## Style Gallery

Styles apply to `docdesigner::pdf`. They do not apply to `docdesigner::html`, and Snapshot uses its official house style.

| Style | Visual use | Body font | Accent | Sections | Columns |
|---|---|---|---|---|---|
| `minimal` | Clean arXiv / university preprint | Source Serif 4 | `333333` | numbered | 1 |
| `policy` | Brookings / Urban / OECD policy report | Source Serif 4 | `006A71` | unnumbered | 1 |
| `methods` | Computational social science / methods | Source Serif 4 | `003DA5` | numbered | 1 |
| `demography` | Demography / Social Forces article | XITS | `000000` | numbered | 1 |
| `humanities` | Critical Inquiry / university-press essay | EB Garamond | `000000` | unnumbered | 1 |
| `economist` | The Economist / public data journalism | Source Serif 4 | `B21F24` | unnumbered | 1 |
| `nature` | Nature / Science article | Source Serif 4 | `2F6F8F` | numbered | 2 |
| `ssrn` | SSRN / NBER working paper | XITS | `000000` | numbered | 1 |
| `atlantic` | The Atlantic / long-form scholarship | EB Garamond | `8F1D14` | unnumbered | 1 |
| `government` | Census / Federal Reserve bulletin | XITS | `2F4F3E` | numbered | 1 |

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

A style is a folder with a `format.yml` file of design tokens. Built-in styles
ship inside two sets, `academic` and `public`:

```text
inst/sets/
  academic/
    set.yml
    styles/
      minimal/
        format.yml
  public/
    set.yml
    styles/
      policy/
        format.yml
```

Tokens are written as flat dotted keys — one `key: value` per line. Only the
identity keys (`id`, `label`, `description`) and the tokens that differ from the
defaults need to appear:

```yaml
id: my-style
label: My Style
description: A concise description of where this style should be used

typography.body: "Source Serif 4"
typography.heading: "Source Serif 4"
typography.base_size: "10pt"

color.accent: "005EA8"
color.rule: "005EA8"

headings.number_sections: true
headings.h1.scale: 1.30

title.layout: plain
code.highlight: tango
```

Scaffold a new style from an existing one, then edit only what differs:

```r
docdesigner::designer_new_style("my-style", from = "minimal")
```

Validate it against the token schema before rendering:

```r
docdesigner::designer_validate_style("my-style")
```

`docdesigner::designer_tokens()` lists every available token with its type,
allowed values, default, and implementation status. `STYLE-SPEC.md` documents
the whole vocabulary. Use a local style by its folder path:

```yaml
output:
  docdesigner::pdf:
    style: "path/to/my-style"
```

Keep styles declarative. They describe a visual system through tokens, not
arbitrary R code.

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
