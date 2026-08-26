You are designing a print PDF style for **docdesigner**, an R Markdown rendering engine. The engine only understands a fixed, bounded set of design tokens -- it cannot render anything outside them. Treat every constraint below as a hard boundary, not a suggestion: a design that relies on something not listed here (a gradient, a fifth accent hue, an arbitrary font) will only be partially recoverable when it's imported back into docdesigner.

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

## Title treatment

Five archetypes exist for how the title/byline/abstract block reads.
**Pick one** and design toward it -- a design that mixes elements from
several will not map cleanly onto any single archetype:

- **plain** -- flush left, no title page, no page break.
- **essay** -- centred, book-like: centred small-caps title, short rule, italic subtitle, generous leading.
- **journal** -- centred with rules, abstract, keywords.
- **report** -- flush left, heavy rule, institution line.
- **masthead** -- compact accent bar, one page, "About the Author" footer.

**Caveat, stated plainly:** `title.layout` is implemented in
docdesigner's LaTeX template but not yet wired up to the `pdf()` output
path (tracked in `dev/PORT-PLAN.md`). A design built around, say, a
full-page `journal` title page is valuable now for its colour, type,
and heading choices -- those import cleanly -- but the full-page
treatment itself will not render until that port lands. Don't be
surprised if an early import comes back with a plain flush-left title
regardless of what the Claude Design canvas shows; that's this gap, not
a bug in the import.

## Tables and code

- Table style: one of `booktabs`, `grid`, `zebra`, `minimal`.
- Code syntax theme: one of `pygments`, `tango`, `espresso`, `zenburn`, `kate`, `monochrome`, `breezedark`, `haddock`, `none`.

## Explicitly out of bounds

- Gradients, drop shadows, or any effect implying a light source.
- More than two accent hues (`accent` + optional `accent2`).
- Background images or photography behind text.
- Partial transparency on text or rules (must survive grayscale print).
- More than four heading levels.
- Arbitrary pixel font sizes not expressible as one of the base sizes
  above, or a heading scale multiple of one.

## What to do with the result

Export as **standalone HTML** (Claude Design's Export menu). Then, in
R:

```r
docdesigner::designer_import_claude_design(
  html = "path/to/export.html",
  id   = "your-style-id",
  from = "minimal"
)
docdesigner::designer_validate_style("your-style-id")
```

The import extracts colour, font, and type-scale values mechanically.
It does not set `title.layout` or any other structural token -- those
are still your call, informed by which archetype you designed toward
above. See `dev/CLAUDE-DESIGN-IMPORT.md` for the full accounting of
what is and isn't extracted.

---

**Relationship to `screenshot-to-style-prompt.md`, in this same folder:**
this document is the *greenfield* entry point — hand it to Claude Design
when you're designing a new look from scratch, with no specific printed
page in mind, and want only the mechanically-extractable tokens (colour,
font, type scale) filled automatically from the HTML export.
`screenshot-to-style-prompt.md` is the *reproduce this specific page* entry
point — give it a screenshot and it hands back both the HTML mockup *and* a
hand-authored `format.yml` (so it also sets `title.layout` and other
tokens the mechanical importer can't infer). Whether one of these should
become the sole/primary path is an open question — see
`USER-MANUAL-NOTES.md` (Hub notes vault), question 2. Until that's decided,
both stay, kept side by side here.
