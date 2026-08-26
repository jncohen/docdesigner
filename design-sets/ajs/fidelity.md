# ajs — fidelity report

New style: authored 2026-07-18 directly from the token-faithful model set
(`ajs-{stylesheet,title,firstpage,page}.dc.html`). There is no prior
`format.yml` — the design had not been started, so there is no prior-error
table. Validates clean against `schema.yml` (0 errors).

Categories: **exact** (renders as modelled today), **approximated** (right
token, coarser than the model), **declared-inert** (valid token, but
`status: new`/`port` — validates, not yet rendered by the engine), **not
expressible** (needs new schema vocabulary).

## Exact
- Typeface XITS body/heading (Times-metrics, substituting STIX Two Text),
  Fira Code mono; base 11pt; line-height 1.6; justified.
- Palette: text `#1A1A1A`, accent `#333333` (links + rules only), muted
  `#555555`, rule `#111111`. Lining figures (schema default) — correct for a
  Times-family journal.
- Symmetric margins (top 0.8 / bottom 0.875 / sides 1.23 in), single column.
- Section heads all **regular** weight, centred: h1 full-caps A-head
  (`case: upper`, `align: center`), h2 centred-italic B-head, near-black not
  accent. (`case`/`align`/`style`/`weight` are `status: impl`, wired 1.0.3.)
- Title layout journal, **centred** opener title at scale 1.5, byline in
  small caps and text ink (`byline.color: text` impl; `byline.case` port).
- Unlabelled abstract: `title.abstract.label_style: none` (impl) — the AJS
  signature, an indented block with no "Abstract" heading.
- Booktabs table, row stretch 1.15; plain (unhighlighted) code.
- Running head carries onto the opener (`first_page: header`); no duplicate
  footer folio (`footer.center/right: none`, `footer.rule: false`).

## Approximated
- **Paragraph indent** `lg` (1.5em) for the model's 1.6em first-line indent —
  nearest scale step. Same step used for the abstract's own first-line indent.
- **Abstract inset** `indent: md` (~1em ≈ 0.42in) for the model's 40px each-side
  inset — the `indent` scale tops out (lg = 1.5em) below the modelled inset.
- **Title scale** 1.5 for the opener's 22px title over 15px body (1.47); the
  standalone title page runs slightly larger (25px) — the opener governs.
- **Running head** `page` (left) + `runningtitle` (right) applied throughout,
  approximating the model's mirrored two-side head (see not-expressible).

## Declared-inert (valid, awaiting engine wiring)
- `headings.run_in: [h3]` — `status: new`. The C-head should sit run-in with
  its paragraph ("Data and sample. text follows…"); until run-in is wired it
  renders as a standalone italic h3. The one real heading gap.
- `title.layout: journal`, `title.align: center`, `title.byline.case: smallcaps`,
  `title.date.show: false`, `title.keywords.show: false` — `status: port`; the
  journal front-matter port controls these. `align`/`byline.color`/
  `abstract.label_style`/`abstract.indent`/`abstract.size` are `impl` and do
  render.
- `table.header.weight: regular`, `table.caption.position: above`,
  `figure.caption.position/align/label_style`, `footnotes.size`,
  `footnotes.numbering`, `quote.style`, `quote.indent`,
  `header_footer.first_page: header` — `status: new`; validate, not yet rendered.

Note: `headings.h*.case`/`align`/`style`/`weight` are `status: impl` (wired
1.0.3), so the centred caps / centred-italic heads are expected to render —
confirm by eye, since `verify-tokens.R` checks margins, fonts, and columns but
not heading case.

## Not expressible (needs new schema vocabulary)
- **First-page journal citation line** — "The Chicago Review of Sociology ·
  Volume 129 · Number 6 · May 2026" centred atop the title page. No
  `journaltitle`/`volume`/`issue` enum values exist for the running head or a
  masthead line.
- **Verso journal-name running head** — the model's even-page head reads
  "American Journal of Sociology" (small caps) on the outer edge, mirroring to
  the article title on recto. The header enum has no `journaltitle` value and
  the file applies a single (non-mirrored) `page` + `runningtitle` scheme to
  all pages; the journal-name slot is dropped.
- **True drop-folio** — the model also shows a centred folio at the page foot
  on every sample page (page 1 style) alongside the top running-head folio.
  The engine applies one running-head scheme to all pages; the bottom-centre
  drop folio is not reproduced (the head folio stands in).
- **First-page acknowledgment / correspondence footnote + copyright & billing
  code** — the unnumbered rule-topped note ("Direct correspondence to…") and
  the `0002–9602/2026/…$10.00` line are content-driven; no dedicated token.
- **Author affiliation styling** ("Meridian University", italic muted under the
  byline) — affiliation is content with no dedicated style token.
- **Heading letter-tracking** (0.12em on the full-caps A-heads, 0.05em on the
  small-caps byline) — no tracking/letter-spacing token exists.
- **Block-extract left accent rule** — the stylesheet's body specimen shows an
  optional accent left-rule on the extract; the body page shows the plain
  both-sides-indented extract, which is what the file targets (`quote.rule`
  left `false`).
