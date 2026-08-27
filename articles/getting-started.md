# Getting Started with docdesigner

`docdesigner` has three outputs:

- [`docdesigner::pdf`](https://jncohen.github.io/docdesigner/reference/pdf.md)
  creates a designed PDF document.
- [`docdesigner::html`](https://jncohen.github.io/docdesigner/reference/html.md)
  creates plain body HTML for WordPress or another CMS.
- [`docdesigner::snapshot`](https://jncohen.github.io/docdesigner/reference/snapshot.md)
  creates the official Snapshot PDF and, by default, a plain HTML
  companion.

The main design principle is short YAML. A field should appear in YAML
only when it changes the document, identifies the document, or helps
publishing.

## Start a Document

Create a starter:

``` r

docdesigner::designer_use(template = "pdf")
docdesigner::designer_use(template = "html")
docdesigner::designer_use(template = "snapshot")
```

Or use RStudio:

``` text
File > New File > R Markdown > From Template
```

## Minimal PDF YAML

``` yaml
---
title: "Document Title"
author: "Your Name"
output:
  docdesigner::pdf:
    style: policy
---
```

## Minimal HTML YAML

``` yaml
---
title: "Article Title"
author: "Your Name"
output:
  docdesigner::html
---
```

## Minimal Snapshot YAML

``` yaml
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

Snapshot has one official style. Do not add `style` or `accent` to
Snapshot YAML unless you are deliberately testing template internals.

## Check Your Setup

Run:

``` r

docdesigner::designer_check()
```

This checks package assets, style bundles, `rmarkdown`, Pandoc, and
common LaTeX engines.
