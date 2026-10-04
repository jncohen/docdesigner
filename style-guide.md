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

Built-in styles live in `inst/sets/<set>/styles/<style>/format.yml`.

## Style Bundle Rules

A style is declarative. It describes typography and visual defaults through
design tokens, without adding R code. Tokens are flat dotted keys — one
`key: value` per line. A style declares only its identity and the tokens that
differ from the defaults:

```yaml
id: policy
label: Policy
description: Public policy report style

typography.body: "Source Serif 4"
color.accent: "006A71"
color.rule: "006A71"
headings.number_sections: false
title.layout: report
title.rule.position: below
code.highlight: pygments
```

Scaffold and validate with `designer_new_style()` and
`designer_validate_style()`. `designer_tokens()` and `STYLE-SPEC.md` list the
full vocabulary.

Bundled font families: `Source Serif 4`, `EB Garamond`, `XITS`, `Fira Code`.
A style may declare others under `fonts.<Family>` and ship the faces in its own
`assets/fonts/`. Use six-character hex colors without `#`.
