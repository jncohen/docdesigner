# docdesigner

Knit attractive, publication-quality documents from R Markdown without deep LaTeX or design knowledge.

`docdesigner` is a **token-driven rendering engine** plus **distributable style sets**. A style is a small YAML file of design tokens; the engine turns those tokens into LaTeX. Styles are self-contained and independently upgradeable, and sets can be installed from GitHub.

> **Status: 0.9.10, alpha.** The engine and the style-set format are working and tested: `R CMD check` is clean, all thirteen styles validate and render, and 84 token-to-page checks pass. The design layer is not finished — see [Known limitations](#known-limitations) before judging output quality. If you are evaluating this for us, start with [alpha-testing-instructions.pdf](alpha-testing-instructions.pdf), or [TESTING.md](TESTING.md) for the short version.

## Outputs

- `docdesigner::pdf` — designed PDF, driven by a style.
- `docdesigner::html` — plain body HTML for pasting into WordPress or another CMS.
- `docdesigner::snapshot` — the official Snapshot PDF layout, with an optional HTML companion.

## Minimal YAML

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

```yaml
---
title: "Article Title"
output:
  docdesigner::html
---
```

```yaml
---
title: "Finding-Forward Headline"
snapshot_feature: "figures/chart.png"
snapshot_data_note: "Data: source note."
output:
  docdesigner::snapshot:
    html: true
---
```

## Starters

```r
docdesigner::designer_use(template = "pdf")       # or "html", "snapshot"
```

RStudio users can also pick the package templates from **File > New File > R Markdown > From Template**.

## Styles and style sets

A **style** is a directory containing `format.yml`. A **set** is a directory of styles with a `set.yml` manifest. Ten styles ship across two sets:

```text
inst/sets/
  academic/
    set.yml
    styles/
      minimal/ modern/ nature/ methods/ demography/ ssrn/ sociology/ ajs/
  public/
    set.yml
    styles/
      policy/ government/ economist/ atlantic/ humanities/
```

```r
designer_styles()             # every installed style
designer_sets()               # every installed set
designer_style("methods")     # fully resolved tokens for one style
designer_gallery()            # HTML swatch table
designer_specimens()          # render a PDF specimen per style + gallery index
```

### A style file

`format.yml` is a flat list of dotted-key tokens — one `key: value` per line. It declares only its identity (`id`, `label`, `description`) and the tokens that differ from the engine defaults; anything omitted falls back to the schema (`inst/engine/schema.yml`). Run `designer_tokens()` for the full vocabulary, and see [Creating a style](https://jncohen.github.io/docdesigner/articles/creating-styles.html) for how to write a style and what makes a good one.

```yaml
id: methods
label: Methods
description: Computational social science and methods journals
inherits: minimal            # optional; resolves a full chain

typography.body: "Source Serif 4"
typography.heading: "Source Serif 4"
typography.mono: "Fira Code"
typography.base_size: "10pt"

color.accent: "003DA5"
color.rule: "003DA5"

headings.number_sections: true
headings.h1.scale: 1.30
headings.h1.rule.position: below
headings.h1.rule.weight: medium
headings.h2.scale: 1.12

title.layout: header
title.rule.position: below
title.rule.weight: thick
title.rule.color: rule

code.highlight: tango
```

Point a document at a style directory to try it without installing:

```yaml
output:
  docdesigner::pdf:
    style: "path/to/my-style"
```

### Creating a style

```r
designer_new_style("my-style", from = "minimal", path = "~/styles")
```

The scaffold contains the source style's *declared* tokens only, not the resolved defaults, so it keeps tracking engine changes. Edit, then render a specimen to see it:

```r
designer_specimens(styles = "my-style")
```

### Installing a set from GitHub

```r
designer_install_set("academic")                   # from the canonical library, jncohen/docdesigner
designer_install_set(repo = "owner/repo")           # a dedicated repo with set.yml at its root
designer_install_set("some-set", repo = "owner/monorepo")  # a set inside someone else's monorepo
designer_update_sets()                              # re-pull recorded sources
```

Sets install under `tools::R_user_dir("docdesigner", "data")` and survive package updates. A user set **shadows** a core style of the same id, with a warning. Sets declare a `format_version`; the engine refuses to load a set from a newer format rather than mis-render it.

### Fonts

Styles and sets may declare their own font families and ship the files alongside. Lookup order is style → set → core:

```text
my-set/
  set.yml
  assets/fonts/Inter-Regular.otf
  assets/fonts/Inter-Bold.otf
  styles/my-style/format.yml
```

```yaml
fonts.Inter.regular: Inter-Regular.otf
fonts.Inter.bold: Inter-Bold.otf
typography.body: Inter
typography.heading: Inter
```

All faces of a family must live in one directory — `fontspec`'s `Path=` applies per family.

## Checking your setup

```r
designer_check()
```

Reports whether the template, fonts, CSL, styles, Pandoc, and a LaTeX engine are all findable. PDF output requires **xelatex** (TinyTeX is fine) and **Pandoc**.

## Known limitations

Read this before evaluating output.

1. **`pdf()` does not use `inst/templates/docdesignertemplate.tex`.** It generates a preamble from tokens and hands it to `rmarkdown::pdf_document()`'s stock template. Only `snapshot()` uses the bundled template.
2. **Consequently, `pdf()` cannot render** `subtitle` title pages, `institution` / `series` / `number`, `author_dept` / `_inst` / `_addr` / `_email` / `_orcid`, `keywords`, `acknowledgements`, `anonymize`, `doublespace`, `linenumbers`, or running heads (`surname`, `runningtitle`). The `.tex` supports all of these; the token engine does not yet reach them.
3. **Page architecture is not tokenized.** The vocabulary now reaches fonts, sizes, colour roles, heading scales, columns, title kickers, boxed abstracts and code panels — so the twelve styles no longer differ only by accent colour. What it does not reach is page *furniture*: title-page layout, the author block, full-bleed masthead bands, boxed callouts. `economist` and `government` depend on exactly that, and are the two styles that still do not resemble their models.

The fix for all three is one piece of work: port `pdf()` *onto* the template and tokenize its branching. See `docdesigner.md` for the staged plan.

## Repository layout

```text
R/                          package functions
  engine.R                  token resolution, font registry, dd_preamble(), pdf()
  sets.R                    install / list / update / scaffold
  specimens.R               designer_specimens(): the only path that runs xelatex
  snapshot.R  html.R  gallery.R  check.R  use.R  styles.R  utils.R
inst/engine/schema.yml      token schema + defaults; every style inherits these
inst/engine/*.lua           pandoc filters (two-column tables)
inst/sets/                  bundled style sets
inst/specimen/specimen.md   the document rendered by designer_specimens()
inst/templates/             docdesignertemplate.tex (snapshot only, for now)
inst/fonts/                 14 bundled font files (3.4 MB; slated to move)
inst/rmarkdown/templates/   RStudio starter templates
examples/                   fuller source examples and fixtures
tests/test-package.R        R CMD check suite; does not render PDFs
tools/render_style.py       dev harness; the executable spec for the engine
rendered-examples/          created by designer_specimens(); git-ignored
```

## Documentation

- [USER-MANUAL.md](USER-MANUAL.md) — full user manual.
