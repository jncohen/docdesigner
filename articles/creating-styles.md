# Creating a style

A docdesigner style is one file, `format.yml`, that lists design
decisions as tokens: `color.accent`, `typography.base_size`,
`headings.h1.scale`, and so on. The engine turns those tokens into
LaTeX. You never write LaTeX, and a style cannot break a document: every
token is checked against a schema with fixed types, bounds and named
steps.

This guide assumes you design a style with an AI assistant. You decide
what the style is for and judge every page. The assistant writes the
file, checks it and renders it. The split plays to each side: an
assistant writes valid tokens quickly once it has the vocabulary, and a
person sees at a glance whether a page works.

The guide covers the workflow, the context to give the assistant, the
rules for setting tokens, the principles that separate a good style from
a merely valid one, and markup styles for drafts. It closes with the
full token reference. Everything after the workflow is background for
both of you: for you, to judge the result; for the assistant, to produce
it.

## The workflow

1.  **Write a context folder** with
    [`designer_ai_context()`](https://jncohen.github.io/docdesigner/reference/designer_ai_context.md).
    It gathers the files that make an assistant accurate; the next
    section lists them.
2.  **Give the folder to the assistant**, `AI-INSTRUCTIONS.md` first.
3.  **Say what the style is for**: the kind of document, who reads it
    and how, and anything it should resemble. Pictures of pages you
    admire do more than adjectives.
4.  **The assistant drafts.** It copies the nearest shipped style,
    changes only the tokens that differ, writes a reason beside each,
    then validates and renders with the folder’s `check-style.R`.
5.  **You look at the pages** and say what is wrong. Repeat 4 and 5.
6.  **Read the finished `format.yml`.** Every token should carry a
    reason you agree with. Then share it, as a folder or inside a set.

``` r

# 1. The context folder, built around the style you will start from.
#    Name two or three other styles to show the assistant the range.
designer_ai_context("my-context", from = "policy", examples = c("economist", "minimal"))
```

A first message to the assistant can be as short as this:

> Read `AI-INSTRUCTIONS.md` and the files beside it. I want a style for
> two-page briefs on housing policy, read by city officials on paper and
> on screen. It should feel authoritative but not academic. I’ve
> attached three pages from briefs I like. Start from `policy`.

The assistant’s loop runs four commands. You can run them yourself at
any point:

``` r

# Copy the nearest shipped style. complete = FALSE copies only the tokens
# that style declares, so the draft stays short and every line is a choice.
designer_new_style("my-brief", from = "policy", path = ".", complete = FALSE)

# Errors must be fixed. Warnings flag risky combinations.
designer_validate_style("my-brief")

# Render any document with the draft by pointing at its folder.
rmarkdown::render("paper.Rmd", output_format = docdesigner::pdf(style = "my-brief"))
```

``` sh
# Or all three steps, plus an image of every page, in one:
Rscript my-context/check-style.R my-brief
```

Inside a document’s YAML header the style is named the same way:

``` yaml
output:
  docdesigner::pdf:
    style: "path/to/my-brief"
    title_layout: page        # optional: override the style's title.layout
```

The folder’s `specimen.md` shows every element a style sets in a few
pages. Before you finish, also render a document that looks like your
real work: figures, tables of different shapes, a long title, an
abstract, footnotes, a block quote and references.
`examples/gallery-document.Rmd` in the source repository carries all of
these.

## What to give the assistant

An assistant left to its memory writes YAML that resembles a style but
names tokens and values docdesigner does not have. These files fix that.
All of them except the last two come from
[`designer_ai_context()`](https://jncohen.github.io/docdesigner/reference/designer_ai_context.md),
generated from the installed package, so they match the version you
render with. Write the folder again after updating docdesigner.

| File | Also available as | What it gives the assistant |
|:---|:---|:---|
| `AI-INSTRUCTIONS.md` |  | How to work: what to ask you first, the loop, the validator’s cross-token rules, and the mistakes assistants make most. Load it first. |
| `brief.md` | [`designer_design_brief()`](https://jncohen.github.io/docdesigner/reference/designer_design_brief.md) | The hard constraints: colour roles, fonts, named steps, the type scale, title layouts, markup styles. |
| `tokens.csv` | [`designer_tokens()`](https://jncohen.github.io/docdesigner/reference/designer_tokens.md) | Every key that exists, with its allowed values, default and status. The commonest failure is an invented key. |
| `examples/*.yml` | [`designer_new_style()`](https://jncohen.github.io/docdesigner/reference/designer_new_style.md) | Shipped styles with their authors’ comments. An assistant imitates what it sees, so show it reasoned files. |
| `specimen.md` |  | A test document with every element a style sets. |
| `check-style.R` |  | The loop as one script: validate, render, write each page as a PNG. Needs the pdftools package for the images. |
| This article | [the website](https://jncohen.github.io/docdesigner/articles/creating-styles.html) | What makes a style good, not just valid. The brief says what is allowed; this says what works. |
| Your model pages |  | Screenshots or PDF pages of what the style should resemble. The single most useful input when imitating a publication. |

How you hand these over depends on the assistant.

- **An assistant that runs code and reads images**, such as a coding
  assistant opened on the folder, runs `check-style.R` itself and looks
  at the pages before showing them to you. Your part is to judge.
- **A chat assistant without tools** gets the files as attachments and
  writes `format.yml`. You run the script, paste back the validator’s
  output, and attach the page images. It is slower, and it works.

Either way, hold the assistant to the page. It will describe a draft as
clean, balanced or readable; only a render shows whether it is (see
*Only the page is evidence*, below). Ask for the images, and look at
every one.

To imitate a design made in a visual tool rather than describe it,
export the design as one standalone HTML page and translate it with
[`designer_import_html()`](https://jncohen.github.io/docdesigner/reference/designer_import_html.md).
The brief’s last section says what the import reads and what it leaves
to you.

## Setting tokens

### The format

Keys are flat and dotted, one per line. Comments are encouraged; record
*why* a value was chosen, not what it is.

``` yaml
id: my-brief                 # required; lowercase letters, digits, hyphens
label: "My Brief"            # required; how the style is listed
description: >               # recommended; what it is for and what it imitates
  A two-page policy brief with a sans kicker and a tinted callout.
inherits: policy             # optional; see below

color.accent: "#0B5E55"
typography.base_size: 10.5pt
title.layout: page
callout.style: boxed
```

Each key appears once. To change a value the scaffold already declares,
edit that line; adding the same key again further down is a YAML error.

### Six rules

1.  **Declare only what differs.** Every token has a default. A style
    that restates defaults freezes them: when the engine’s default
    improves, your style will not follow.
2.  **Hex colours live only under `color.*`.** Everywhere else a token
    names a colour *role*: `accent`, `accent2`, `text`, `muted`, `rule`,
    `background`, `code_bg` or `knockout`. Change the palette in one
    place and every element that uses a role follows. Quote hex values
    (`"#0B5E55"`); unquoted, YAML can read some of them as numbers.
3.  **Lengths are named steps, not dimensions.** `quote.indent: md`, not
    `quote.indent: 1em`. The steps are fixed scales (space, indent, rule
    weight, gutter, margin, width), so styles stay consistent with one
    another and cannot produce invalid LaTeX. Margins are the exception:
    `page.margins.*` take inches, because a page design needs asymmetric
    margins.
4.  **Sizes are multiples.** Heading, title, caption and table sizes are
    set relative to `typography.base_size`, so changing the body size
    rescales the whole hierarchy.
5.  **Use `inherits` for families of styles.** `inherits: policy` starts
    from policy’s declared tokens and applies yours on top. Chains
    resolve from the root, and a cycle or missing parent is an error.
6.  **Check a token’s status before relying on it.** `impl` tokens
    render. `new` tokens validate and are ignored until the engine
    implements them;
    [`designer_validate_style()`](https://jncohen.github.io/docdesigner/reference/designer_validate_style.md)
    lists them. `deprecated` tokens still work and name their
    replacement.

The validator also applies cross-token rules:

| Rule | Meaning |
|:---|:---|
| indent-and-spacing | A style should separate paragraphs by indent OR by vertical space, not both. |
| dropcap-twocolumn | lettrine drop caps are unreliable in two-column bodies. |
| span-columns-single | figure.span_columns has no effect in a single-column body. |
| markup-no-columns | Margin markup (line and paragraph numbers, flags, changebars) needs a single-column page. |
| margins-override | page.margins overrides page.margin; setting both is redundant. |
| margin-cap | No margin wider than 1.25in. The thesis title layout is exempt (college binding margins). |
| bar-and-rule | A heading bar already carries its own edge; a rule on the same level reads as an error. |

### Structure versus look

Two kinds of decision go into a page, and docdesigner keeps them apart.

**Structure** is what goes where. `title.layout` is the main structural
token: `header` sets the title block at the head of the first page, and
`page` gives the title and abstract a page of their own. `page.columns`
(one or two) is the other. Because structure varies by occasion as much
as by style, the title layout can also be chosen per document with
`pdf(title_layout = "page")`.

**Look** is everything else: faces, sizes, colours, rules, spacing, and
how each element (title, abstract, headings, quotes, callouts, tables,
captions, running heads) is treated. Look tokens apply in every layout.
A centred small-caps title with a short rule is centred, small-caps and
ruled whether it opens page 1 or stands on a title page.

Design the look once and check it in both layouts.

### Block elements

Three elements set text apart from the body, and a style should make
them distinguishable at a glance.

| Element | Written as | Tokens | Use it for |
|:---|:---|:---|:---|
| Block quote | `> text` | `quote.*` | Someone else’s words |
| Callout | `::: {.callout title="..."}` | `callout.*` | The author’s own key point |
| Abstract | `abstract:` in the YAML header | `title.abstract.*` | The summary |

`callout.style` takes `filled` (a tinted panel), `ruled` (a bar at the
left), `boxed` (a border round a tint) or `plain` (indented text under a
title). If the style’s quotes already carry a left bar, do not give
callouts one too: readers will take the two for the same thing. The
shipped styles show the pattern. atlantic, economist, modern and nature
rule their quotes and fill their callouts; methods, which boxes its
abstract, boxes its callouts to match.

## Principles of good style

A style passes validation the moment its keys and values are legal.
These principles decide whether it is any good. Each comes with the
check that tells you whether you have met it.

### Measure: 45 to 75 characters per line

Line length governs reading comfort more than any other single choice.
Below about 45 characters the eye jumps lines too often; above about 75
it loses its place on the return sweep. Aim for 60 to 72 in a single
column and 40 to 55 in each of two.

Estimate it before you render. For a typical book serif, a line holds
about

``` math
\text{characters} \approx \frac{\text{text width in points}}{0.47 \times \text{body size in points}}
```

An 8.5-inch page with 1.85-inch side margins leaves 4.8 inches (346 pt);
at 10.5 pt that is about 70 characters. Then count a few full lines on
the rendered page.

Wide margins look generous on screen and wasteful in print. If a
comfortable measure leaves the margins too wide, raise the body size by
half a point, or use two columns, before you shrink the margins.

### Leading: open enough to track, tight enough to hold

`typography.line_height` multiplies LaTeX’s own leading, which is
already about 1.2 times the type size. Values from 1.1 to 1.25 suit most
text faces. Open the leading as the measure lengthens; tighten it for
short lines and large type. Display text (titles, headings, captions,
tables, footnotes) keeps its own spacing whatever this token says.

### Hierarchy: few signals, used consistently

A reader should be able to tell a section from a subsection without
reading the words. Use the fewest signals that achieve it: size, weight,
case, colour, rules, numbering. Two or three distinct heading levels are
enough for almost any paper.

- Keep the size steps modest. `h1` at 1.3 to 1.5 times the body, `h2` at
  1.1 to 1.2, `h3` at the body size. Large jumps look like a poster.
- Change one signal per level where possible. If `h2` is bold, `h3` can
  be bold italic or small capitals at the same size.
- Do not repeat a signal for two different jobs. If the accent colour
  marks headings, a link in the same colour reads as a heading fragment.

### Colour: one accent, used sparingly

Most good document designs use near-black text, one grey for secondary
material, and a single accent. The accent carries meaning only while it
is rare: put it on the title rule, the section numbers or headings,
links, and callouts, and nowhere else. A second accent (`color.accent2`)
is for data graphics that need two series, not for decoration.

Check contrast. Body text needs a contrast ratio of at least 4.5 to 1
against the page (WCAG AA), and so does any coloured text a reader must
read, such as captions in `muted` or links in `accent`. A light grey
that looks refined on a screen often fails on paper.

``` r

contrast <- function(fg, bg = "#FFFFFF") {
  lum <- function(hex) {
    c <- grDevices::col2rgb(hex)[, 1] / 255
    c <- ifelse(c <= 0.03928, c / 12.92, ((c + 0.055) / 1.055)^2.4)
    sum(c(0.2126, 0.7152, 0.0722) * c)
  }
  l <- sort(c(lum(fg), lum(bg)), decreasing = TRUE)
  round((l[1] + 0.05) / (l[2] + 0.05), 1)
}
pal <- designer_style("modern")$color
sapply(pal[c("text", "accent", "muted")], contrast)
#>   text accent  muted 
#>   17.4    9.0    5.3
```

### Paragraphs: indent or space, never both

Separate paragraphs with a first-line indent (`paragraph.indent`) or
with vertical space (`paragraph.spacing`), not both. Indents suit
continuous argument and long reading; space suits reports that a reader
scans. The validator warns if you set both.

### Tables: let the data carry the structure

Horizontal rules at the top, under the header and at the bottom
(`table.style: booktabs`) suit nearly every research table. Vertical
rules and full grids add noise without helping the eye along a row. Set
tables slightly smaller than the body (`table.size` about 0.9) and keep
their leading close (`table.row_stretch` 1.1 to 1.25). Right-align
numbers; that is the author’s job (in
[`knitr::kable`](https://rdrr.io/pkg/knitr/man/kable.html),
`align = "lrr"`), not the style’s.

### Faces: open, legible, and few

Use one family for text and at most one more for contrast, typically a
sans for labels, kickers and table headers (`typography.label`). Never
name a proprietary face: a style that imitates a publication uses an
open substitute with similar proportions and records the original in
`description`. The bundled families are Source Serif 4, EB Garamond,
XITS and Fira Code; a style can ship others under
`fonts.<Family>.<face>`.

### Fit the occasion

A style is for a kind of document read by a kind of reader. A journal
manuscript under review wants plain structure, a header title, wide
spacing (`pdf(doublespace = TRUE)`) and no ornament. A policy brief
wants a kicker, a strong title, a callout for the finding, and a page a
busy reader can scan. A long essay wants a book face, indented
paragraphs, and quiet headings. Decide who reads the document and how,
then choose.

### Only the page is evidence

A token can be correct in `format.yml`, correct in the resolved spec,
and still wrong on the page. Look at every page of a realistic render,
in both title layouts, before you share a style. In particular check:

- a two-line title, and a long author line;
- a table wider than half the measure, in a two-column style;
- the last page, which often carries only a few references;
- the first page of the body when `title.layout` is `page`.

## Markup styles

Most styles dress a finished document for a reader. A markup style
dresses a draft for its author: it is printed to be read slowly and
written on, and every mark made on the page has to lead back to a spot
in the source. The shipped `review` style is the example, and the right
starting point:

``` r

designer_ai_context("my-context", from = "review")
```

The `markup.*` tokens make a style a markup style. Each is off by
default, so no publication style shows them.

| Token | Default | Effect |
|:---|:---|:---|
| `markup.line_numbers` | 0 | Number every nth line in the outer margin, restarting on each page. 0: off. |
| `markup.paragraph_numbers` | FALSE | Number body paragraphs continuously in the inner margin (¶n), so a note made on one printout finds its paragraph in the next. |
| `markup.flags` | FALSE | \[\[TODO\]\], \[\[CITE\]\], \[\[WEAK\]\], \[\[CUT\]\], \[\[CHECK\]\], \[\[FIX\]\], \[\[VERIFY\]\], \[\[FACT\]\], \[\[RECOMPUTE\]\] and \[\[QUESTION\]\] in the text print as margin tags, with \[\[V\]\], \[\[C\]\], \[\[F\]\], \[\[N\]\] and \[\[Q\]\] as short forms; \[\[TAG: words\]\] also keeps the words inline in markup.flag_color. |
| `markup.flag_color` | accent | Colour role for margin tags and the words a tag keeps inline. |
| `markup.cite_keys` | FALSE | Print each citation’s bibliography key in small muted type after it. |
| `markup.map` | 0 | Open the body with a map of the argument: each heading to this depth, with its words and starting page. 0: off. |
| `markup.claim_check` | FALSE | Flag \[\[LABEL?\]\] beside a heading of fewer than four words: a label where a claim belongs. Advisory. |
| `markup.changebars` | FALSE | Rule beside each paragraph changed since a reference version: pdf(changes_since = ), else the latest git tag. |
| `markup.floats` | TRUE | false: tables and figures stay exactly where they are written; nothing floats. |

A markup style answers to different rules from a publication style.

- **One column.** Line numbers, paragraph numbers, tags and changebars
  live in the margins. The validator warns when a markup style sets two
  columns.
- **A wide outer margin.** It is where the reader writes. Any `markup.*`
  token lifts the 1.25in margin cap, and `page.margins.outer` may go to
  3.5in; `review` uses 3in. One-sided pages (`page.twoside: false`) keep
  it on the right of every page.
- **Nothing floats.** With `markup.floats: false` a table or figure
  stays beside the text that discusses it, so a note about one finds the
  other.
- **Stable lines.** A short measure, open leading, ragged right and no
  hyphenation keep each line break, and so each line number, the same
  from one printout to the next.
- **The tags belong to the engine.** `[[V]]`, `[[C]]`, `[[TODO]]` and
  the rest are fixed; the README lists them. A style switches them on
  with `markup.flags` and colours them with `markup.flag_color`, but
  cannot add or rename one.

A writer can turn one feature off for one printout without a second
style: `pdf(style = "review", markup = list(line_numbers = 0))`.

When you check the page, check the marks as well as the text: two tags
on one line, a tag under a flagged heading, a changebar beside a table,
and line numbers on a page that opens with a figure.

## Sharing a style

The simplest way to share a style is the folder: anyone can render with
`pdf(style = "path/to/folder")`. To ship several styles together, put
them in a set: a folder holding `set.yml` and `styles/<id>/format.yml`
for each style. Fonts a style needs go in `styles/<id>/assets/fonts/` or
the set’s own `assets/fonts/`.

``` yaml
# set.yml
id: my-house
title: "My house styles"
version: 1.0.0
format_version: 2
styles: [my-brief, my-paper]
```

[`designer_install_set()`](https://jncohen.github.io/docdesigner/reference/designer_install_set.md)
installs a set from a GitHub repository, and
[`designer_update_sets()`](https://jncohen.github.io/docdesigner/reference/designer_update_sets.md)
refreshes installed sets. A style in an installed set with the same id
as a core style takes precedence, with a warning.

## Token reference

Every token the engine knows, generated from the schema when this page
was built. **Allowed** gives the legal values: a list of names, a
numeric range, a colour role, or a hex colour. **Status** says whether
the engine renders it today.

### `identity`

| Token | Allowed | Default | Status | Notes |
|:---|:---|:---|:---|:---|
| `id` |  |  | impl | Unique style id. Keys resolution, not the folder name. |
| `label` |  |  | impl | Human-readable name. |
| `description` |  |  | impl | One line. Note the original typefaces here if imitating a publication. |
| `inherits` |  |  | impl | Style id to inherit from. Resolves a full chain, root-first. |

### `page`

| Token | Allowed | Default | Status | Notes |
|:---|:---|:---|:---|:---|
| `page.papersize` | letter &#124; a4 | letter | impl |  |
| `page.margin` | narrow &#124; normal &#124; wide | normal | impl | Shorthand for all four sides. |
| `page.margins.top` | 0.4 to 2 |  | impl | Overrides page.margin when set. |
| `page.margins.bottom` | 0.4 to 2 |  | impl |  |
| `page.margins.inner` | 0.4 to 2 |  | impl | Binding edge when twoside; else left. |
| `page.margins.outer` | 0.4 to 3.5 |  | impl | Over 1.25in only for a markup style (markup.\*), whose outer margin is a workspace for handwritten notes. |
| `page.twoside` | true &#124; false | FALSE | impl | Mirror margins, alternate running heads. |
| `page.columns` | 1 &#124; 2 | 1 | impl |  |
| `page.gutter` | sm &#124; md &#124; lg |  | impl | Space between columns under columns: 2. Unset: LaTeX’s 10pt. |
| `page.column_rule` | true &#124; false | FALSE | impl | Hairline between columns under columns: 2. |

### `typography`

| Token | Allowed | Default | Status | Notes |
|:---|:---|:---|:---|:---|
| `typography.body` |  | Source Serif 4 | impl |  |
| `typography.heading` |  | Source Serif 4 | impl |  |
| `typography.mono` |  | Fira Code | impl |  |
| `typography.display` |  |  | impl | Display face for titles and headings that set family: display. Unset: the heading face. |
| `typography.label` |  |  | impl | Sans furniture face for kickers, callout titles, table headers. Loaded by name via ; falls back to body if the named font is absent. |
| `typography.base_size` | 8pt &#124; 8.5pt &#124; 9pt &#124; 9.5pt &#124; 10pt &#124; 10.5pt &#124; 11pt &#124; 11.5pt &#124; 12pt | 10pt | impl |  |
| `typography.line_height` | 1 to 2 | 1.3 | impl |  |
| `typography.mono_scale` | 0.6 to 1 | 0.82 | impl |  |
| `typography.numbers` | lining &#124; oldstyle | lining | impl |  |
| `typography.justification` | justified &#124; ragged-right | justified | impl |  |
| `typography.hyphenation` | true &#124; false | TRUE | impl | false: no word is broken at a line end. |
| `typography.microtype` | true &#124; false | TRUE | impl |  |

### `color`

| Token | Allowed | Default | Status | Notes |
|:---|:---|:---|:---|:---|
| `color.accent` | 6-digit hex | 333333 | impl |  |
| `color.accent2` | 6-digit hex |  | impl |  |
| `color.text` | 6-digit hex | 000000 | impl |  |
| `color.muted` | 6-digit hex | 5B6470 | impl |  |
| `color.rule` | 6-digit hex | 333333 | impl |  |
| `color.background` | 6-digit hex |  | impl | A fill role, for panels such as a boxed abstract. |
| `color.code_bg` | 6-digit hex |  | impl |  |
| `color.knockout` | 6-digit hex | FFFFFF | impl | Text drawn on a filled bar or band. |

### `headings`

| Token | Allowed | Default | Status | Notes |
|:---|:---|:---|:---|:---|
| `headings.number_sections` | true &#124; false | FALSE | impl |  |
| `headings.numbering` | arabic &#124; roman &#124; alpha | arabic | impl | How h1 numbers are written when number_sections is true: 1, I or A. |
| `headings.run_in` | h2 &#124; h3 &#124; h4 |  | impl | Levels typeset run-in with the paragraph. |
| `headings.h1.family` | body &#124; heading &#124; display &#124; mono | heading | impl |  |
| `headings.h2.family` | body &#124; heading &#124; display &#124; mono | heading | impl |  |
| `headings.h3.family` | body &#124; heading &#124; display &#124; mono | heading | impl |  |
| `headings.h4.family` | body &#124; heading &#124; display &#124; mono | heading | impl |  |
| `headings.h1.scale` | 0.5 to 4 | 1.35 | impl |  |
| `headings.h2.scale` | 0.5 to 4 | 1.15 | impl |  |
| `headings.h3.scale` | 0.5 to 4 | 1 | impl |  |
| `headings.h4.scale` | 0.5 to 4 | 1 | impl |  |
| `headings.h1.weight` | light &#124; regular &#124; bold | bold | impl |  |
| `headings.h2.weight` | light &#124; regular &#124; bold | bold | impl |  |
| `headings.h3.weight` | light &#124; regular &#124; bold | bold | impl |  |
| `headings.h4.weight` | light &#124; regular &#124; bold | regular | impl |  |
| `headings.h1.style` | normal &#124; italic | normal | impl |  |
| `headings.h2.style` | normal &#124; italic | normal | impl |  |
| `headings.h3.style` | normal &#124; italic | normal | impl |  |
| `headings.h4.style` | normal &#124; italic | italic | impl |  |
| `headings.h1.case` | none &#124; upper &#124; lower &#124; smallcaps | none | impl |  |
| `headings.h2.case` | none &#124; upper &#124; lower &#124; smallcaps | none | impl |  |
| `headings.h3.case` | none &#124; upper &#124; lower &#124; smallcaps | none | impl |  |
| `headings.h4.case` | none &#124; upper &#124; lower &#124; smallcaps | none | impl |  |
| `headings.h1.color` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout | accent | impl |  |
| `headings.h2.color` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout | accent | impl |  |
| `headings.h3.color` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout | accent | impl |  |
| `headings.h4.color` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout | accent | impl |  |
| `headings.h1.align` | left &#124; center &#124; right | left | impl |  |
| `headings.h2.align` | left &#124; center &#124; right | left | impl |  |
| `headings.h3.align` | left &#124; center &#124; right | left | impl |  |
| `headings.h4.align` | left &#124; center &#124; right | left | impl |  |
| `headings.h1.space_before` | none &#124; xs &#124; sm &#124; md &#124; lg &#124; xl | lg | impl |  |
| `headings.h2.space_before` | none &#124; xs &#124; sm &#124; md &#124; lg &#124; xl | md | impl |  |
| `headings.h3.space_before` | none &#124; xs &#124; sm &#124; md &#124; lg &#124; xl | md | impl |  |
| `headings.h4.space_before` | none &#124; xs &#124; sm &#124; md &#124; lg &#124; xl | md | impl |  |
| `headings.h1.space_after` | none &#124; xs &#124; sm &#124; md &#124; lg &#124; xl | sm | impl |  |
| `headings.h2.space_after` | none &#124; xs &#124; sm &#124; md &#124; lg &#124; xl | xs | impl |  |
| `headings.h3.space_after` | none &#124; xs &#124; sm &#124; md &#124; lg &#124; xl | xs | impl |  |
| `headings.h4.space_after` | none &#124; xs &#124; sm &#124; md &#124; lg &#124; xl | xs | impl |  |
| `headings.h1.rule.position` | above &#124; below &#124; none | none | impl | above: a rule over the heading. below: under it. |
| `headings.h2.rule.position` | above &#124; below &#124; none | none | impl | above: a rule over the heading. below: under it. |
| `headings.h3.rule.position` | above &#124; below &#124; none | none | impl | above: a rule over the heading. below: under it. |
| `headings.h4.rule.position` | above &#124; below &#124; none | none | impl |  |
| `headings.h1.rule.weight` | hairline &#124; thin &#124; medium &#124; thick &#124; heavy | medium | impl |  |
| `headings.h2.rule.weight` | hairline &#124; thin &#124; medium &#124; thick &#124; heavy | medium | impl |  |
| `headings.h3.rule.weight` | hairline &#124; thin &#124; medium &#124; thick &#124; heavy | medium | impl |  |
| `headings.h4.rule.weight` | hairline &#124; thin &#124; medium &#124; thick &#124; heavy | medium | impl |  |
| `headings.h1.rule.color` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout | rule | impl |  |
| `headings.h2.rule.color` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout | rule | impl |  |
| `headings.h3.rule.color` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout | rule | impl |  |
| `headings.h4.rule.color` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout | rule | impl |  |
| `headings.h1.bar.fill` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout |  | impl | Set to render the heading as a filled bar across the measure. |
| `headings.h2.bar.fill` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout |  | impl | Set to render the heading as a filled bar across the measure. |
| `headings.h3.bar.fill` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout |  | impl | Set to render the heading as a filled bar across the measure. |
| `headings.h4.bar.fill` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout |  | impl | Set to render the heading as a filled bar across the measure. |
| `headings.h1.new_page` | true &#124; false | FALSE | impl | Start every heading of this level on a new page (thesis chapters). |
| `headings.h2.new_page` | true &#124; false | FALSE | impl | Start every heading of this level on a new page (thesis chapters). |
| `headings.h3.new_page` | true &#124; false | FALSE | impl | Start every heading of this level on a new page (thesis chapters). |
| `headings.h4.new_page` | true &#124; false | FALSE | impl | Start every heading of this level on a new page (thesis chapters). |
| `headings.h1.bar.text` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout | knockout | impl |  |
| `headings.h2.bar.text` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout | knockout | impl |  |
| `headings.h3.bar.text` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout | knockout | impl |  |
| `headings.h4.bar.text` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout | knockout | impl |  |

### `title`

| Token | Allowed | Default | Status | Notes |
|:---|:---|:---|:---|:---|
| `title.layout` | header &#124; page &#124; thesis | header | impl | Structure, not look. header: the title block sits at the top of the first body page. page: the title block and abstract take a page of their own and the body starts on the next. thesis: a thesis title page (degree statement, optional signature block), an optional copyright page, then front matter (contents, acknowledgements, abstract) before the body. Alignment, case, rules, kicker, subtitle and abstract treatment are separate tokens and apply to every layout. pdf(title_layout = ) overrides it per document. |
| `title.page.offset` | 0 to 0.4 | 0.25 | impl | layout: page only. Space above the title block, as a fraction of the text height. The default sets the title about a third of the way down a letter page. |
| `title.page.abstract` | title &#124; next | title | impl | layout: page only. title: the abstract sits on the title page. next: it opens the first body page. |
| `title.align` | left &#124; center | left | impl |  |
| `title.scale` | 1 to 5 | 2.6 | impl |  |
| `title.color` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout | text | impl | Near-black is what every design-sets mockup specifies; accent titles are the exception, not the rule. |
| `title.family` | body &#124; heading &#124; display | heading | impl |  |
| `title.case` | none &#124; upper &#124; smallcaps | none | impl |  |
| `title.weight` | bold &#124; regular | bold | impl | regular is LaTeX’s own unbolded title. |
| `title.rule.position` | above &#124; below &#124; both &#124; none | none | impl | above: over the kicker and title. below: under the title block. both: both. |
| `title.rule.weight` | hairline &#124; thin &#124; medium &#124; thick &#124; heavy | thick | impl |  |
| `title.rule.length` | 0.3 to 8 |  | impl | Rule width in inches; omit for the full measure. |
| `title.rule.color` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout | rule | impl |  |
| `title.page_break_after` | true &#124; false | FALSE | deprecated | Superseded by title.layout: page, which it now maps to. |
| `title.kicker.text` |  |  | impl | Eyebrow label above the title. Unset = no kicker. |
| `title.kicker.color` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout | accent | impl |  |
| `title.kicker.case` | none &#124; upper &#124; lower &#124; smallcaps | upper | impl |  |
| `title.kicker.scale` | 0.5 to 1.5 | 0.8 | impl | Multiple of typography.base_size. |
| `title.kicker.font` | label &#124; heading &#124; body | label | impl |  |
| `title.subtitle.scale` | 0.8 to 2.5 | 1.3 | impl |  |
| `title.subtitle.style` | normal &#124; italic | italic | impl |  |
| `title.subtitle.color` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout | muted | impl |  |
| `title.byline.position` | above &#124; below | below | impl |  |
| `title.byline.case` | none &#124; upper &#124; smallcaps | none | impl |  |
| `title.byline.color` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout | muted | impl |  |
| `title.date.show` | true &#124; false | TRUE | impl |  |
| `title.date.color` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout | muted | impl |  |
| `title.abstract.width` | half &#124; text &#124; full |  | impl | Narrow the abstract to this width, centred. Overrides indent. |
| `title.abstract.size` | 0.7 to 1.2 | 0.95 | impl |  |
| `title.abstract.label` |  | Abstract | impl |  |
| `title.abstract.rule` | true &#124; false | FALSE | impl |  |
| `title.abstract.show` | true &#124; false | TRUE | impl | false suppresses it entirely — a magazine feature has a deck, not an abstract. |
| `title.abstract.label_style` | heading &#124; runin &#124; none | heading | impl | heading: centred bold over the block. runin: small-caps label inline with the first line. none: no label. |
| `title.abstract.indent` | none &#124; sm &#124; md &#124; lg | none | impl | Inset from BOTH margins. |
| `title.abstract.weight` | regular &#124; bold | regular | impl | bold gives a standfirst rather than an abstract. |
| `title.abstract.color` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout | text | impl |  |
| `title.abstract.box` | true &#124; false | FALSE | impl | Wrap the abstract in a filled/bordered panel. |
| `title.abstract.background` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout |  | impl | Panel fill when box is true; defaults to code_bg. |
| `title.abstract.label_color` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout | text | impl |  |
| `title.abstract.label_align` | left &#124; center &#124; right | center | impl |  |
| `title.abstract.label_case` | none &#124; upper &#124; smallcaps | none | impl |  |
| `title.keywords.show` | true &#124; false | TRUE | impl | Print the document’s keywords: field under the abstract. |
| `title.keywords.label` |  | Keywords | impl |  |
| `title.warning.auto` | true &#124; false | FALSE | impl | With no warning: in the document, print a stamped draft line (version, date, do not circulate). warning: auto does the same in any style. |

### `paragraph`

| Token | Allowed | Default | Status | Notes |
|:---|:---|:---|:---|:---|
| `paragraph.indent` | none &#124; sm &#124; md &#124; lg | none | impl |  |
| `paragraph.spacing` | none &#124; xs &#124; sm &#124; md &#124; lg &#124; xl | sm | impl |  |
| `paragraph.indent_after_heading` | true &#124; false | FALSE | impl |  |
| `paragraph.drop_cap.lines` | 2 to 4 |  | impl | Set to enable a drop cap. |
| `paragraph.drop_cap.color` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout | accent | impl | lettrine; unreliable under columns: 2. |

### `figure`

| Token | Allowed | Default | Status | Notes |
|:---|:---|:---|:---|:---|
| `figure.style` | plain &#124; ruled &#124; inset | plain | impl | ruled: rules above and below. inset: a light frame. |
| `figure.width` | half &#124; text &#124; full |  | impl | Default image width. A width set in the document (out.width) wins. |
| `figure.placement` | here &#124; top &#124; bottom &#124; page |  | impl | Preferred float position. Unset: LaTeX chooses (here, top, bottom or page). |
| `figure.caption.position` | above &#124; below | below | impl |  |
| `figure.caption.family` | body &#124; heading &#124; mono | body | impl |  |
| `figure.caption.size` | 0.6 to 1 | 0.85 | impl |  |
| `figure.caption.align` | left &#124; center | left | impl |  |
| `figure.caption.color` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout | muted | impl |  |
| `figure.caption.label_style` | bold &#124; italic &#124; smallcaps &#124; plain &#124; none | bold | impl | plain: an unstyled “Figure 1:” label, as LaTeX sets it. none: no label. |

### `table`

| Token | Allowed | Default | Status | Notes |
|:---|:---|:---|:---|:---|
| `table.style` | booktabs &#124; grid &#124; zebra &#124; minimal | booktabs | impl | booktabs: three rules. grid: every cell ruled. zebra: shaded alternate rows. minimal: one rule under the header. |
| `table.row_stretch` | 1 to 2 | 1.2 | impl |  |
| `table.size` | 0.7 to 1.1 | 0.9 | impl |  |
| `table.zebra_color` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout |  | impl |  |
| `table.header.weight` | regular &#124; bold | bold | impl |  |
| `table.header.case` | none &#124; upper &#124; smallcaps | none | impl |  |
| `table.header.rule_below` | true &#124; false | TRUE | impl |  |
| `table.caption.position` | above &#124; below | above | impl | Only `above` is achievable: pandoc renders tables as longtable, which is not a float, so the caption cannot be relocated from the preamble. `above` is pandoc’s own default and every shipped style wants it. |

### `code`

| Token | Allowed | Default | Status | Notes |
|:---|:---|:---|:---|:---|
| `code.highlight` | pygments &#124; tango &#124; espresso &#124; zenburn &#124; kate &#124; monochrome &#124; breezedark &#124; haddock &#124; none | tango | impl |  |
| `code.background` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout |  | impl |  |
| `code.border` | true &#124; false | FALSE | impl |  |
| `code.line_numbers` | true &#124; false | FALSE | impl |  |

### `quote`

| Token | Allowed | Default | Status | Notes |
|:---|:---|:---|:---|:---|
| `quote.indent` | none &#124; sm &#124; md &#124; lg | md | impl |  |
| `quote.style` | normal &#124; italic | normal | impl |  |
| `quote.color` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout | text | impl |  |
| `quote.rule` | true &#124; false | FALSE | impl | Vertical accent rule at the left. |

### `callout`

| Token | Allowed | Default | Status | Notes |
|:---|:---|:---|:---|:---|
| `callout.style` | filled &#124; ruled &#124; boxed &#124; plain | filled | impl | filled: tinted panel, no border. ruled: a left bar, no fill. boxed: a border round a tinted panel. plain: indented text with the title, no ornament. |
| `callout.color` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout | accent | impl | The bar, border and title colour, and the base of the fill tint. |
| `callout.tint` | 0 to 40 | 8 | impl | Fill strength: percent of callout.color mixed into white. filled and boxed only; 0 = no fill. |
| `callout.rule` | hairline &#124; thin &#124; medium &#124; thick &#124; heavy | thick | impl | ruled: the bar. boxed: the border, where hairline or thin is usual. |
| `callout.size` | 0.8 to 1.1 | 0.95 | impl | Text size, as a multiple of typography.base_size. |
| `callout.title.case` | none &#124; upper &#124; smallcaps | upper | impl |  |
| `callout.title.color` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout |  | impl | Defaults to callout.color. |

### `footnotes`

| Token                 | Allowed              | Default | Status | Notes |
|:----------------------|:---------------------|:--------|:-------|:------|
| `footnotes.size`      | 0.6 to 1             | 0.8     | impl   |       |
| `footnotes.numbering` | arabic &#124; symbol | arabic  | impl   |       |

### `header_footer`

| Token | Allowed | Default | Status | Notes |
|:---|:---|:---|:---|:---|
| `header_footer.header.left` | none &#124; title &#124; runningtitle &#124; author &#124; surname &#124; section &#124; page &#124; folio &#124; stamp | none | impl |  |
| `header_footer.header.center` | none &#124; title &#124; runningtitle &#124; author &#124; surname &#124; section &#124; page &#124; folio &#124; stamp | none | impl |  |
| `header_footer.header.right` | none &#124; title &#124; runningtitle &#124; author &#124; surname &#124; section &#124; page &#124; folio &#124; stamp | none | impl |  |
| `header_footer.header.rule` | true &#124; false | FALSE | impl |  |
| `header_footer.header.fill` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout |  | impl | Fill the running head with a full-bleed colour band spanning the whole paper width, not just the text block. The Economist flag and a government masthead. Suppresses header.rule, which a filled band does not want. |
| `header_footer.header.bleed` | true &#124; false | TRUE | impl | With header.fill: true runs the band to the paper edges; false keeps it to the text measure, aligned with the body. |
| `header_footer.header.color` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout |  | impl | Ink used inside the running head. Unset: muted for a plain head, text inside a band. With header.fill set this is the knockout colour – white-on-red is fill: accent, color: knockout. |
| `header_footer.footer.color` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout |  | impl | Ink used in the running foot. Unset: muted. |
| `header_footer.footer.left` | none &#124; title &#124; runningtitle &#124; author &#124; surname &#124; section &#124; page &#124; folio &#124; stamp | none | impl |  |
| `header_footer.footer.center` | none &#124; title &#124; runningtitle &#124; author &#124; surname &#124; section &#124; page &#124; folio &#124; stamp | none | impl |  |
| `header_footer.footer.right` | none &#124; title &#124; runningtitle &#124; author &#124; surname &#124; section &#124; page &#124; folio &#124; stamp | page | impl |  |
| `header_footer.footer.rule` | true &#124; false | TRUE | impl |  |
| `header_footer.alternate` | true &#124; false | FALSE | impl | Under page.twoside: mirror the left and right slots on even pages, so `right` is always the outer edge and `left` the inner. Slot values: folio is page/pages; stamp is the running title, version and date (see pdf(version = )). |
| `header_footer.section_chars` | 20 to 120 |  | impl | Set: `section` in a running head shows the first level-1 heading on the page, numbered and cut at this many characters. Unset: LaTeX’s own . |
| `header_footer.page_number.format` | arabic &#124; roman | arabic | impl | Front-matter page numbers in the thesis layout. roman: i, ii, …; the body starts again at 1. |
| `header_footer.first_page` | plain &#124; none &#124; header &#124; folio | plain | impl | plain: LaTeX default (centred footer folio, no running head on page 1). none: nothing on page 1. header: carry the running head onto page 1 too. folio: page 1 keeps the band and the folio slots, but drops the running title. |

### `links`

| Token | Allowed | Default | Status | Notes |
|:---|:---|:---|:---|:---|
| `links.color` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout | accent | impl |  |

### `thesis`

| Token | Allowed | Default | Status | Notes |
|:---|:---|:---|:---|:---|
| `thesis.statement` |  | A thesis submitted in partial fulfillment of the requirements for the degree of | impl |  |
| `thesis.degree` |  |  | impl | e.g. Master of Arts in Sociology. YAML: degree. |
| `thesis.institution` |  |  | impl | One line per line of text. YAML: institution. |
| `thesis.signatures` | true &#124; false | FALSE | impl | Signature lines for the committee on the title page. YAML: signatures. |

### `markup`

| Token | Allowed | Default | Status | Notes |
|:---|:---|:---|:---|:---|
| `markup.line_numbers` | 0 to 10 | 0 | impl | Number every nth line in the outer margin, restarting on each page. 0: off. |
| `markup.paragraph_numbers` | true &#124; false | FALSE | impl | Number body paragraphs continuously in the inner margin (¶n), so a note made on one printout finds its paragraph in the next. |
| `markup.flags` | true &#124; false | FALSE | impl | \[\[TODO\]\], \[\[CITE\]\], \[\[WEAK\]\], \[\[CUT\]\], \[\[CHECK\]\], \[\[FIX\]\], \[\[VERIFY\]\], \[\[FACT\]\], \[\[RECOMPUTE\]\] and \[\[QUESTION\]\] in the text print as margin tags, with \[\[V\]\], \[\[C\]\], \[\[F\]\], \[\[N\]\] and \[\[Q\]\] as short forms; \[\[TAG: words\]\] also keeps the words inline in markup.flag_color. |
| `markup.flag_color` | accent &#124; accent2 &#124; text &#124; muted &#124; rule &#124; background &#124; code_bg &#124; knockout | accent | impl | Colour role for margin tags and the words a tag keeps inline. |
| `markup.cite_keys` | true &#124; false | FALSE | impl | Print each citation’s bibliography key in small muted type after it. |
| `markup.map` | 0 to 3 | 0 | impl | Open the body with a map of the argument: each heading to this depth, with its words and starting page. 0: off. |
| `markup.claim_check` | true &#124; false | FALSE | impl | Flag \[\[LABEL?\]\] beside a heading of fewer than four words: a label where a claim belongs. Advisory. |
| `markup.changebars` | true &#124; false | FALSE | impl | Rule beside each paragraph changed since a reference version: pdf(changes_since = ), else the latest git tag. |
| `markup.floats` | true &#124; false | TRUE | impl | false: tables and figures stay exactly where they are written; nothing floats. |
