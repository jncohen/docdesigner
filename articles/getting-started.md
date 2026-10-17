# Getting Started with docdesigner

`docdesigner` has two outputs:

- [`docdesigner::pdf`](https://jncohen.github.io/docdesigner/reference/pdf.md)
  creates a designed PDF document.
- [`docdesigner::html`](https://jncohen.github.io/docdesigner/reference/html.md)
  creates plain body HTML for WordPress or another CMS.

The main design principle is short YAML. A field should appear in YAML
only when it changes the document, identifies the document, or helps
publishing.

## Start a Document

Create a starter:

``` r

docdesigner::designer_use(template = "pdf")
docdesigner::designer_use(template = "html")
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

## PDF options

``` yaml
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

- `doublespace: true` double-spaces the body text, as for a manuscript
  under review. Titles, headings, tables, captions, footnotes and code
  stay single-spaced.
- `title_layout: page` gives the title, byline and abstract a page of
  their own; `header` (the default in every style) sets them at the top
  of page 1.
- `author` is a plain string or a list of people. Each person’s `name`
  appears in the byline, with several authors stacked. The corresponding
  author (marked `corresponding: true`, otherwise the first author with
  an `address`, `email` or `web`) gets a contact block: name, `dept` and
  `inst`, `address`, and linked `email` and `web`. `orcid` is accepted
  but not printed yet.
- `kicker` replaces the small label some styles set above the title
  (“POLICY BRIEF” in policy, “WORKING PAPER” in ssrn and economist):
  `kicker: "Research Brief"`. `kicker: ""` removes it, and any style
  accepts one.
- `warning` is a line such as “DRAFT IN PROGRESS: DO NOT CIRCULATE”, set
  between two rules. `acknowledgements` (or `acknowledgments`) is a
  paragraph or more of thanks.
- On a title page the contact block, the warning and the
  acknowledgements stack at the foot of the page, in that order. In the
  header layout the warning sits above the title, and the contact
  details and acknowledgements become an unnumbered note at the foot of
  page 1.

> **Warning: tables in two-column styles (`nature`, `economist`).** A
> two-column page cannot hold a table that breaks across pages, so in
> these styles every table becomes a float, placed by LaTeX:
>
> - **A table may not appear where you put it.** It moves to the top of
>   a column or page, often after the paragraph that follows it. Refer
>   to tables by number (“Table 2”), never as “the table below”.
> - **A table that fits one column stays in the column; a wider one
>   spans both columns** and moves to the top of the next page that has
>   room.
> - **A table is never split.** One taller than a page runs off the
>   bottom. Keep tables short, or split them yourself.
> - **Column widths are not kept.** Text in cells does not wrap, so a
>   long cell widens the whole table. Keep cell text short.
>
> For long or wide tables, use a single-column style.

## Writing a thesis

Two styles set a thesis: `thesis`, plain and conservative, and
`qc-thesis`, the same with the Queens College title page for the MA in
Data Analytics and Applied Social Research. Both use the thesis title
layout: a title page with the degree statement, an optional copyright
page, then contents, acknowledgements and abstract numbered i, ii, iii,
with chapters starting on new pages from page 1.

``` yaml
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

Each level-one heading (`#`) is a chapter. `signatures: false` removes
the signature block. Any style can use the thesis layout with
`title_layout: thesis` under `docdesigner::pdf:`.

## Minimal HTML YAML

``` yaml
---
title: "Article Title"
author: "Your Name"
output:
  docdesigner::html
---
```

## Check Your Setup

Run:

``` r

docdesigner::designer_check()
```

This checks package assets, style bundles, `rmarkdown`, Pandoc, and
common LaTeX engines.
