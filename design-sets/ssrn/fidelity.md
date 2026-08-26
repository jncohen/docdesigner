# ssrn — fidelity report

Rebuilt 2026-07-18 from `ssrn-{stylesheet,title,firstpage,page}.dc.html`.
Validates clean against `schema.yml` (0 errors; the prior 8 are resolved — see
bottom). Categories: **exact** (renders as modelled today), **approximated**
(right token, coarser than the model), **declared-inert** (valid token, but
`status: new`/`port` — validates, not yet rendered by the engine), **not
expressible** (needs new schema vocabulary). The stylesheet is the explicit
token spec sheet; title/firstpage/page are rendered intent (measured in px,
in = px/96, pt = px*0.75).

## Exact
- Typeface XITS body/heading (bundled Times-metrics serif), Fira Code mono;
  base 12pt; line-height 1.68; justified; microtype on.
- Palette: text `#1A1A1A`, accent `#333333` (links only), muted `#555555`,
  rule `#B8B8B8`. Effectively colourless — the identity is its restraint.
- Asymmetric margins (top 1.0 / bottom 0.875 / sides 1.333 in), single column.
- Numbered sections; bold near-black section/subsection heads (not the accent).
- Booktabs tables with a bold header; code unhighlighted (`none`).
- Folio centred in the footer, no footer rule (`footer.center: page`,
  `footer.right: none`, `footer.rule: false`). Continuation pages and the
  `plain`-styled opener both carry the centred drop-folio.

## Approximated
- **Paragraph indent** `lg` (1.5em) for the model's `text-indent: 1.6em`
  first-line indent — nearest scale step. (The stylesheet labels this step
  "md — 1.6em", but in schema v2 `indent.md` = 1em and `indent.lg` = 1.5em; the
  rendered 1.6em maps to `lg`.)
- **Abstract inset** `title.abstract.indent: lg` for the title page's 24px
  each-side inset (24px = 1.5em at 12pt); the firstpage variant insets ~28px.
- **Heading scales** h1 `1.1`, h2/h3 `1.0`. The stylesheet specimen grades
  h1/h2/h3 at 16/15/13px on a 14px body (~1.14 / 1.07 / 0.93); the rendered
  body pages show section heads at 15px on 14.5px (~1.03). Values chosen between
  the two; the gradation is gentle by design.
- **Title colour** left at the `text` default (near-black `#111`/`#1A1A1A` in
  the models); byline set to `text` ink to match the author line (affiliation
  is the muted italic — see not-expressible).

## Declared-inert (valid, awaiting engine wiring)
- `headings.run_in: [h3]` — `status: new`. The h3 italic lead-in should sit
  run-in with the paragraph ("Identification. text follows…"); until run-in is
  wired it renders as a standalone italic h3. Exercised only in the stylesheet
  specimen (the body pages show no h3).
- `title.layout: plain`, `title.page_break_after: true`, `title.date.show`,
  `title.keywords.show` — `status: port`/`new`. The standalone centred title
  page (title page 1, body from page 2), the date line, and the keyword line
  won't render until those ports land; today they degrade to plain centred
  front matter carried as metadata/body text.
- `title.byline.color` — the byline colour hook is `port`.

Note: this style targets the LEFT compact opener (`ssrn-firstpage`), not the
centred standalone title page (`ssrn-title`). `title.align: left`,
`title.abstract.label_style: runin`, `.indent`, `.size`, `title.scale`, and
`headings.h*.color`/`style` are `status: impl` (wired 1.0.3), so the flush-left
title, the run-in "Abstract." label, and the near-black italic h3 render today.
The centred title page returns once `title.layout`/`title.page_break_after`
land (both port/new). (Corrected 2026-07-18 from an initial center/heading
read that matched the title-page model, not the opener the specimen renders.)

## Not expressible (needs new schema vocabulary)
- **Working-paper series line** — "Meridian Economics Working Paper Series /
  Working Paper No. 31428 / https://www.ssrn.com/abstract=31428" centred at the
  top of the title page (and a compact "…Series · No. 31428" rule-underlined
  band on the firstpage variant). No series/working-paper-number token exists.
- **JEL classification line** — "JEL Classification: D31, I24, J24" under the
  abstract. No `jel` token.
- **First-page acknowledgment footnote** — the thanks/"errors are our own" note
  set below a short 150px hairline, pinned to the foot of the title and opener
  pages. No `acknowledgment`/thanks-note token; the schema has no first-page
  footnote-block control.
- **Date label prefix** — "This draft:" before the date. `title.date` exposes
  only `show`/`color`, no label string.
- **Author affiliation styling** — "Meridian University" in muted italic under
  the byline. Affiliation is content with no dedicated style token.
- **Display-equation numbering** — right-flush "(1)" on the numbered display
  equation is the math engine's own convention; there is no `math.*` token
  vocabulary in the schema to declare it.
- **Abstract leading** — the opener sets the abstract tighter than the body
  (1.55 vs 1.68), but there is no per-abstract line-height token, so the
  abstract inherits the body `typography.line_height`.

## The 8 prior validation errors — resolved
| Was | Fix |
|---|---|
| `title.series.show: true` (no such key) | dropped → series line not expressible (above) |
| `title.byline.align: center` (no such key) | dropped → global `title.align: center` governs |
| `title.byline.affiliation.style: italic` (no such key) | dropped → affiliation not expressible |
| `title.date.label: "This draft:"` (no such key) | dropped → date-label prefix not expressible |
| `title.abstract.align: center-heading` (no such key/value) | → `title.abstract.label_style: heading` |
| `title.jel.show: true` (no such key) | dropped → JEL line not expressible |
| `title.acknowledgment.position: footnote` (no such key) | dropped → acknowledgment note not expressible |
| `math.numbering: right` (no such key; no `math.*` in schema) | dropped → equation numbering not expressible |
