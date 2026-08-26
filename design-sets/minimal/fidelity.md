# minimal — fidelity report

Rebuilt 2026-07-18 from `minimal-{stylesheet,title,firstpage,page}.dc.html`.
Validates clean against `schema.yml` (0 errors). Categories: **exact** (renders
as modelled today), **approximated** (right token, coarser than the model),
**declared-inert** (valid token, but `status: new`/`port` — validates, not yet
rendered by the engine), **not expressible** (needs new schema vocabulary).

The style sheet is the explicit token spec; title/firstpage/page supply
rendered intent measured in px (14px = 10.5pt = base size; ÷96 = inches).

## Exact
- Typeface Source Serif 4 body/heading, Fira Code mono (all bundled defaults,
  inherited); base 10.5pt; line-height 1.15; mono at 0.9.
- Palette: text `#1A1A1A`, accent `#244A7A` (title rule, heads, section
  numbers, links), muted `#6B6B6B`, rule `#C9C9C9`.
- Letter, single column, symmetric `page.margin: normal` (1.25in).
- Numbered sections; accent section heads in the body face — h1 1.5 / h2 1.15 /
  h3 0.95 — bold and accent-coloured (both schema defaults).
- Flush-left title in accent at scale 2.2, with an accent rule below.
- Run-in abstract label (`label_style: runin`).
- First-line paragraph indent, no inter-paragraph space.
- Continuation running head: short title (left) · author (right) with a
  hairline separator; centred folio in the foot, no foot rule; page 1 plain.

## Approximated
- **Margins** `page.margin: normal` (symmetric 1.25in) per the style sheet's
  explicit `margin: normal — 1.25in`. The firstpage/page models actually render
  a slightly asymmetric block (top ~1.0in / bottom ~0.79in / sides 1.25in); the
  named shorthand collapses this to symmetric 1.25.
- **Paragraph indent** `md`. The schema step `md` is 1em; the model's first-line
  indent is 1.25em (the style sheet labels it "md — 1.25em", but the live schema
  step is 1em). Nearest named step.
- **Abstract inset** `indent: lg` (1.5em ≈ 0.22in) for the model's ~0.35in
  both-margin inset — the indent scale tops out at `lg`.
- **Abstract label** `label_style: runin` renders a small-caps "ABSTRACT" run in
  with line 1; the model shows a bold "Abstract." Right structure, different
  case (the engine has no bold-run-in label variant).
- **Title rule weight** inherits `thick` (2pt) for the model's 2px (~1.5pt)
  accent rule — nearest rule-weight step (the style sheet does not name one).
- **Heading scales** h1 1.5 and h3 0.95 read from the style-sheet specimen
  (21px and 13px on a 14px base); h2 1.15 matches both the specimen (16px) and
  the schema default.
- **Running-head author** `header.right: surname` renders the full author name
  (current engine behaviour); the page model shows bare surnames
  ("Vance, Okafor & Menon").

## Declared-inert (valid, awaiting engine wiring)
- `title.layout: report` — `status: port`. Captures the flush-left opener with a
  heavy rule and institution line. Until ported, the opener is still drawn by
  the default title macros, and the impl tokens (`title.color: accent`,
  `title.rule.position: below`, `title.rule.color: accent`, `title.scale`,
  default left align) render the flush-left accent title + accent rule as
  modelled — so the visible result is close regardless.
- `color.code_bg` + `code.background: code_bg` + `code.border: true` —
  `status: new`. The light code panel (`#F6F7F9`) and its hairline border won't
  render yet; code still highlights via the default `tango` theme.
- `quote.rule: true`, `quote.color: muted` — `status: new`. The accent left-rule
  blockquote (muted text) won't render until quote styling is wired; block
  quotations still indent.

Note: `title.abstract.label_style`, `title.color`, `title.rule.*`,
`headings.*.scale`, `header_footer.header.*`/`footer.*` are all `status: impl`
(wired in 1.0.3), so the accent title + rule, numbered accent heads, run-in
abstract, and the continuation running head are expected to render — confirm the
run-in abstract and head by eye, as `verify-tokens.R` does not check those.

## Not expressible (needs new schema vocabulary)
- **Affiliation / institution line** ("Department of Sociology, Meridian
  University", italic muted under the byline) — affiliation is content with no
  dedicated style token.
- **Title-page furniture** — the "Preprint · not peer reviewed" kicker above the
  title and the "Meridian University · Working Paper Series · 2026" band at the
  foot of the title page. No kicker/masthead-line token; `title.layout` selects
  a block layout but exposes no extra text slots.
- **Bare-surname running head** — the model's "Vance, Okafor & Menon" (surnames
  only, no first names); the `surname` enum value resolves to the full author
  string. Same class of gap noted under Approximated.
- **Reference hanging indent** — the models' bibliography uses a hanging indent;
  there is no bibliography-style token.

## Prior format — validation status and corrections
The previous `minimal/format.yml` already validated clean (**0 errors**); it was
stale on fidelity, not on schema. Changes made this rebuild:

| Prior | Change | Why |
|---|---|---|
| `page.margins.top/bottom/inner/outer` (asymmetric) | → `page.margin: normal` | honour the style sheet's explicit `margin: normal — 1.25in`; asymmetry noted as approximated |
| `header_footer.footer.right` unset (defaults to `page`) | → `footer.right: none` | `footer.center: page` + the default `page` on the right duplicated the folio |
| (no running head declared) | + `header.left: runningtitle`, `header.right: surname`, `header.rule: true` | the page model shows a continuation running head the stale file omitted |
| `title.scale: 2.57` | → `2.2` | style-sheet Title spec |
| `headings.h1.scale: 1.35` | → `1.5` | style-sheet specimen (21px on 14px base) |
| `headings.h3.scale: 1.0` | → `0.95` | style-sheet specimen (13px) |
| `headings.h*.weight: bold`, `headings.h*.color: accent` | dropped | redundant — both are schema defaults |
| `title.byline.color: muted`, `title.date.color: muted` | dropped | redundant — schema defaults |
| `table.row_stretch: 1.2`, `code.highlight: tango` | dropped | redundant — schema defaults |
| (title in default text ink) | + `title.color: accent` | every minimal model draws the title in accent |
| — | + `title.abstract.label_style: runin`, `title.abstract.indent: lg` | run-in inset abstract from the firstpage opener |
| — | + `code.background`/`code.border`, `quote.rule`/`quote.color` | code panel + accent quote rule (declared-inert) |
