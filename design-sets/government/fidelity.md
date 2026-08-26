# government — fidelity report

Rebuilt 2026-07-18 from `government-{stylesheet,title,firstpage,page}.dc.html`.
Validates clean against `schema.yml` (0 errors; the prior 18 are resolved — see
bottom). Categories: **exact** (renders as modelled today), **approximated**
(right token, coarser than the model), **declared-inert** (valid token, but
`status: new`/`port` — validates, not yet rendered by the engine), **not
expressible** (needs new schema vocabulary). The stylesheet is the explicit
token spec sheet; title/firstpage/page are rendered intent (measured in px,
in = px/96, pt = px*0.75).

## Exact
- Typeface Source Serif 4 body/heading, Fira Code mono; base 10pt;
  line-height 1.32; justified; microtype on; mono at 0.9.
- Palette: text `#1C2126`, accent navy `#1A3A5C`, muted `#5A636B`,
  rule `#C7CDD3`.
- Single column, US Letter, `normal` (1in) margins taken from the body page.
- Numbered sections (`1.`, `2.`); navy bold h1/h2, near-black bold h3.
- Flush-left title (`title.align: left`), title colour left at the `text`
  default (opener title is near-black `#14181C`), with a navy rule below it
  (`title.rule.position: below`, `.color: accent`, `.weight: thick` — all impl).
- Roman (non-italic) subtitle deck (`title.subtitle.style: normal`).
- `table.style: grid` — full cell borders — with a bold header row
  (`table.header.weight: bold`). `table.style` is `status: impl`, so the grid
  renders today (the old format's "booktabs only" comment is stale).
- Code unhighlighted (`code.highlight: none`).
- Folio bottom-right in the footer with a footer rule (both inherited defaults),
  matching the page-1 and page-2 footers.

## Approximated
- **Heading scales** h1 `1.3`, h2 `1.1`, h3 `1.0`. The stylesheet specimen
  grades h1/h2/h3 at 18/15/13px on a 14px body (~1.29 / 1.07 / 0.93); the body
  pages render section heads at 17px on 13.5px (~1.26). Values chosen between.
- **Title scale** `2.2` — the stylesheet spec value (30px opener title / 13.5px
  body ~= 2.2). The cover title (`government-title`) is larger at 40px (~2.96);
  the flush-left opener governs.
- **Title rule weight** `thick` (2pt) for the model's 2px (=1.5pt) navy
  divider — nearest scale step.
- **Abstract label** `title.abstract.label_style: heading` for the "Highlights"
  panel label (a navy filled bar over the block). `heading` (label over the
  block) is the nearest of `[heading, runin, none]`; the filled label-bar and
  the box around it are not expressible (below).
- **Zebra stripe** `table.zebra_color: code_bg`, with the `#F2F5F7` tint
  re-homed into the otherwise-unused `color.code_bg` role (code is unhighlighted
  and no code blocks appear, so there is no side effect). No dedicated
  stripe-colour token exists.
- **Running head** `header_footer.header.left: runningtitle` structurally
  reproduces the ruled top running line, but renders the document's short title,
  not the model's fixed "Statistical Bulletin" series label (below).
- **Margins** `normal` (1in) from the body page (sides 76px ~= 0.79in, top
  46px ~= 0.48in); the masthead bleeds past the margin — see not expressible.

## Declared-inert (valid, awaiting engine wiring)
- `title.layout: report` — `status: port`. The report archetype (heavy rule,
  institution line) is not yet wired; today it degrades to a plain flush-left
  title. The navy rule is supplied independently via `title.rule.*` (impl), so
  the flush-left title + navy divider still render.
- `title.date.show: true` — `status: port`. The "Issued July 2026" date line
  won't render until the date port lands.
- `figure.caption.position: above` — `figure.caption.*` is `status: new`. The
  spec sheet lists "caption above"; the body page renders the figure caption
  below. Either way the token is inert until figure captions are wired.
- `table.zebra_color: code_bg` — `status: new`. The grid borders and bold header
  render; the zebra body-row tint does not until zebra colour is wired.
- `color.accent2` (gold) and `color.code_bg` — `status: new` colour roles.
  They validate; `accent2` has no renderable hook of its own (the gold stripe is
  not expressible), and `code_bg` only feeds the inert `table.zebra_color`.

## Not expressible (needs new schema vocabulary)
- **Agency masthead band** — the solid navy full-bleed band carrying the agency
  name ("Bureau of Household Statistics") and division line. There is no bleed
  concept and no masthead/agency token; margins are set from the body page and
  the band is dropped. This is the largest single gap.
- **Gold accent stripe** under the masthead and under the running head.
  `color.accent2` records the colour, but no token draws a secondary-colour
  bleed stripe.
- **Navy table-header fill + white (knockout) header text** — `table.header`
  exposes only `weight`, `case`, `rule_below`; there is no header background or
  header text-colour token. The header renders as bold text on the grid, not
  white-on-navy.
- **Table source note** — the "Source: …" line below each table. `table` has no
  notes token (`table.caption.position` governs the title, not a footnote).
- **Tabular / lining figures** in the money columns — `typography.numbers` is
  `lining`/`oldstyle` only; there is no tabular-figures control.
- **Boxed "Highlights" panel** — the border + tint + navy label-bar around the
  bulleted highlights. The abstract renders as a plain labelled block; no
  panel/box token exists.
- **Report-series line** — "Statistical Bulletin · Report 2026-14 · Issued
  July 2026" and the report number. No series / report-number token.
- **Running-head and footer content slots** — the running head's left ("Statistical
  Bulletin" series label) and right ("Report 2026-14 · Page N"), and the footer's
  agency-name left slot, have no matching enum value (`header_footer.*` values are
  `title/runningtitle/author/surname/section/page`). The report-number prefix on
  the folio and the agency footer slot are dropped; the folio itself survives.
- **Mono byline** — "Prepared by J. N. Cohen, …" is set in Fira Code in the
  model; the byline uses the body/heading face and there is no per-byline font
  token. (`title.byline.color` muted matches by default.)
- **Technical-note callout** — the gold-ruled, tinted blockquote on the body
  page. `quote.rule`/`quote.color` can add a left accent rule and colour, but
  the gold tint-panel treatment isn't expressible; it degrades to a plain quote.

## The 18 prior validation errors — resolved
| Was | Fix |
|---|---|
| `color.table_header_bg: accent` (no such key) | dropped → navy table-header fill not expressible |
| `color.table_header_fg: "#FFFFFF"` (no such key) | dropped → maps to `color.knockout` default; header text not wired to tables (not expressible) |
| `color.table_stripe: "#F2F5F7"` (no such key) | hex re-homed → `color.code_bg: "#F2F5F7"`, referenced by `table.zebra_color` |
| `title.banner: true` (no such key) | dropped → masthead band not expressible |
| `title.banner.color: accent` (no such key) | dropped → masthead band not expressible |
| `title.banner.rule.color: accent2` (no such key) | dropped → gold stripe not expressible (`accent2` kept in palette) |
| `title.agency.show: true` (no such key) | dropped → agency line not expressible |
| `title.series.show: true` (no such key) | dropped → report-series line not expressible |
| `title.abstract.style: box` (no such key) | → `title.abstract.label_style: heading`; boxed panel not expressible |
| `table.header.background: table_header_bg` (no such key) | dropped → navy header fill not expressible |
| `table.header.color: table_header_fg` (no such key) | dropped → white header text not expressible |
| `table.header.weight: semibold` (invalid enum) | → `table.header.weight: bold` |
| `table.stripe: table_stripe` (no such key) | → `table.zebra_color: code_bg` |
| `table.figures: tabular` (no such key) | dropped → tabular figures not expressible |
| `table.notes.position: below` (no such key) | dropped → source note not expressible |
| `table.notes.label: Source` (no such key) | dropped → source note not expressible |
| `header_footer.footer.left: agency` (value outside enum) | dropped (default `none`) → agency footer slot not expressible |
| `header_footer.footer.right: report-page` (value outside enum) | → `page` (default; folio bottom-right, report-number prefix not expressible) |
