# nature — fidelity report

Rebuilt 2026-07-18 from `nature-{title,firstpage,page,stylesheet}.dc.html`.
Validates clean against `schema.yml` (0 errors, 0 warnings). nature is the
**two-column** style (`page.columns: 2`), so the notes below pay particular
attention to what the token vocabulary can and cannot reach across columns.
Categories: **exact** (renders as modelled today), **approximated** (right
token, coarser than the model), **declared-inert** (valid token, but
`status: new`/`port` — validates, not yet rendered), **not expressible**
(needs new schema vocabulary). A prior-format table closes the report.

## Exact (status: impl — renders as modelled)
- A4 paper, **two columns**, measured asymmetric margins (top 0.583 /
  bottom 0.646 / inner 0.646 / outer 0.646 in).
- Source Serif 4 body + heading, Fira Code mono; base 8.5pt; microtype on.
- Palette: text `#0A0A0A`, accent `#0B4F8A` (kicker/citations/links only),
  muted `#6A6F76`, rule `#0A0A0A`; links in accent.
- Bold **black** named section heads — h1 1.14 / h2 1.0 / h3 0.93 italic —
  all `color: text`, never accent (case/style/align are `impl`, wired 1.0.3).
- Title flush-left, scale 2.2, black headline (`title.color: text`,
  `title.align: left` — `impl`).
- Unlabelled **bold lead-paragraph standfirst**: `abstract.label_style: none`
  + `abstract.weight: bold` + `abstract.size: 1.05`, full measure. All three
  are `impl` — this treatment IS expressible now (see prior-format note).
- Dense body: 1em first-line indent (`paragraph.indent: sm`), no paragraph
  spacing.
- Booktabs tables, bold header, tight rows (`row_stretch: 1.0`); unhighlighted
  code (`code.highlight: none`).
- Running foot: running-title (left) · page (right) · hairline rule
  (`header_footer.footer.*` — `impl`). No running head anywhere; the page-1
  footer is the plain-page default (`first_page` left at default).

## Approximated (right token, coarser than the model)
- **Margins.** The stylesheet's `margin: narrow` shorthand is 0.75in, looser
  than the pages actually render; measured page geometry (0.583 / 0.646 in)
  is used instead of the scale step for a truer measure.
- **Body leading `line_height: 1.15`** — the stylesheet body specimen sets
  1.15 and it is taken as authoritative; the rendered two-column article
  bodies loosen to ~1.42. If the article look matters more than the spec
  sheet, this is the one value to revisit.
- **Paragraph separation.** Spec sheet declares `indent: sm` + `spacing:
  none`; the rendered two-column bodies instead separate paragraphs by
  ~0.6em vertical space with no first-line indent. The spec-sheet token
  intent (indent, no space) is used — it is the denser, more Nature-like of
  the two and avoids the indent-and-spacing validator warning.
- **Title heavy rule position.** `title.rule.position: above` records the
  signature 2.5px black rule that sits **above** the kicker+title in the
  model. `title.rule.*` is `impl`, but per the schema only `below`/`none`
  render today — `above` falls back to `below`, so the rule currently prints
  *under* the title rather than above the kicker. Weight `thick` (~2pt) and
  `color: rule` (black) are exact.
- **Heading scales** are the stylesheet specimen ratios (16/14/13 px over a
  14px body); the in-article section heads render a hair larger (h2 ≈ 1.08).
- **`abstract.size: 1.05`** for the 13.4px standfirst over the 12.6px body.
- **`mono_scale: 0.85`** for the ~0.84 code/body ratio in the Methods panel.
- **`figure.caption.color: muted`** for the model's `#4A4F56` caption ink (a
  shade darker than the muted role `#6A6F76`); nearest role.
- **`title.scale: 2.2`** is the spec-sheet value; the firstpage opener
  measures 2.14 and the separate title-model 2.6 — the plain page-1 opener
  (not the title page) governs, so 2.2 is used.

## Declared-inert (valid token, status new/port — not yet rendered)
- `typography.justification: justified` (`new`) — body still justifies by
  class default, but the token itself is inert.
- `title.layout: plain` (`port`) — plain flush-left already matches the
  engine default, so no visible loss while the layout machinery is wired.
- `figure.style: plain`, `figure.caption.position/color/label_style` (`new`)
  — the below-caption, muted face and bold **"Fig. 1 |"** label are all
  captured but await wiring.
- `table.header.weight: bold`, `table.caption.position: above` (`new`).
- `code.background: code_bg` + `code.border: true` + `color.code_bg`
  (`new`) — the tinted, hairline-bordered code panel in the Methods column.
- `quote.rule: true` + `quote.color: muted` + `quote.indent: md` (`new`) —
  the left accent-rule blockquote shown in the stylesheet specimen.

## Not expressible (needs new schema vocabulary)
- **Two-column spanning figures/tables.** The only spanning control is
  `figure.span_columns` (a single bool, `status: risk`, "fragile under
  columns:2"), and there is no table equivalent. In the models every figure
  and table stays **in-column** (`break-inside: avoid`), so `span_columns`
  is correctly left `false` and nothing is lost here — but a Nature layout
  that needed a full-measure figure across both columns could only reach for
  the one risky bool, and a full-width table could not be expressed at all.
  This is the standing two-column vocabulary gap.
- **Category kicker "ARTICLE"** over the heavy rule — no `title.kicker.*`
  token (PROPOSED in PACKAGE-CHANGES.md). Furniture in every model.
- **Superscript numeric citations** (accent, 0.66em) — a CSL/bibliography
  concern carried by the document's citation style, not a docdesigner token.
- **"Fig. 1 |" / "Table 1 |" bar-delimited labels** — the bold caption face
  is token-controlled (`label_style: bold`), but the literal `Fig. n |` /
  `Table n |` delimiter string is a caption-numbering convention with no token.
- **Continuation-page running HEAD.** The page model shows *both* a top head
  ("Article" kicker + `J. Popul. Sci. · Vol. 12 · 2026 · 2`) and a bottom
  foot on later pages. The token model gives one footer scheme; the page-2
  top head (category + journal-citation folio) is dropped. `header.right:
  surname` would render a full author name, not a bare surname — not used here.
- **DOI line, "Received / Accepted" dates, volume/issue folio text** — no
  `doi` / `volume` / `issue` / `date-received` running-slot enum values; the
  footer renders `runningtitle` + `page` only.

## Prior format.yml — corrections
The stale `format.yml` already **validated clean (0 errors)** — unlike some
sibling styles, it carried no invalid keys, weights, or out-of-enum values,
so there is no error table to resolve. The edits below are **fidelity /
measurement corrections** and added tokens, not error fixes:

| Was | Now | Why |
|---|---|---|
| `title.scale: 2.38` | `2.2` | match the stylesheet's declared title scale (firstpage measures 2.14) |
| `headings.h1.scale: 1.1` / `h2: 1.05` / `h3: 1.0` | `1.14` / `1.0` / `0.93` | match the specimen ratios (16/14/13 px over 14px body) |
| `title.abstract.size: 1.18` | `1.05` | correct standfirst/body ratio (13.4/12.6 px) |
| `typography.mono_scale: 0.9` | `0.85` | measured code/body ratio ~0.84 |
| (comment) "margin narrow = 0.85in" | measured margins kept | schema `narrow` is 0.75in; the comment mis-stated the scale, so measured inches are authoritative |
| lead-abstract "mockup-only, no token" comment | expressed via `label_style: none` + `weight: bold` | both `impl` — the unlabelled bold standfirst is expressible now; the old comment was stale |
| (absent) | `+ headings.h4.color: text` | pin h4 to black; else it falls through to the accent default |
| (absent) | `+ code.background/border + color.code_bg` | capture the tinted bordered code panel in the page model |
| (absent) | `+ quote.rule/color/indent` | capture the left accent-rule blockquote in the stylesheet |
| (absent) | `+ figure.caption.label_style: bold`, `table.caption.position: above`, `typography.justification: justified` | complete the caption/justification intent (all declared-inert) |
