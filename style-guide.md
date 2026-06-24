# docdesigner Style Guide

This guide describes the public style system for general PDFs.

## Outputs and Styles

Styles apply to:

```yaml
output:
  docdesigner::pdf:
    style: policy
```

Styles do not apply to:

```yaml
output:
  docdesigner::html
```

Snapshot uses one official house style:

```yaml
output:
  docdesigner::snapshot
```

## Built-In Styles

Use:

```r
docdesigner::designer_styles()
docdesigner::designer_gallery()
```

Built-in styles live in `inst/styles/<style-name>/style.yml`.

## Style Bundle Rules

A style bundle is declarative. It should describe typography and visual defaults without adding R code.

Required fields:

```yaml
name: policy
label: Policy
description: Public policy report style
fontset: docdesigner
accent: "006A71"
highlight: pygments
maincolumns: 1
numbersections: false
link_citations: true
```

Allowed fontsets:

- `default`
- `humanities`
- `demography`
- `methods`
- `docdesigner`

Use six-character hex colors without `#`.
