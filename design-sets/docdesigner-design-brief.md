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

Bundled (usable with no extra work): *Source Serif 4*, *EB Garamond*, *XITS*, *Fira Code*.

**All four bundled families are serif or monospace -- there is no
bundled sans-serif.** A sans-serif design is not out of bounds, but it
means supplying font files (`fonts.<Family>.regular/bold/italic/
bolditalic`) rather than using what's already available.

Three font roles: `typography.body`, `typography.heading` (falls back
to body if unset), `typography.mono` (code). At most three families in
a single design -- docdesigner has no fourth type role.

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
- **masthead** -- reserved for the snapshot format (port step 4); renders as header today.

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

## Explicitly out of bounds

- Gradients, drop shadows, or any effect implying a light source.
- More than two accent hues (`accent` + optional `accent2`).
- Background images or photography behind text.
- Partial transparency on text or rules (must survive grayscale print).
- More than four heading levels.
- Arbitrary pixel font sizes not expressible as one of the base sizes
  above, or a heading scale multiple of one.

## What to do with the result

Export the design as **standalone HTML** (one self-contained page).
Then, in R:

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
