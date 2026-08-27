# docdesigner style specification

**Format version 2 (draft).** This document defines every design token a
`docdesigner` style may set. It is written to be read by a person *or*
handed to a language model as a reference, together with a page of the
publication to be imitated.

------------------------------------------------------------------------

## How to use this document with an AI

Paste this file into the conversation along with an image of the page
you want to imitate, then ask for a `format.yml`. Rules the model must
follow:

1.  **Emit only keys defined below.** Unknown keys are rejected by
    [`designer_validate_style()`](https://jncohen.github.io/docdesigner/reference/designer_validate_style.md).
2.  **Omit anything that matches the default.** A style declares only
    what differs.
3.  **Never name a proprietary typeface.** Publications use fonts you
    cannot license (*The Economist* uses Milo and EcoSans; *Nature* uses
    Harding). Specify a metric-similar open substitute from the [font
    substitution table](#font-substitution) and note the original in
    `description`.
4.  **Choose an archetype before overriding.** Pick `title.layout` and
    `figure.style` from the named menus, then override individual keys
    only where the target page demands it.
5.  **Do not invent units.** Lengths are LaTeX dimensions (`pt`, `mm`,
    `in`, `em`, `ex`, `\baselineskip`). Ratios are unitless numbers.
    Colours are 6-digit hex, with or without `#`.

Then:

``` r

designer_style_from_yaml(readr::read_file("claude-output.yml"), id = "my-style")
designer_preview("my-style")     # renders and rasterizes page 1
```

Hand the preview back to the model beside the original page and ask what
is off.

------------------------------------------------------------------------

## Renderer status

Every token is marked. **Do not trust an unmarked token to do
anything.**

| Mark | Meaning |
|----|----|
| `[impl]` | Implemented and rendering today |
| `[port]` | The LaTeX exists in `docdesignertemplate.tex`; needs wiring to a token |
| `[new]` | Requires new LaTeX. Not yet written |
| `[risk]` | Feasible but fragile — interacts badly with two-column, floats, or `linenumbers` |

A style may set a `[new]` token. It will validate, and it will be
ignored until implemented.
[`designer_validate_style()`](https://jncohen.github.io/docdesigner/reference/designer_validate_style.md)
warns when a style relies on unimplemented tokens.

------------------------------------------------------------------------

## Top level

``` yaml
id: economist-ish          # required, unique. Keys resolution, not the folder name
label: "Economist"         # required, human-readable
description: "..."         # recommended. Note the original typefaces here
inherits: minimal          # optional. Resolves a full chain, root-first
format_version: 2          # optional at style level; required in set.yml
```

`inherits` is a resolution instruction, not a token. It is stripped from
the resolved spec.

------------------------------------------------------------------------

## `page`

``` yaml
page:
  papersize: letter        # [impl] letter | a4 | legal
  margin: "1in"            # [impl] shorthand, all four sides
  margins:                 # [new] overrides `margin` when present
    top: "0.9in"
    bottom: "1in"
    inner: "0.85in"        # binding edge when twoside; else left
    outer: "1.1in"
  twoside: false           # [new] mirror inner/outer, alternate running heads
  columns: 1               # [impl] 1 | 2
  gutter: "1.5em"          # [new] column separation (\columnsep)
  column_rule: null        # [new] {weight: "0.4pt", color: rule} or null
  measure: null            # [new] target line length, e.g. "34ch" or "112mm".
                           #       Advisory: sets margins if they are unset
```

**Note on `columns: 2`.** Pandoc emits `longtable`, which is illegal in
a two-column body. The engine applies `inst/engine/twocolumn-tables.lua`
to convert tables into spanning `table*` floats. Figures behave the same
way — a full-width figure in two-column mode must be a `figure*`. This
is handled, but it is the single most fragile area of the renderer.
`[risk]`

------------------------------------------------------------------------

## `typography`

``` yaml
typography:
  body: "Source Serif 4"       # [impl] family name; see fonts:
  heading: "Source Serif 4"    # [impl]
  mono: "Fira Code"            # [impl]
  display: null                # [new] title/masthead face; falls back to heading
  base_size: "10pt"            # [impl]
  line_height: 1.30            # [impl] multiplier (\linespread)
  scale_ratio: null            # [new] modular scale, e.g. 1.200. If set, heading
                               #       scales may be omitted and are derived
  mono_scale: 0.82             # [impl] relative to body
  tracking: 0                  # [new] letterspacing in 1/1000 em, body text
  features:                    # [new] OpenType features via fontspec
    numbers: lining            # lining | oldstyle
    figures: proportional      # proportional | tabular
    ligatures: common          # common | none | historic
  microtype: true              # [impl] protrusion + expansion
  hyphenation: true            # [new] false sets \hyphenpenalty=10000
  justification: justified     # [new] justified | ragged-right
```

### `fonts`

Declare families the core package does not bundle. Files live in
`<style>/assets/fonts/` or `<set>/assets/fonts/`; lookup is style → set
→ core. **All faces of one family must sit in one directory** —
`fontspec`’s `Path=` applies per family. `[impl]`

``` yaml
fonts:
  Inter:
    regular: Inter-Regular.otf
    bold: Inter-Bold.otf
    italic: Inter-Italic.otf
    bolditalic: Inter-BoldItalic.otf
```

Bundled families: `Source Serif 4`, `EB Garamond`, `XITS`, `Fira Code`.

### Font substitution

Never specify a proprietary face. Use these.

| Publication      | Actual              | Open substitute                      |
|------------------|---------------------|--------------------------------------|
| *The Economist*  | Milo Serif, EcoSans | EB Garamond / Source Serif 4 + Inter |
| *Nature*         | Harding, Neue Haas  | Source Serif 4 + Inter               |
| *The Atlantic*   | Adobe Caslon        | EB Garamond                          |
| *Demography*     | Times/Minion        | XITS                                 |
| Brookings, Urban | Roboto, Georgia     | Source Serif 4 + Inter               |
| University press | Monotype Bembo      | EB Garamond                          |

------------------------------------------------------------------------

## `color`

Roles, not names. A style sets roles; the renderer never asks for a
literal colour.

``` yaml
color:
  accent: "E3120B"      # [impl] headings, links, rules
  accent2: null         # [new] secondary accent (bars, callouts)
  text: "000000"        # [impl] body
  muted: "5B6470"       # [impl] captions, folios, author line
  rule: "E3120B"        # [impl] hairlines
  background: null      # [new] page background
  code_bg: null         # [new] code block background
  knockout: "FFFFFF"    # [new] text on an accent-filled bar
```

------------------------------------------------------------------------

## `headings`

`h1`–`h4`. Each key below is per-level. Omitted levels inherit `h3`.

``` yaml
headings:
  number_sections: false      # [impl]
  numbering: arabic           # [new] arabic | roman | alpha | none
  h1:
    family: heading           # [new] heading | body | display | mono
    scale: 1.35               # [impl] multiple of base_size
    size: null                # [new] absolute; overrides scale
    weight: bold              # [impl] bold | regular | light
    style: normal             # [new] normal | italic
    case: none                # [impl] none | upper | lower | smallcaps
    color: accent             # [new] a colour role, not a hex value
    align: left               # [new] left | center | right
    tracking: 0               # [new]
    space_before: "1.7em"     # [impl, hard-coded] currently fixed
    space_after: "0.5em"      # [impl, hard-coded] currently fixed
    rule:                     # [impl as boolean; full form is new]
      position: below         # above | below | none
      weight: "1pt"
      color: rule
      length: full            # full | text | "3em"
    bar: null                 # [new] {fill: accent, text: knockout, pad: "0.3em"}
                              #       section head as a filled bar
  h2: { scale: 1.15, weight: bold }
  h3: { scale: 1.00, weight: bold }
  h4: { scale: 1.00, weight: regular, style: italic }
  run_in: []                  # [new] levels typeset run-in with the paragraph,
                              #       e.g. [h4]
```

------------------------------------------------------------------------

## `title`

Pick a `layout`, then override. The five archetypes are the five title
pages currently hard-coded in `docdesignertemplate.tex`. `[port]`

| `layout` | Description |
|----|----|
| `plain` | Flush left, title / author / date. The current [`pdf()`](https://jncohen.github.io/docdesigner/reference/pdf.md) default. `[impl]` |
| `essay` | Book-like. Centred, generous leading above, no rule. Humanities. |
| `journal` | Centred title, accent rules top and bottom, abstract block, keywords. |
| `report` | Flush left, heavy accent rule under title, institution and series line. |
| `masthead` | Blog/brief. Accent bar, compact byline, one page. |

``` yaml
title:
  layout: journal
  align: center               # [port] left | center
  rule:                       # [port]
    position: below           # above | below | both | none
    weight: "2pt"
    color: rule
  scale: 2.6                  # [impl] multiple of base_size
  family: display             # [new]
  case: none                  # [new]
  subtitle:                   # [port]
    scale: 1.3
    style: italic
    color: muted
  byline:                     # [port]
    position: below           # above | below (relative to title)
    case: smallcaps
    color: muted
  date:
    show: true                # [port]
    color: muted
  abstract:                   # [port]
    width: "0.85\\linewidth"
    size: "0.95"              # multiple of base_size
    label: "Abstract"
    rule: true
  keywords:
    show: true                # [port]
    label: "Keywords"
  page_break_after: false     # [new] true = full title page
```

Deprecated: `title.style: plain|rule|bars`. Accepted in
`format_version: 1` styles and mapped onto `title.layout` +
`title.rule`.

------------------------------------------------------------------------

## `paragraph`

``` yaml
paragraph:
  indent: "0pt"               # [impl, hard-coded] first-line indent
  spacing: "0.5em"            # [impl, hard-coded] \parskip
  indent_after_heading: false # [new] suppress indent on the first para
  drop_cap: null              # [new] {lines: 3, family: display, color: accent}
                              #       via lettrine. [risk] breaks under twocolumn
  widow_penalty: 150          # [new]
  orphan_penalty: 150         # [new]
```

An indent-based style should set `indent: "1em"` **and**
`spacing: "0pt"`. Setting both is a design error;
[`designer_validate_style()`](https://jncohen.github.io/docdesigner/reference/designer_validate_style.md)
warns.

------------------------------------------------------------------------

## `figure`

``` yaml
figure:
  style: plain                # [new] archetype: plain | ruled | full-bleed | inset
  default_width: "\\linewidth"  # [new]
  placement: "htbp"           # [new]
  span_columns: false         # [new] figure* in two-column mode. [risk]
  rule:                       # [new] {position: above, weight: "0.4pt", color: rule}
  caption:
    position: below           # [new] below | above
    family: body              # [new]
    size: 0.85                # [new] multiple of base_size
    align: left               # [new]
    color: muted              # [new]
    label_style: bold         # [new] bold | italic | smallcaps | none
    separator: ". "           # [new]
```

------------------------------------------------------------------------

## `table`

``` yaml
table:
  style: booktabs             # [impl] booktabs | grid | zebra | minimal
  rule_weight: "0.4pt"        # [new]
  row_stretch: 1.2            # [impl]
  header:
    weight: bold              # [new]
    case: none                # [new]
    rule_below: true          # [new]
  zebra_color: null           # [new]
  size: 0.9                   # [new] multiple of base_size
  caption:                    # [new] same keys as figure.caption
    position: above
```

------------------------------------------------------------------------

## `code`

``` yaml
code:
  highlight: tango            # [impl] any pandoc highlight theme, or `none`
  family: mono                # [new]
  size: 0.82                  # [impl] as typography.mono_scale
  background: null            # [new] colour role
  border: null                # [new] {weight, color}
  line_numbers: false         # [new]
```

Pandoc themes: `pygments`, `tango`, `espresso`, `zenburn`, `kate`,
`monochrome`, `breezedark`, `haddock`.

------------------------------------------------------------------------

## `quote`

``` yaml
quote:
  indent: "1em"               # [new]
  size: 1.0                   # [new]
  style: normal               # [new] normal | italic
  color: text                 # [new]
  rule: null                  # [new] {position: left, weight: "2pt", color: accent}
```

------------------------------------------------------------------------

## `footnotes`

``` yaml
footnotes:
  size: 0.8                   # [new]
  rule: { weight: "0.4pt", length: "2in" }   # [new]
  numbering: arabic           # [new] arabic | symbol
  per_page_reset: false       # [new]
```

------------------------------------------------------------------------

## `header_footer`

``` yaml
header_footer:
  header:
    left: null                # [port] null | title | runningtitle | author |
    center: null              #        surname | section | page | "literal text"
    right: null
    rule: null                # [port] {weight, color}
  footer:
    left: null
    center: null
    right: page               # [impl] currently hard-coded
    rule: { weight: "0.4pt", color: muted }   # [impl] hard-coded
  page_number:
    format: arabic            # [new] arabic | roman
    style: plain              # [new] plain | "Page N" | "N of M"
  first_page: plain           # [new] plain | none | full — style of page 1
```

------------------------------------------------------------------------

## `links` and `citations`

``` yaml
links:
  color: accent               # [impl]
  underline: false            # [new]
  external_marker: false      # [new]
citations:
  link: true                  # [impl]
  style: null                 # [new] path to a CSL file, relative to the style dir
bibliography:
  heading: "References"       # [new]
  size: 0.9                   # [new]
  hanging_indent: "1.5em"     # [new]
```

------------------------------------------------------------------------

## `math`

``` yaml
math:
  font: null                  # [new] null = follow body. XITS pairs with XITS text
  numbering: right            # [new] right | left | none
```

------------------------------------------------------------------------

## What LaTeX will not give you

Set expectations honestly; do not spec these.

- **Optical margin alignment** (hanging punctuation beyond protrusion).
  `microtype` approximates it. Magazines do it by hand.
- **Art-directed figure placement.** LaTeX floats optimize a penalty
  function. A designer places figures. Two-column + floats +
  `linenumbers` is a known-bad combination.
- **Copyfitting.** No tracking or leading adjustment to make a column
  bottom out evenly.
- **True mixed-column layout** (a three-column sidebar beside two-column
  body). `paracol` exists and is fragile.
- **Proprietary typefaces.** See the substitution table.

A “faithful reproduction” here means *unmistakably in the family of* the
target publication — right typographic colour, hierarchy, measure, and
palette. It does not mean pixel correspondence.

------------------------------------------------------------------------

## Validation and compatibility

``` r

designer_validate_style("path/to/format.yml")
```

Reports: - **Errors** — unknown keys, bad types, malformed colours,
undeclared font families, missing font files, `inherits` cycles. -
**Warnings** — tokens marked `[new]` that the current engine ignores;
`paragraph.indent` set together with a non-zero `paragraph.spacing`; a
`[risk]` token combined with `columns: 2`.

`set.yml` declares `format_version`. The engine (`DD_FORMAT_VERSION`)
refuses to load a set from a newer format rather than mis-render it.
Version 1 styles load unchanged: `title.style` is mapped onto
`title.layout`, and every `[new]` key is simply absent.

------------------------------------------------------------------------

## Minimal complete example

``` yaml
id: broadsheet
label: "Broadsheet"
description: "Two-column news-feature style. Milo Serif substituted with EB Garamond."
inherits: minimal

page:
  columns: 2
  gutter: "1.6em"
  margins: { top: "0.8in", bottom: "1in", inner: "0.75in", outer: "0.75in" }

typography:
  body: "EB Garamond"
  heading: "EB Garamond"
  base_size: "9.5pt"
  line_height: 1.18
  features: { numbers: oldstyle }

color:
  accent: "E3120B"
  rule: "E3120B"
  muted: "6B7280"
  knockout: "FFFFFF"

title:
  layout: masthead
  rule: { position: below, weight: "3pt", color: accent }
  byline: { position: above, case: smallcaps }

headings:
  h1: { scale: 1.15, case: smallcaps, color: accent, rule: { position: above, weight: "0.5pt" } }
  h2: { scale: 1.00, weight: bold, style: italic, color: text }

paragraph:
  indent: "1em"
  spacing: "0pt"
  indent_after_heading: false
  drop_cap: { lines: 3, color: accent }

figure:
  style: ruled
  caption: { size: 0.78, family: heading, color: muted, label_style: smallcaps }

highlight: none
```

Of the tokens above, `[impl]` today: fonts, sizes, colours, `columns`,
heading scales, `highlight`. Everything else awaits the template port.
That gap is the current work.
