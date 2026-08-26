# methods — fidelity report

Rebuilt 2026-07-18 from `methods-{title,firstpage,page,stylesheet}.dc.html`.
Validates clean against `schema.yml` (0 errors). Categories: **exact** (renders
as modelled today), **approximated** (right token, coarser than the model),
**declared-inert** (valid token, but `status: new`/`port` — validates, not yet
rendered by the engine), **not expressible** (needs new schema vocabulary).

## Exact
- Typeface Source Serif 4 body/heading, Fira Code mono; base 10pt; line-height
  1.3; mono scale 0.88×; justified with hyphenation.
- Palette: text `#16181C`, accent `#0F766E` (deep teal), muted `#667085`, rule
  `#D4D9DE`. Links coloured (accent), not underlined.
- Symmetric 1in margins (`page.margin: normal`), single column, US Letter.
- Numbered sections; teal-bold section heads (h1) and subsection heads (h2);
  near-black italic subhead (h3). `headings.*.color`, `.weight`, `.style` are
  all `status: impl` (1.0.3), so these render as modelled.
- Title layout journal, flush-left, title in near-black at scale 2.4, accent
  underline (`rule.position: below`, medium, accent), muted italic subtitle,
  author byline in text ink.
- Paragraphs: no indent, 0.5em spacing (`paragraph.spacing: sm`).
- Booktabs table, bold header, row-stretch 1.15.
- Continuation running head with hairline rule; centred foot folio.

## Approximated
- **Heading scales** h1 `1.5` / h2 `1.2` / h3 `1.0` — measured from the body
  pages (22px section head, ~17px subsection, 15px run-in ÷ 14.5px body). The
  compact spec-sheet previews (19/15/13px) imply slightly smaller ratios; the
  rendered pages are the authority here. Low-confidence on h2 (no `1.1`
  subsection appears in the body models; interpolated from the spec sheet).
- **Title scale** `2.4` is the spec sheet's declared value; the firstpage
  opener actually renders the title a touch smaller (33px ≈ 2.3×) and the full
  title page larger (44px ≈ 3.0×). 2.4 is the canonical middle.
- **Abstract label** `label_style: heading` for the model's small uppercase
  label set *above* the block — `heading` is the nearest (label over the block)
  but it centres in the heading face, where the model shows a left-aligned mono
  accent label. See declared-inert / not-expressible for the boxed treatment.
- **Quote inset** `quote.indent: md` (~1em) for the model's 16px left padding
  beside the accent rule.
- **Running head left** `surname` renders the FULL author name ("Joseph N.
  Cohen") — no name-parsing yet — where the body-page model shows a bare
  "Cohen". Also, the model's left slot combines surname *and* a short running
  title ("Cohen · Wealth by Education"); only one enum value fits per slot, so
  the running-title half is dropped (see not-expressible).

## Declared-inert (valid, awaiting engine wiring)
- **`title.layout: journal`, `title.date.show`, `title.keywords.*`** —
  `status: port`. The journal front-matter treatment (rules, keyword line)
  validates and carries as metadata but renders later; the abstract block,
  byline, and title itself still render.
- **Code hero: `code.background`, `code.border`, `code.line_numbers`** —
  `status: new`. The tint + border + gutter numbers are the signature of this
  style but are not emitted yet; `code.highlight: tango` (impl) still gives the
  light syntax theme, so listings read as intended minus the frame.
- **`figure.caption.position` / `.color`, `table.caption.position`,
  `table.header.weight`** — `status: new`; captions render in engine defaults
  until wired (defaults already match: figure-below, table-above, header-bold).
- **`quote.style`/`.color`/`.rule`/`.indent`** — `status: new`; the italic
  muted note with its left teal rule renders as a plain block quote today.
- **`color.code_bg`** — `status: new` (the hex validates; consumed only once
  `code.background` is wired).
- **`typography.justification`, `links.underline`** — `status: new`; both
  happen to match the engine defaults (justified, no underline), so no visible
  gap.

## Not expressible (needs new schema vocabulary)
- **Mono technical furniture** — the running head, the `Research Note` kicker,
  and the `TABLE 1.` / `LISTING 1` / `FIGURE 1.` labels are all set in Fira
  Code in the models to signal the computational identity. There is no
  `typography.label` role, so those labels fall back to the body/heading face.
  Mockup-only enhancement (the spec sheet's own fidelity note flags this).
- **First-page journal-furniture band** — "Research Note · Methods &
  Measurement · Vol. 4 · 2026" across the top of the opener. No kicker /
  `journaltitle` / `volume` / `issue` running-head enum values exist, and
  `header_footer.first_page: header` is not in this schema's enum ([plain,
  none]), so page 1 stays plain (headerless) — the continuation running head
  (surname · section) applies to pages 2+ only, which matches the models.
- **Abstract call-out box** — the tinted panel (`#F8FAFB`) with a 3px left
  accent border. `title.abstract.*` has no background / box / left-rule token;
  the abstract renders as flowed text with a label.
- **Combined running-head slot** — the left head "Cohen · Wealth by Education"
  packs author + short title into one slot; the enum takes one role per slot.
- **Author affiliation line** ("¹Department of Sociology", italic muted under
  the byline) and the **reproducibility Meta grid** (received/accepted/data/
  code/built) on the title page — both are content with no dedicated style
  token.
- **Opener folio suppression** — the firstpage model shows no folio (title
  metadata fills the foot); with `footer.center: page` the plain page-1 style
  still emits a centred folio. True drop-folio behaviour (suppress on opener,
  present on continuation) has no control.

## Prior validation errors — none
The stale `format.yml` predates these models but already validated clean
against the current schema (0 errors); there were no invalid tokens to remap.
The changes in this rebuild are model-driven, not error fixes:

| Was | Now | Why |
|---|---|---|
| `page.margins.top/bottom/inner/outer` (asymmetric, valid) | `page.margin: normal` | Spec sheet declares a single "margin: normal — 1in"; avoids the margins-override warning |
| `title.scale: 2.48` | `2.4` | Spec sheet's explicit value |
| `headings.h1/h2.scale: 1.4 / 1.15` | `1.5 / 1.2` | Measured from the rendered body-page section heads (22px ÷ 14.5px) |
| `quote.indent: sm` | `md` | 16px left padding measures closer to md (~1em) |
| header slots left as inactive comments | `header.left: surname`, `header.right: section`, `header.rule: true` | Now `status: impl` (1.0.3); the body-page running head is emitted |
| (no folio token) | `footer.center: page`, `footer.right: none` | Centred foot folio per spec sheet "footer: page", without the default right-folio duplicate |
