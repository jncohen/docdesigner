# demography — fidelity report

Rebuilt 2026-07-17 from `demography-{title,firstpage,page,stylesheet}.dc.html`.
Validates clean against `schema.yml` (0 errors; the prior 6 are resolved —
see bottom). Categories: **exact** (renders as modelled today), **approximated**
(right token, coarser than the model), **declared-inert** (valid token, but
`status: new`/`port` — validates, not yet rendered by the engine), **not
expressible** (needs new schema vocabulary).

## Exact
- Typeface EB Garamond body/heading, Fira Code mono; base 11pt; line-height 1.5;
  justified; oldstyle figures in prose.
- Palette: text `#1B1B18`, accent `#2A4B6E` (links + rules only), muted
  `#6A6862`, rule `#C9C6BC`.
- Asymmetric margins (top 1.0 / bottom 0.875 / sides 1.375 in), single column.
- Centred small-caps section heads (h1/h2), near-black not accent; italic h3.
- Title layout journal, flush-left title at scale 1.9, italic subtitle,
  author byline in text ink.
- Booktabs table, row stretch 1.15, bold header; plain (unhighlighted) code.
- Continuation running head: page (outer-left) · surname (outer-right).

## Approximated
- **Paragraph indent** `lg` (1.5em) for the model's 1.4em first-line indent —
  nearest scale step.
- **Abstract inset** `indent: md` for a ~0.42in inset from both margins — the
  indent scale tops out below the modelled inset.
- **Table/figure caption** `label_style: italic` + `caption.position: above`
  for the model's small-caps label + italic caption text (see declared-inert).

## Declared-inert (valid, awaiting engine wiring)
- `headings.run_in: [h3]` — `status: new`. The h3 sub-head should sit run-in
  with the paragraph ("Measurement. text follows…"); until run-in is wired it
  renders as a standalone italic h3. The one real heading gap.
- `title.abstract.rule: true`, `title.keywords.*` — `status: port`; the
  front-matter hairline separator and keyword line won't render until the port.
- `figure.caption.*`, `table.caption.position` — `status: new`.

Note: `headings.h*.case: smallcaps` and `headings.h*.align: center` are
`status: impl` (wired in 1.0.3), so the centred small-caps section heads are
expected to render — confirm by eye, since `verify-tokens.R` checks margins,
fonts, and columns but not heading case.

## Not expressible (needs new schema vocabulary)
- **First-page journal citation line** — "Demography · Volume 61, Number 3 ·
  June 2026" across the top of page 1, and the "Article · pp. 411–438" line. No
  `journaltitle`/`issue`/`volume` running-head enum values exist, and there is
  no per-first-page running-head control (`header_footer.first_page` is
  `status: new`). Same class of gap as `_inbox/PACKAGE-CHANGES.md`'s Economist
  running-header band. The continuation-page head (page · surname) is applied
  throughout as the approximation.
- **True drop-folio** (folio bottom-centre on the opener, migrating to the top
  running head on later pages) — the engine applies one running-head scheme to
  all pages.
- **Author affiliation styling** ("Meridian University", italic muted, under the
  byline) — affiliation is content with no dedicated style token.

## The 6 prior validation errors — resolved
| Was | Fix |
|---|---|
| `title.byline.affiliation.style` (no such key) | dropped → affiliation not expressible (above) |
| `figure.caption.style: italic` (no such key) | → `figure.caption.label_style: italic` |
| `table.header.weight: semibold` (not in enum) | → `bold` (bundled faces ship Regular/Bold only) |
| `quote.style: roman` (not in enum) | → `normal` |
| `header_footer.header.left: journaltitle` (not in enum) | → `page`; journal line noted as not expressible |
| `header_footer.header.right: issue` (not in enum) | → `surname` |
