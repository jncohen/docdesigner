# policy — fidelity report

Rebuilt 2026-07-18 from `policy-{stylesheet,title,firstpage,page}.dc.html`.
Validates clean against `schema.yml` (0 errors; the prior 13 are resolved — see
bottom). Categories: **exact** (renders as modelled today), **approximated**
(right token, coarser than the model), **declared-inert** (valid token, but
`status: new`/`port` — validates, not yet rendered by the engine), **not
expressible** (needs new schema vocabulary). The stylesheet is the explicit
token spec sheet; title/firstpage/page are rendered intent (measured in px,
in = px/96, pt = px*0.75). The style targets the flush-left opener
(`policy-firstpage`), not the full-page cover (`policy-title`).

## Exact
- Typeface Source Serif 4 body/heading; Fira Code mono for the wordmark,
  kickers, labels and folios; base 10.5pt; line-height 1.4; justified;
  microtype on (all per the stylesheet spec sheet).
- Palette: text `#21262B`, accent `#C1442A` (kicker/stats/rules/callout/links),
  muted `#7A828A`, rule `#DBDFE3`. A single assertive accent over near-black.
- Single column; `page.margin: normal` (1in) exactly as the stylesheet declares.
- Unnumbered, bold, near-black section heads (`headings.*.color: text`) — the
  accent is reserved for kicker/stats/rules, never the running heads.
- Booktabs tables with a bold header; code unhighlighted (`none`).
- Folio in the footer-right slot with a hairline rule above
  (`footer.right: page`, `footer.rule: true`) — matches the "…No. 47 · 1"
  footer of the opener and body pages. No second folio is emitted.
- Flush-left title, `title.align: left`, following the opener.

## Approximated
- **Title rule weight** `thick` (2pt ≈ 2.67px) for the model's 3px accent rule
  under the byline — nearest `rule_weight` step (the cover variant runs 4px ≈
  `heavy`, but the opener governs).
- **Title scale** `2.5` from the opener headline (35px / 14px body). The cover
  page sets it larger (46px ≈ 3.3); the opener is the target.
- **Subtitle/deck scale** `1.35` from the opener deck (18px / 14px body); the
  cover deck runs 21px (≈1.5). `title.subtitle.style: normal` because the deck
  is a large *roman* muted line, not the schema's default italic subtitle.
- **Heading scales** h1 `1.35`, h2 `1.1`, h3 `1.0` from the stylesheet specimen
  (19 / 15 / 13px on a 14px body). Body-page section heads render a touch larger
  (16–18px ≈ 1.14–1.28); values follow the stylesheet spec sheet.
- **Paragraph spacing** `sm` (0.5em) for the model's 0.7em inter-paragraph
  gap — nearest scale step, with no first-line indent (modern block setting).
- **Margins** taken as `normal` (1in) per the stylesheet; the body-page mockup
  lays text on 72px (0.75in) side padding and a tight 40px top, but the declared
  design token is `normal` and the cover's full-bleed masthead (padding 0) is
  not expressible (see below).

## Declared-inert (valid, awaiting engine wiring)
- `title.layout: report` — `status: port`. The flush-left report opener (heavy
  rule, institution line) is the intended archetype; until the port lands the
  title degrades to a plain flush-left headline + subtitle + rule.
- `title.subtitle.scale`, `title.date.show` — `status: port`; the deck sizing
  and the "July 2026" date line render once those ports land.
- `title.byline.color` — the byline colour hook is `port` (renders text ink).
- `quote.style` / `quote.rule` / `quote.color` — `status: new`. The stylesheet
  block quote (left accent rule, muted roman text) validates but is not yet
  wired; today it renders as an ordinary indented quote.
- `figure.caption.*` — `status: new`; caption-below / muted validates, awaiting
  the figure engine.

## Not expressible (needs new schema vocabulary)
- **Full-bleed accent masthead / footer band** — the cover's coloured band runs
  to the trim edge with zero page padding (`padding: 0`, accent footer band).
  The token vocabulary has no bleed or full-width-band concept; ordinary
  `normal` margins are set from the body model instead.
- **Wordmark / brand line** — "Meridian **Institute**" (two-tone Fira Code
  wordmark) at the top of every page. No brand/wordmark token; `title.layout`
  names an "institution line" but exposes no brand string or styling.
- **Coloured category kicker** — "Economic Mobility · No. 47" in accent
  small-caps mono above the title. No `kicker` token.
- **The tinted "By the numbers" stat rail** — the two-column opener region with
  a `#FBF3F1` tint panel and oversized accent figures (40px 3× / 68% / 0.03).
  No float/sidebar primitive, no panel-tint colour role, and it exceeds
  `page.columns: 1`. The most design-forward element; mockup-only.
- **Recommendation callout** — the left-accent-rule tinted box ("Recommendation
  …") on the opener. No callout primitive and no panel-tint colour role.
- **Tint wash colour** `#FBF3F1` — used behind the stat rail and callout. The
  colour roles are [accent, accent2, text, muted, rule, background, code_bg,
  knockout]; none is a panel tint (`background` would flood the whole page), so
  the wash cannot be declared.
- **Brand + series running head / footer line** — "Meridian Institute · Policy
  Brief No. 47" repeated top (running head, ruled) and bottom-left (footer). The
  header/footer enum offers only [none, title, runningtitle, author, surname,
  section, page]; brand and a series number ("No. 47") are neither. Header slots
  are left off (an empty header rule would otherwise draw); footer-left dropped.
- **Byline role line** — "Senior Fellow" precedes the date in the byline row.
  The byline carries no affiliation/role token.
- **Numbered recommendation list & big centred pull-quote** — the accent
  circled "1/2/3" list markers (body page) and the 25px centred accent
  pull-quote are bespoke layout; `quote.*` has no align/scale, and list-marker
  styling has no token.

## The 13 prior validation errors — resolved
| Was | Fix |
|---|---|
| `color.tint: "#FBF3F1"` (no such colour role) | dropped → tint wash not expressible (no panel-tint role) |
| `title.brand.show: true` (no such key) | dropped → wordmark/brand line not expressible |
| `title.kicker.show: true` (no such key) | dropped → coloured kicker not expressible |
| `title.kicker.color: accent` (no such key) | dropped → kicker not expressible |
| `title.subtitle.style: deck` (invalid enum value) | → `title.subtitle.style: normal` (+ `title.subtitle.scale: 1.35`); the deck is a roman muted line |
| `callout.style: rule` (no such key) | dropped → recommendation callout not expressible |
| `callout.color: accent` (no such key) | dropped → callout not expressible |
| `callout.background: tint` (no such key) | dropped → callout not expressible |
| `callout.label.color: accent` (no such key) | dropped → callout not expressible |
| `sidebar.style: tint` (no such key) | dropped → stat rail not expressible (no float/sidebar) |
| `sidebar.stat.scale: 3.0` (no such key) | dropped → stat rail not expressible |
| `sidebar.stat.color: accent` (no such key) | dropped → stat rail not expressible |
| `header_footer.footer.left: brand-series` (invalid enum value) | dropped → brand+series footer line not expressible (enum has no brand/series) |
