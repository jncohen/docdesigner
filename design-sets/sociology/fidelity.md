# sociology — fidelity report

Rebuilt 2026-07-18 from `sociology-{stylesheet,title,firstpage,page}.dc.html`.
Validates clean against `schema.yml` (0 errors; the prior 6 are resolved — see
bottom). Categories: **exact** (renders as modelled today), **approximated**
(right token, coarser than the model), **declared-inert** (valid token, but
`status: new`/`port` — validates, not yet rendered by the engine), **not
expressible** (needs new schema vocabulary). The stylesheet is the explicit
token spec sheet; title/firstpage/page are rendered intent (measured in px,
in = px/96, pt = px*0.75).

## Exact
- Typeface XITS body/heading (bundled Times-metrics serif), Fira Code mono;
  base 11pt; line-height 1.6 (loose); justified; microtype on.
- Palette: text `#1A1A1A`, accent `#333333` (links only), muted `#555555`,
  rule `#111111`. Effectively colourless — the identity is its restraint.
- Asymmetric margins (top 0.958 / bottom 0.875 / sides 1.125 in), single column.
- Heading hierarchy (all `status: impl`, wired 1.0.3): h1 centred bold ALL CAPS
  near-black; h2 flush-left bold italic; h3 bold italic (run-in — see inert).
  Unnumbered (`number_sections: false`).
- Title: centred (`title.align: center`), byline in small caps and text ink,
  abstract run-in labelled (`label_style: runin`) at 0.9× — the small-caps
  "Abstract" runs in with the first line exactly as the opener shows.
- Booktabs tables with a **regular** (non-bold) header — the ASA column-head
  convention (model `th` weight 400); code unhighlighted (`none`).
- Block quotations set roman and indented (`quote.style: normal`), not
  italicised — matches the body-page blockquote.

## Approximated
- **Paragraph indent** `lg` (1.5em) for the models' `text-indent: 1.5em`
  first-line indent — an exact match to the *rendered* value. Note the
  stylesheet labels this step "md — 1.5em", but in schema v2 `indent.md` = 1em
  and `indent.lg` = 1.5em; the rendered 1.5em maps to `lg` (the stylesheet's
  scale label is stale). Continuation paragraphs indent; the first paragraph
  after a heading does not (`indent_after_heading` left false).
- **Abstract inset** `title.abstract.indent: md` for the opener's 34px each-side
  inset (~2.3em at 15px); the scale tops out at `lg` = 1.5em, so any step
  under-insets. `md` chosen to match the demography cousin.
- **Quote inset** `quote.indent: md` for the body-page blockquote's 38px
  each-side margin (~2.5em) — coarser than modelled, same scale ceiling.
- **Heading / title scales** all set at the models' measured ratios (heads
  ~15px on ~15px body → 1.0; title 22px → 1.5). The standalone title-page model
  sets the title one step larger (24px); the opener's 22px governs here.
- **Title colour** left at the `text` default (models render `#111`, i.e.
  near-black — indistinguishable from text ink at this contrast).

## Declared-inert (valid, awaiting engine wiring)
- `headings.run_in: [h3]` — `status: new`. The h3 bold-italic lead-in should sit
  run-in with the paragraph ("Data and sample. text follows…"); until run-in is
  wired it renders as a standalone bold-italic h3.
- `title.layout: journal`, `title.case: upper`, `title.byline.case: smallcaps`
  — `status: port`. The centred journal front matter, the ALL-CAPS title, and
  the small-caps byline degrade until those ports land; `title.align`,
  `.byline.color`, `.abstract.label_style`, `.abstract.size` are `impl` and
  render today, so the centred run-in-abstract opener is largely faithful now.
- `header_footer.first_page: header` — carries the opener's page-1 running head
  (the firstpage model shows a top running head). `status: new`.
- `figure.caption.position: above`, `figure.caption.color: text`,
  `table.header.case`-family, `table.caption.position: above` — figure/table
  caption controls are `status: new`; table.style/header.weight/row_stretch are
  `impl`.

## Not expressible (needs new schema vocabulary)
- **Journal-title running head** — the head's outer-left carries the journal
  name ("American Journal of Social Research"). No journal-title role exists in
  `header_footer.*`; mapped to `runningtitle`, which renders the *article's*
  running title, not the journal name.
- **Recto/verso running-head alternation** — the opener/recto shows
  journal-title · page while the body/verso shows page · surname (bare "Cohen").
  docdesigner has one header spec (no per-side content); the file encodes the
  opener pattern (`header.left: runningtitle`, `header.right: page`) and the
  verso alternate is lost. Were the verso pattern used, `header.right: surname`
  renders the **full** author name, whereas the model shows a bare surname.
- **Duplicate footer folio** — every model page also prints a centred folio in
  the footer. With the folio already in the head, the default footer folio is
  suppressed (`footer.right: none`, `footer.rule: false`) to avoid a second one.
- **Masthead / issue line** — the title page's "…· 61(3) · 2026" volume/issue
  line has no token.
- **Hanging-indent references** — the reference list (`padding-left:1.6em;
  text-indent:-1.6em`, author-date) is a citation-processor/CSL concern; no
  `references.*` namespace exists.
- **Table notes block** — the ASA note below the table (N, replicate-weight SEs,
  significance-star legend) is table content; `table.caption.position` governs
  the title above, but there is no notes-position token.
- **Significance stars** — `0.42***`, `0.19*` and the `* p < .05` legend are
  analysis content, not a docdesigner token.
- **Author affiliation styling** — "Meridian University" in muted italic under
  the byline; affiliation is content with no dedicated style token.

## The 6 prior validation errors — resolved
| Was | Fix |
|---|---|
| `headings.h3.run_in: true` (no per-level `run_in` key) | → `headings.run_in: [h3]` (top-level list) |
| `title.byline.align: center` (no such key) | dropped → global `title.align: center` centres the byline |
| `table.notes.position: below` (no such key) | dropped → table notes-below not expressible (content) |
| `references.style: hanging` (no `references.*` namespace) | dropped → hanging references not expressible (CSL) |
| `quote.style: roman` (enum is normal/italic) | → `quote.style: normal` |
| `header_footer.header.left: journaltitle` (not in enum) | → `header.left: runningtitle`; folio moved to `header.right: page`, `footer.right: none` |
