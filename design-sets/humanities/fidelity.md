# humanities — fidelity report

Rebuilt 2026-07-18 from `humanities-{stylesheet,title,firstpage,page}.dc.html`.
Validates clean against `schema.yml` (0 errors; the prior 4 are resolved — see
bottom). Categories: **exact** (renders as modelled today), **approximated**
(right token, coarser than the model), **declared-inert** (valid token, but
`status: new`/`port` — validates, not yet rendered by the engine), **not
expressible** (needs new schema vocabulary). The stylesheet is the explicit
token spec sheet; title/firstpage/page are rendered intent (measured in px,
in = px/96, pt = px*0.75). This style follows the OPENER (`humanities-firstpage`):
centred small-caps title, italic subtitle, short centred rule, centred byline,
no abstract.

## Exact
- Typeface EB Garamond body/heading (bundled oldstyle serif), Fira Code mono;
  base 11.5pt; line-height 1.62 (generous); justified; microtype on.
- Palette: text `#211E18` (warm near-black), accent `#5A3A2E` (deep sepia —
  footnote markers + links only), muted `#8A7F6B`, rule `#B7AE97` (warm grey).
  Near-monochrome; the identity is its restraint.
- Asymmetric margins (top 1.125 / bottom 0.875 / sides 1.5625 in), single column.
- Title: centred (`title.align: center`), small-caps (`title.case: smallcaps`),
  near-black (`title.color: text`) with a hairline rule below
  (`title.rule.position: below`, `weight: hairline`, `length: 0.5625in` = the
  54px opener rule). Italic subtitle (`title.subtitle.style: italic`). Centred
  byline in text ink (`title.byline.color: text`). No abstract
  (`title.abstract.show: false`). `title.case`/`title.align` are impl (1.0.3).
- Headings: h1 centred small-caps near-black; h2 centred italic; h3 italic
  lead-in — all body-sized (`scale: 1.0`), colour `text` not accent.
  `headings.<h>.case`/`.align`/`.style`/`.color` are impl (1.0.3), so the
  centred small-caps h1 and centred italic h2 render today.
- Unnumbered sections (`headings.number_sections: false`).
- Paragraphs separated by first-line indent, no vertical space
  (`paragraph.spacing: none`). Block quotations roman and indented, no quote
  marks (`quote.style: normal`, no `quote.rule`). Booktabs tables; code
  unhighlighted (`none`).
- Folio bottom-centred (`footer.center: page`), no second folio
  (`footer.right: none`), no footer rule (`footer.rule: false`). Running title
  top-centred on continuation pages (`header.center: runningtitle`), no header
  rule; the opener carries no running head (default `first_page: plain`).

## Approximated
- **Paragraph indent** `lg` (1.5em) for the model's `text-indent: 1.6em`
  first-line indent — nearest scale step. (The stylesheet labels this step
  "md — 1.6em", but in schema v2 `indent.md` = 1em and `indent.lg` = 1.5em; the
  rendered 1.6em maps to `lg`.)
- **Title scale** `1.9` — the stylesheet's explicit token value. The opener
  title measures 27px on a 15.5px body (~1.74) and the standalone title page
  32px (~2.06); 1.9 is the spec-sheet intent between them.
- **Heading weight** `bold` for the model's 500 (medium). Bundled EB Garamond
  ships Regular/Bold only; `weight` enum is light/regular/bold, so 500 → bold
  (schema convention; the delicate small-caps/italic heads render heavier than
  the model's medium).
- **Subtitle colour** left at the `muted` default; the model subtitle is a
  darker warm grey (`#55503F`) with no matching colour role.
- **Quote indent** `md` (1em), matching the stylesheet specimen's 16px inset;
  the body-page block quote is set wider (~44px each side, beyond the `lg`
  ceiling of 1.5em). The stylesheet specimen also shows an alternative
  italic + accent left-rule quote treatment; the body page (followed here) is
  plain roman with no rule.

## Declared-inert (valid, awaiting engine wiring)
- `title.layout: essay` — `status: port`. The centred book-like essay opener
  (small-caps title, short rule, italic subtitle, centred byline) is the
  intended archetype; until the layout port lands it degrades to plain centred
  front matter, though `title.align`/`case`/`rule.*` already render the centred
  small-caps + rule treatment.
- `title.case: smallcaps`, `title.byline.color`, `title.abstract.show: false`
  route through `title.layout`/byline ports; `title.case` validates and the
  small-caps title renders via the impl case hook.
- `headings.run_in: [h3]` — `status: new`. The h3 italic lead-in should sit
  run-in with the paragraph ("A digression. text follows…"); until run-in is
  wired it renders as a standalone italic h3. Exercised only in the stylesheet
  specimen (the body pages show no h3).
- `typography.numbers: oldstyle` — `status: new`. Oldstyle figures depend on
  OpenType feature activation not yet wired; digits render lining today.
- `typography.justification: justified` — `status: new` (but the engine default
  is already justified, so output is unaffected).
- `footnotes.size: 0.72` — `status: new`. Footnotes themselves render via
  `\footnote`; the per-note scale control is not yet parameterised.
- `figure.style`/`figure.caption.*` — `status: new`. No figure appears in the
  models; these encode the spec sheet's "caption below · italic" intent.

## Not expressible (needs new schema vocabulary)
- **"An Essay" eyebrow/kicker** — the small-caps muted label above the title on
  the opener and title page. No kicker/eyebrow token.
- **Small-caps incipit** — the opening paragraph's "That the learned…" small-caps
  lead-in is a paragraph-level flourish with no token (and no drop cap: the
  models show a plain initial, so `paragraph.drop_cap.lines` is left unset).
- **Flush opening paragraph** — the first paragraph is set flush (no indent),
  subsequent paragraphs indented; this is LaTeX's default first-paragraph
  behaviour, not a declarable token.
- **Footnote separator rule** — the short 120px hairline above the note block is
  the default footnote rule; there is no token for its width/position.
- **Institution / colophon line** — "Meridian University · MMXXVI" centred at
  the foot of the title page and the small-caps "Meridian University" closing
  the body pages. No institution/colophon token; `title.date` exposes only
  `show`/`color`.
- **Running-head small caps** — the top-centred running title is small-caps in
  the model; `runningtitle` renders it, but its case is not separately
  controllable.
- **Warm page tint** — the models sit on a faintly warm `#fbfaf6` stock;
  `color.background` exists (`status: new`) but the effect is a paper tint the
  print pipeline does not model, so it is left unset.

## The 4 prior validation errors — resolved
| Was | Fix |
|---|---|
| `title.weight: medium` (no such key; and `medium` not a valid weight) | dropped → title weight (model 500) not expressible; no `title.weight` token |
| `title.byline.align: center` (no such key) | dropped → global `title.align: center` governs the centred byline; added `title.byline.color: text` |
| `figure.caption.style: italic` (no such key) | → `figure.caption.label_style: italic` |
| `quote.marks: none` (no such key) | dropped → no-quote-marks is the default; block quotes carry no marks (`quote.style: normal`) |
