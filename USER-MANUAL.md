# docdesigner User Manual

`docdesigner` has two outputs:

- `docdesigner::pdf` creates a designed PDF document.
- `docdesigner::html` creates plain body HTML for WordPress or another CMS.

The main design principle is simple YAML. A field should appear in YAML only when it changes the document, identifies the document, or helps publishing.

## Start a Document

Create a starter:

```r
docdesigner::designer_use(template = "pdf")
docdesigner::designer_use(template = "html")
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

After the package is updated, documents using `docdesigner::pdf` or `docdesigner::html` use the updated bundled assets automatically.

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

PDF options:

```yaml
---
title: "Document Title"
author:
  - name: "First Author"
    dept: "Department of Sociology"
    inst: "Queens College, CUNY"
    address: "65-30 Kissena Blvd, Queens, NY 11367"
    email: "first.author@example.edu"
    web: "example.edu/~first"
  - name: "Second Author"
warning: "DRAFT IN PROGRESS: DO NOT CIRCULATE"
acknowledgements: |
  I thank the department's workshop for comments.
output:
  docdesigner::pdf:
    style: methods
    title_layout: page
    doublespace: true
---
```

- `doublespace: true` double-spaces the body text, as for a manuscript under
  review. Titles, headings, tables, captions, footnotes and code stay
  single-spaced.
- `title_layout: page` gives the title, byline and abstract a page of their
  own; `header` (the default in every style) sets them at the top of page 1.
- `author` is a plain string or a list of people. Each person's `name` appears
  in the byline, with several authors stacked. The corresponding author
  (marked `corresponding: true`, otherwise the first author with an `address`,
  `email` or `web`) gets a contact block: name, `dept` and `inst`, `address`,
  and linked `email` and `web`. `orcid` is accepted but not printed yet.
- `kicker` replaces the small label some styles set above the title
  ("POLICY BRIEF" in policy, "WORKING PAPER" in ssrn and economist):
  `kicker: "Research Brief"`. `kicker: ""` removes it, and any style accepts
  one.
- `warning` is a line such as "DRAFT IN PROGRESS: DO NOT CIRCULATE", set
  between two rules. `acknowledgements` (or `acknowledgments`) is a paragraph
  or more of thanks.
- On a title page the contact block, the warning and the acknowledgements
  stack at the foot of the page, in that order. In the header layout the
  warning sits above the title, and the contact details and acknowledgements
  become an unnumbered note at the foot of page 1.

> **Warning: tables in two-column styles (`nature`, `economist`).** A
> two-column page cannot hold a table that breaks across pages, so in these
> styles every table becomes a float, placed by LaTeX:
>
> - **A table may not appear where you put it.** It moves to the top of a
>   column or page, often after the paragraph that follows it. Refer to
>   tables by number ("Table 2"), never as "the table below".
> - **A table that fits one column stays in the column; a wider one spans
>   both columns** and moves to the top of the next page that has room.
> - **A table is never split.** One taller than a page runs off the bottom.
>   Keep tables short, or split them yourself.
> - **Column widths are not kept.** Text in cells does not wrap, so a long
>   cell widens the whole table. Keep cell text short.
>
> For long or wide tables, use a single-column style.

HTML:

```yaml
---
title: "Article Title"
author: "Your Name"
output:
  docdesigner::html
---
```

## Style Gallery

Styles apply to `docdesigner::pdf`. They do not apply to `docdesigner::html`.

Sixteen styles ship in two sets: `academic` (`minimal`, `modern`, `nature`, `methods`,
`demography`, `ssrn`, `sociology`, `ajs`, `thesis`, `qc-thesis`) and `public`
(`policy`, `government`, `economist`, `atlantic`, `humanities`, `bulletin`).

### Writing a thesis

Two styles set a thesis: `thesis`, plain and conservative, and `qc-thesis`,
the same with the Queens College title page for the MA in Data Analytics and
Applied Social Research. Both use the thesis title layout: a title page with
the degree statement, an optional copyright page, then contents,
acknowledgements and abstract numbered i, ii, iii, with chapters starting on
new pages from page 1.

```yaml
---
title: "Thesis Title"
author: "Student Name"
date: "May 2027"
degree: "Master of Arts in Sociology"     # qc-thesis fills this in
institution: "Queens College"             # one line, or a list of lines
committee:
  - name: "Faculty Member"
    role: "Committee Chair"
  - name: "Second Reader"
    role: "Committee Member"
signatures: true      # signature lines on the title page; qc-thesis default
copyright: true       # adds a copyright page
toc: true
acknowledgements: |
  ...
abstract: |
  ...
output:
  docdesigner::pdf:
    style: qc-thesis
---
```

Each level-one heading (`#`) is a chapter. `signatures: false` removes the
signature block. Any style can use the thesis layout with
`title_layout: thesis` under `docdesigner::pdf:`.

Per-style details — body font, accent colour, section numbering, column count —
are **not** listed here on purpose. A hand-written table of them lived at this
spot and silently went stale: after the rebuilt styles were promoted on
2026-08-26, every accent colour in it was wrong. The Style Gallery vignette
builds the same table from the installed styles, so it cannot drift:

```r
vignette("style-gallery", package = "docdesigner")
designer_styles()               # id, label, description, set
designer_style("policy")        # the fully resolved token spec
```

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

title.layout: header
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
allowed values, default, and implementation status. The *Creating a style* article documents
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

## Diagnostics

Run:

```r
docdesigner::designer_check()
```

This checks package assets, style bundles, `rmarkdown`, Pandoc, and common LaTeX engines.
