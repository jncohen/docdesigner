# economist — fidelity report

Rebuilt 2026-07-18 from `economist-{stylesheet,title,firstpage,page}.dc.html`.
Validates clean against `schema.yml` (0 errors; the prior stale-format issues
are resolved — see bottom). Categories: **exact** (renders as modelled today),
**approximated** (right token, coarser than the model), **declared-inert**
(valid token, but `status: new`/`port`/`risk` — validates, not yet rendered by
the engine), **not expressible** (needs new schema vocabulary). The stylesheet
is the explicit token spec sheet; title/firstpage/page are rendered intent
(measured in px, in = px/96, pt = px*0.75).

## Exact
- Two columns (`page.columns: 2`); Source Serif 4 body + heading (Milo Serif
  substituted), Fira Code mono at 0.9x; base 9pt; A4 (spec-sheet token).
- Palette: text `#111111`, accent `#E3120B` (the Economist red — flag, kicker,
  rules, links), muted `#6E6E6E`, rule `#C9C9C9`.
- Unnumbered small BLACK bold serif cross-heads (`headings.h*.color: text`),
  flush left, no rule — matching the model's near-black cross-heads, not the red.
- **Black flush-left headline** (`title.color: text`, `title.align: left`): the
  single most important correction — the headline is black, the red is furniture.
- Short red rule below the headline (`title.rule` below / heavy / accent).
- First-line indent, no inter-paragraph space (`paragraph.indent: sm`,
  `spacing: none`); indent suppressed after headings (engine default).
- Booktabs table with a bold header; code unhighlighted (`code.highlight: none`).
- Continuation running head (running title | author) under a hairline
  (`header.left/right`, `header.rule: true`); folio CENTRED at the foot
  (`footer.center: page`, `footer.right: none`, `footer.rule: false`).

## Approximated
- **Line height** `1.12` — the spec-sheet Typography row and its body specimen
  declare 1.12 (tight Economist leading); the rendered two-column pages set the
  body looser at ~1.36. The spec-sheet token wins; body pages read a shade
  tighter than the mock.
- **Heading scales** h1 `1.15`, h2 `1.0`, h3 `0.95` — from the spec-sheet
  specimen (16/14/13px on a 14px body). The rendered page cross-heads sit at
  ~1.15 (13.5px on 11.7px), so h2 is a touch smaller here than on the page.
- **Title scale** `3.0` — the spec-sheet Title value. The firstpage headline is
  drawn much larger (~68px), but 3.0 is the declared token; the compact opener
  headline (~33px) is nearer the mark.
- **Paragraph indent** `sm` (1em) — spec-sheet says "indent sm — 1em"; the
  rendered body indents second-and-later paras by `text-indent: 1em`. Exact step.
- **Standfirst → subtitle** `title.subtitle` at scale 1.8, upright, text ink —
  approximates the bold serif deck; the **bold** weight is the gap (see below).
- **Byline** `case: upper`, `color: muted` — the model byline is dark-grey
  (`#444`) Archivo caps; mapped to muted caps in the serif face.

## Declared-inert (valid token, awaiting engine wiring)
- `title.layout: plain`, `title.subtitle.*`, `title.byline.*`, `title.date.show`
  — several are `status: port`; the flush-left title, deck and byline slots are
  metadata-driven and degrade to plain front matter until the title port lands.
- `figure.caption.color`, `code.border`, `code.background` (+ `color.code_bg`),
  `quote.color`, `quote.rule` — all `status: new`: they validate but the muted
  caption ink, the bordered light-grey code block, and the red-ruled quote are
  not rendered yet. The quote follows the STYLE-SHEET specimen (muted, red side
  rule); the page-model pull-quote (black bold italic, red top rule) is a
  second quote treatment the single quote.* block cannot also carry.
- **Drop cap** — `paragraph.drop_cap.lines: 3` is modelled (opening "I"/"N"),
  but the token is `status: new` and rule `dropcap-twocolumn` warns it is
  unreliable under `columns: 2` (`lettrine`). Left UNSET to keep the file
  warning-free; it is both inert and column-fragile today.

## Not expressible (needs new schema vocabulary)
- **The red FILLED flag band** — the white-on-red masthead bar ("Security ·
  Working Papers · Vol. 4 · 2026") that runs across the top of the opener and
  body pages. `header_footer.header.*` has no fill/colour-band token
  (`fancyhdr` emits no `\fancyhead` fill); `header.first_page` is limited to
  `[plain, none]`, so the page-1 running band cannot be requested at all.
- **The red kicker / eyebrow** — "Menacing Taiwan" above the headline. No
  `title.kicker.*` token; it is neither title nor subtitle.
- **The Archivo grotesque-sans label face** — used for the masthead, kicker,
  dateline, captions, table caption, and running head. Font roles are only
  `body/heading/mono`; there is no `typography.label`, and
  `figure.caption.family` offers no sans option, so all labels fall back to the
  serif.
- **Bold standfirst weight** — the deck is bold serif; `title.subtitle` exposes
  only `style` (normal/italic) and `scale`, no weight, so it renders regular.
- **Dateline** — "NEW YORK" set above the byline has no home
  (`title.byline`/`title.date` carry no dateline string).
- **Masthead volume/issue line** — "Working Papers · Vol. 4 · 2026" in the flag
  is page furniture, not a style token.

## Prior stale-format errors — resolved
The previous `format.yml` was a thin ~0.7KB draft; the following were fixed:
| Was | Fix |
|---|---|
| `color.accent: "B21F24"` (wrong red, missing `#`) | → `color.accent: "#E3120B"` (the model red, valid hex) |
| `color.rule: "B21F24"` (accent red, no `#`) | → `color.rule: "#C9C9C9"` (the model's light-grey rule) |
| missing `color.muted` | → `color.muted: "#6E6E6E"` (model muted ink) |
| `title.layout: masthead` | → `title.layout: plain` (flush-left opener; masthead is a one-page treatment the model is not) |
| `title.scale: 2.48` | → `title.scale: 3.0` (the spec-sheet Title value) |
| `title.rule.color: accent` only, no title colour set | → added `title.color: text` (headline is BLACK, the core correction) |
| `headings.h1.scale: 1.32` / `h2: 1.12` | → `1.15` / `1.0` (spec-sheet specimen gradation) |
| no `page.columns` | → `page.columns: 2` (the style is two-column) |
| no folio control (default `footer.right: page`) | → `footer.center: page` + `footer.right: none` (single centred folio) |
| `code.highlight: pygments` | → `code.highlight: none` (spec-sheet: code none / monochrome) |
| missing `page.papersize`, base size only partly set | → `page.papersize: a4`, `base_size: 9pt`, `line_height: 1.12`, `mono_scale: 0.9` |
