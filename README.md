# docdesigner

Knit attractive, publication-quality documents from R Markdown without deep LaTeX or design knowledge.

`docdesigner` is a **token-driven rendering engine** plus **distributable style sets**. A style is a small YAML file of design tokens; the engine turns those tokens into LaTeX. Styles are self-contained and independently upgradeable, and sets can be installed from GitHub.

> **Status: 0.9.1, alpha.** The engine and the style-set format are working and tested: `R CMD check` is clean, all twelve styles validate and render, and 84 token-to-page checks pass. The design layer is not finished — see [Known limitations](#known-limitations) before judging output quality. If you are evaluating this for us, start with `TESTING.md` — it is sent alongside the tarball, and is also in the repository root.

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
      minimal/ nature/ methods/ demography/ ssrn/ sociology/ ajs/
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

`format.yml` is a flat list of dotted-key tokens — one `key: value` per line. It declares only its identity (`id`, `label`, `description`) and the tokens that differ from the engine defaults; anything omitted falls back to the schema (`inst/engine/schema.yml`). Run `designer_tokens()` or read [STYLE-SPEC.md](STYLE-SPEC.md) for the full vocabulary.

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

title.layout: journal
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
- [docdesigner.md](docdesigner.md) — project status, roadmap, open decisions.
- [CLAUDE.md](CLAUDE.md) — orientation for AI coding sessions.
- [dev/NOTEBOOK.md](dev/NOTEBOOK.md) — the canonical developer reference (architecture, template port, engine traps, workflow, distribution).
