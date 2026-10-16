# docdesigner

Knit attractive, publication-quality documents from R Markdown without deep LaTeX or design knowledge.

`docdesigner` is a **token-driven rendering engine** plus **distributable style sets**. A style is a small YAML file of design tokens; the engine turns those tokens into LaTeX. Styles are self-contained and independently upgradeable, and sets can be installed from GitHub.

> **Status: 0.10.0, alpha.** `R CMD check` passes on Linux and Windows, all
> thirteen styles render, and 90 checks that each style's tokens reach the page
> pass. See [Known limitations](#known-limitations). Testers can start with
> [alpha-testing-instructions.pdf](alpha-testing-instructions.pdf), or
> [TESTING.md](TESTING.md) for the short version.

See every style as a sample PDF in the
[style gallery](https://jncohen.github.io/docdesigner/articles/gallery.html).

## Install

```r
# install.packages("remotes")
remotes::install_github("jncohen/docdesigner")
```

PDF output needs Pandoc 3.1.8 or newer (RStudio includes it) and xelatex
(TinyTeX is enough).

## Outputs

- `docdesigner::pdf`: a designed PDF, set in one of the styles.
- `docdesigner::html`: plain body HTML for pasting into WordPress or another
  CMS.

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

## Starters

```r
docdesigner::designer_use(template = "pdf")       # or "html"
```

RStudio users can also pick the package templates from **File > New File > R Markdown > From Template**.

## Styles and style sets

A **style** is a directory containing `format.yml`. A **set** is a directory of styles with a `set.yml` manifest. Thirteen styles ship in two sets:

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
inherits: modern             # optional; resolves a full chain

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

Reports whether the template, fonts, citation style, styles, Pandoc and a LaTeX engine can all be found.

## Known limitations

1. **Tables in two-column styles** (`nature`, `economist`) are floats: they
   move, never split across pages, and lose their column widths. See the
   warning above.
2. **Some tokens validate but do nothing yet.** `designer_validate_style()`
   lists them as "not yet implemented". The main ones: `table.style` (only
   `booktabs` renders, so government's grid tables are plain rules),
   `figure.placement`, `links.underline` and `title.keywords.show`.
3. **Not printed:** `keywords` (they go into the PDF's metadata only) and the
   author `orcid`.
4. **The last page of a two-column document is not balanced**, so the right
   column can end well above the left.
5. **The bundled fonts take 3.4 MB.** That is too large for CRAN, which is on
   hold until they move.

## Repository layout

```text
R/
  engine.R                  token resolution, fonts, dd_preamble(), pdf()
  schema.R                  reads and validates the token schema
  sets.R                    install, list, update and scaffold styles and sets
  specimens.R               designer_specimens()
  html.R  html-assets.R     html() and its image and checklist helpers
  gallery.R  check.R  use.R  styles.R  design_brief.R  import_html.R  utils.R
inst/engine/schema.yml      the token vocabulary and its defaults
inst/engine/*.lua           pandoc filters: authors, tables, table headers,
                            callouts, drop caps
inst/templates/docdesigner.tex   the LaTeX template pdf() renders through
inst/sets/                  the bundled style sets
inst/fonts/                 bundled fonts (3.4 MB)
inst/specimen/specimen.md   the document designer_specimens() renders
inst/rmarkdown/templates/   RStudio starter templates
design-sets/                style drafts; not part of the package
examples/                   example documents, including the gallery specimen
dev/                        development scripts (render, verify, specimens)
pkgdown/assets/specimens/   the gallery's PDFs and thumbnails
tests/test-package.R        tests run by R CMD check; they do not render PDFs
```

## Documentation

The website, <https://jncohen.github.io/docdesigner/>, has the function
reference, the [style gallery](https://jncohen.github.io/docdesigner/articles/gallery.html),
[Getting started](https://jncohen.github.io/docdesigner/articles/getting-started.html)
and [Creating a style](https://jncohen.github.io/docdesigner/articles/creating-styles.html).
[USER-MANUAL.md](USER-MANUAL.md) collects the user documentation in one file.
