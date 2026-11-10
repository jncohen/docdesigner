# docdesigner design brief

You are designing a print PDF style for **docdesigner**, an R Markdown
rendering engine. The engine only understands a fixed, bounded set of
design tokens -- it cannot render anything outside them. Treat every
constraint below as a hard boundary, not a suggestion: a design that
relies on something not listed here (a gradient, a fifth accent hue, an
arbitrary font) will only be partially recoverable when it's imported
back into docdesigner.

This is a **print** design, not a responsive web page. Design for a
single fixed page width (see `page.margin` below), not a fluid layout.

## Colour

Exactly these roles exist. Do not introduce more distinct hues than
this list allows.

- **accent**: Primary identifying colour. Headings, the title, rules, and links unless overridden. Every style must set this.
- **accent2**: Optional secondary accent. Nullable -- most shipped styles leave it unset. Use sparingly if at all; this is not a second primary colour.
- **text**: Body text colour. Every style must set this.
- **muted**: Secondary text: byline, date, captions, muted labels. Every style must set this.
- **rule**: Colour of hairlines and rules (under headings, under the title).
- **background**: Page background colour. Nullable -- null means the paper's default (effectively white).
- **code_bg**: Fill behind code blocks. Nullable -- null means no fill.
- **knockout**: Colour of text drawn on top of an accent-filled bar. Defaults to white-on-accent.

## Fonts

Bundled with docdesigner: *Source Serif 4*, *EB Garamond*, *XITS*, *Fira Code*.

In every TeX installation, so also usable with no extra work: *Latin Modern*, *Latin Modern Mono*, *TeX Gyre Heros*.

*TeX Gyre Heros* (a Helvetica-like face) is the one sans-serif available
without supplying files. Any other face means shipping its files with
the style (`fonts.<Family>.regular/bold/italic/bolditalic`).

Font roles: `typography.body`; `typography.heading` (falls back to
body); `typography.mono` (code); and two optional roles,
`typography.display` (titles and headings set in a display face) and
`typography.label` (small sans furniture: kickers, callout titles, table
headers). The roles allow up to five families; good designs use two or
three.

## Type scale

- Base body size: one of `8pt`, `8.5pt`, `9pt`, `9.5pt`, `10pt`, `10.5pt`, `11pt`, `11.5pt`, `12pt`.
- Line height: 1.0-2.0x (typical: 1.2-1.4).
- Heading sizes are a *multiple of the base size*, not a free value: h1/h2/h3 each between 0.5x and 4.0x body size. A typical scale is h1 around 1.3-1.5x, h2 around 1.1-1.2x, h3 at or near 1.0x.
- Heading weight: light, regular, or bold -- no in-between.
- Heading case: none, upper, lower, or smallcaps.

## Rules and rhythm — named steps only

These are enums, not free dimensions. A design that uses a rule weight
or a spacing value off this list cannot be represented exactly.

- Rule weight: `hairline` = 0.4pt, `thin` = 0.6pt, `medium` = 1pt, `thick` = 2pt, `heavy` = 3pt
- Vertical space (heading/paragraph spacing): `none` = 0pt, `xs` = 0.25em, `sm` = 0.5em, `md` = 1em, `lg` = 1.75em, `xl` = 2.5em
- Paragraph indent: `none` = 0pt, `sm` = 0.75em, `md` = 1em, `lg` = 1.5em
- Page margin: `narrow` = 0.75in, `normal` = 1in, `wide` = 1.35in (or a custom margin in inches, 0.4-2.0)

## Line length and page proportions

**Set the body to 60-72 characters per line** (spaces included) in a
single-column design, and 40-55 per column in a two-column one. This is
the most important constraint here: a long line is what makes a page
read like a memo rather than a journal. Count characters on a full line
of body text in the design before calling it done.

- On US letter paper (8.5in wide) a serif body at 10-12pt sets roughly
  14-17 characters per inch, so a single column wants a text block about
  4.2-4.8in wide: side margins of roughly 1.85-2.0in. One-inch side
  margins give 90-105 characters, which is too long.
- If generous side margins look wrong for the design, raise the body
  size by half a point or a point rather than widening the text block,
  or use two columns.
- Keep the bottom margin at least as large as the top. A tall, narrow
  text block with thin top and bottom margins looks like a printout;
  give the page some vertical air as well.
- In a screen mockup the page is 816px wide (letter at 96px per inch),
  so a single-column text block is about 400-460px wide.

## Title treatment

`title.layout` decides structure only: whether the title block opens
the first body page or takes a page of its own. Design the title's
look (alignment, case, rule, kicker, subtitle, abstract panel) with the
other `title.*` tokens; they apply to every layout.

- **header** -- the title block sits at the top of the first body page.
- **page** -- the title block and abstract take a page of their own and the body starts on the next.
- **thesis** -- a thesis title page (degree statement, optional signature block), an optional copyright page, then front matter (contents, acknowledgements, abstract) before the body.

On a title page (`page`), the title block sits about a third of the way
down (`title.page.offset`, a fraction of the text height), and the
abstract sits either on the title page or at the head of the first body
page (`title.page.abstract`). The title page carries no running head,
band or folio.

A model that shows both a standalone title page and a first page with
the title at its head is two layouts of one style: design the tokens
once and both render. The importer does not infer the layout; set it
by hand.

## Tables and code

- Table style: one of `booktabs`, `grid`, `zebra`, `minimal`.
- Code syntax theme: one of `pygments`, `tango`, `espresso`, `zenburn`, `kate`, `monochrome`, `breezedark`, `haddock`, `none`.

## Quotes, callouts and the abstract

Three block elements set text apart. Make them distinguishable at a glance:
if quotes carry a left bar, give the callout a fill or a border instead.

- Quote: indent `none` = 0pt, `sm` = 0.75em, `md` = 1em, `lg` = 1.5em; style `normal` or `italic`; any colour role; optional left accent bar.
- Callout (the author's key point, with a short title): `filled`, `ruled`, `boxed`, `plain`; a colour role for the bar, border and title; a fill tint of 0-40% of that colour; title case none, upper or smallcaps.
- Abstract: label as a heading, run in, or none; optional rule below;
  optional box with a background role.

## Making the HTML importable

`designer_import_html()` reads the page's CSS literally. Follow these
conventions or the values will not be found:

- Put all CSS in one `<style>` block in the page's `<head>`.
- Style plain element selectors: `body`, `h1`, `h2`, `h3`. Classes and
  descendant selectors are not read for these values.
- Declare the palette as custom properties on `:root`: `--accent`,
  `--color-text`, `--color-muted`, `--color-background`.
- The accent is read from `h1 { color }` first and `--accent` only when
  `h1` sets no colour. If headings are not in the accent colour, let `h1`
  inherit its colour from `body` and declare `--accent`.
- Give `body` a `font-size` in px and a unitless `line-height`; give each
  heading a `font-size` in px, a `font-weight` and, if used, `text-transform`.
- Name fonts by family (`font-family: "Source Serif 4", serif`).

The import never reads layout: title layout, margins, columns, running
heads, rules and colour roles are set by hand from the design. A
stylesheet page listing every token value by name makes that step
mechanical.

## Markup styles: drafts to be marked up by hand

Most styles dress a finished document for a reader. A *markup style*
dresses a draft for its author: printed to be read slowly and written
on, with every page leading back to a spot in the source. The shipped
example is `review`; start any markup style from it. These tokens make
a style a markup style. Each is off by default.

- `markup.line_numbers`: Number every nth line in the outer margin, restarting on each page. 0: off.
- `markup.paragraph_numbers`: Number body paragraphs continuously in the inner margin (¶n), so a note made on one printout finds its paragraph in the next.
- `markup.flags`: [[TODO]], [[CITE]], [[WEAK]], [[CUT]], [[CHECK]], [[FIX]], [[VERIFY]], [[FACT]], [[RECOMPUTE]] and [[QUESTION]] in the text print as margin tags, with [[V]], [[C]], [[F]], [[N]] and [[Q]] as short forms; [[TAG: words]] also keeps the words inline in markup.flag_color.
- `markup.flag_color`: Colour role for margin tags and the words a tag keeps inline.
- `markup.cite_keys`: Print each citation's bibliography key in small muted type after it.
- `markup.map`: Open the body with a map of the argument: each heading to this depth, with its words and starting page. 0: off.
- `markup.claim_check`: Flag [[LABEL?]] beside a heading of fewer than four words: a label where a claim belongs. Advisory.
- `markup.changebars`: Rule beside each paragraph changed since a reference version: pdf(changes_since = ), else the latest git tag.
- `markup.floats`: false: tables and figures stay exactly where they are written; nothing floats.

A markup style follows different rules from a publication style:

- **One column.** Numbers, tags and changebars live in the margins; the
  validator warns on `markup.*` with `page.columns: 2`.
- **A wide outer margin for handwriting.** Any `markup.*` token lifts the
  1.25in margin cap: `page.margins.outer` may go to 3.5in (`review`
  uses 3in). One-sided (`page.twoside: false`) keeps it on the right.
- **Nothing floats.** `markup.floats: false` keeps a table or figure
  beside the text that discusses it.
- **Stable lines.** A short measure, open leading, ragged right and no
  hyphenation keep line breaks, and so line numbers, stable between
  printouts.
- **The tags belong to the engine.** `[[V]]`, `[[C]]`, `[[TODO]]` and the
  rest are fixed. A style switches them on (`markup.flags`) and colours
  them (`markup.flag_color`); it cannot add or rename one.

## Explicitly out of bounds

- Gradients, drop shadows, or any effect implying a light source.
- More than two accent hues (`accent` + optional `accent2`).
- Background images or photography behind text.
- Partial transparency on text or rules (must survive grayscale print).
- More than four heading levels.
- Arbitrary pixel font sizes not expressible as one of the base sizes
  above, or a heading scale multiple of one.

## What to do with the result

**If you write `format.yml` directly**, start from the nearest shipped
style, declare only the tokens that differ, comment each with the reason
for its value, then validate and render:

```r
docdesigner::designer_new_style("your-style-id", from = "minimal",
                                path = ".", complete = FALSE)
docdesigner::designer_validate_style("your-style-id")
rmarkdown::render("paper.Rmd",
  output_format = docdesigner::pdf(style = "your-style-id"))
```

Fix every validation error first. Then look at the rendered pages: a
valid style can still set a bad page, and only the page shows it.

**If you designed in a visual tool**, export the design as **standalone
HTML** (one self-contained page). Then, in R:

```r
docdesigner::designer_import_html(
  html = "path/to/export.html",
  id   = "your-style-id",
  from = "minimal"
)
docdesigner::designer_validate_style("your-style-id")
```

The import extracts colour, font, and type-scale values mechanically.
It does not set `title.layout` or any other structural token -- those
are still your call, informed by which archetype you designed toward
above. `?docdesigner::designer_import_html` lists exactly
what is and isn't extracted.
