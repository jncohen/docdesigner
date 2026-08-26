# atlantic — fidelity report

Rebuilt 2026-07-18 from `atlantic-{stylesheet,title,firstpage,page}.dc.html`.
Validates clean against `schema.yml` (0 errors; the prior file's 2 invalid-hex
errors and several mis-valued tokens are resolved — see bottom). Categories:
**exact** (renders as modelled today), **approximated** (right token, coarser
than the model), **declared-inert** (valid token, but `status: new`/`port` —
validates, not yet rendered by the engine), **not expressible** (needs new
schema vocabulary). The stylesheet is the explicit token spec sheet;
title/firstpage/page are rendered intent (measured in px, in = px/96,
pt = px*0.75). The title tokens follow the OPENER (`atlantic-firstpage`), not
the standalone cover (`atlantic-title`).

## Exact
- Palette: text `#1C1913`, accent `#B2332A` (a single editorial red — kicker,
  title rule, pull quotes, links), muted `#8A857A` (decks, captions, heads),
  rule `#CFC9BD` (head/foot hairlines). All `color.*` are `status: impl`.
- Symmetric wide measure: margins top 0.65 / bottom 0.81 / sides 1.375 in,
  single column, `page.twoside: true` (heads and the outer folio alternate
  recto/verso, as the firstpage/page models show).
- Body leading 1.62, justified, microtype on.
- Title (opener): centred, near-black (`title.color: text` — the kicker, not
  the title, is red), `title.scale: 3.4` (54px / 16px body); italic deck; a
  short **accent** rule below it (`thick` = 2pt, `length: 0.667` in = 64px);
  abstract suppressed (`title.abstract.show: false`). Byline in text ink.
- Cross-heads near-black, not accent: h1 centred spaced small-caps bold; h2
  italic bold; h3 italic bold run-in. (`case`/`align`/`style`/`color` on
  headings are `status: impl`, wired 1.0.3.)
- Paragraph: `lg` first-line indent, `spacing: none` (indent-separated, no
  extra leading — no indent/spacing warning).
- Booktabs table with a bold header; links in accent.
- `header.rule: true` and `footer.rule: true` (the models draw a hairline under
  the head and over the foot); outer folio in the foot (`footer.right: page`).

## Approximated
- **base_size `11.5pt`** — the spec sheet declares "~11 pt"; the rendered
  firstpage/page bodies are 16px = 12pt. Split at 11.5pt, and EB Garamond
  (substitute) reads a touch smaller than Libre Caslon at the same size.
- **Two faces collapsed to one** — the models use Libre Caslon Text (old-style)
  for body and Playfair Display (high-contrast didone) for the display title and
  h2 sub-head. No bundled face is a didone; `typography.body` and
  `typography.heading` both map to EB Garamond, so the body/display contrast and
  Playfair's drama at the title are lost.
- **Paragraph indent `lg`** (1.5em) for the model's `text-indent: 1.4em` —
  nearest scale step.
- **Title scale 3.4** targets the opener's 54px title; the standalone cover
  (`atlantic-title`) sets it at 82px — not the port targeted here.
- **Deck colour** `title.subtitle.color: muted` (`#8A857A`); the model deck is a
  darker warm grey `#3A352C`. No role matches it (defining `color.accent2` would
  be `status: new` and ignored), so it renders one step lighter than modelled.
- **h1 `case: smallcaps`** for the model's spaced FULL-caps crosshead (the
  stylesheet labels the treatment "spaced small-caps"); the 0.28em tracking has
  no token. **h1.scale 0.8 / h2.scale 0.95 / h3.scale 0.9** — the crossheads are
  smaller than the body (12–15px on a 16px body); the old file's 1.45/1.18 were
  chasing the title.
- **h2 weight `bold`** for the model's 600 (semibold) — nearest bundled weight.
- **`header.right: runningtitle`** approximates the running head with the article
  title ("The Two Ladders"); the stylesheet's intended head is "masthead · date"
  (see not-expressible).
- **`quote.color: muted`**, **`mono_scale: 0.75`** (code extract 12px / 16px).

## Declared-inert (valid, awaiting engine wiring)
- `title.layout: essay` — `status: port`. The nearest centred layout to the
  model's "feature"; today the opener degrades to plain centred front matter
  carried as body flow (which is in fact what the firstpage model shows).
- `title.byline.color` renders (`impl`), but `title.byline.position: below` and
  `title.byline.case: upper` (the centred uppercase "By Joseph N. Cohen") are
  `status: port` — the byline's placement/casing is not yet controllable.
- `paragraph.drop_cap.lines: 3` (`new`) and `.color: text` (`risk`) — the
  drop-cap opener (model initial ~5.2em, ~3 lines, near-black). Validates; not
  yet rendered.
- `headings.run_in: [h3]` (`new`) — the h3 italic lead-in should sit run-in with
  the paragraph ("On completion. text follows…"); until wired it renders as a
  standalone italic h3.
- `figure.caption.position: below` / `.label_style: italic` and
  `table.caption.position: above` — all `status: new`.
- `quote.style: italic` / `quote.rule: true` / `quote.color: muted` — `new`.
  These describe the left-ruled italic block quotation (accent rule at the left);
  until wired the block quote renders plain.
- `code.background: code_bg` + `color.code_bg` (`#F2EFE7`), and
  `color.background` (`#FBFAF6`, the warm paper) — all `status: new`; validate,
  currently ignored (the extract renders on white, no tint).
- `typography.justification: justified` — `status: new` (the default is already
  justified, so no visible change).
- `header_footer.first_page` is `status: new` and its enum here is `[plain,
  none]` — there is **no `header` value** in this schema version, so "carry the
  running head onto the opener" (which the firstpage model shows on page 1)
  cannot be expressed. Left at the default; the opener's page-1 running head is a
  known gap.

## Not expressible (needs new schema vocabulary)
- **Kicker / eyebrow** — "THE AMERICAN IDEA" in accent spaced caps above the
  title (on both the opener and the cover). No `title.kicker` token exists.
- **Large centred pull-quote** — the display pull-quote on the opener ("We built
  a ladder, and called it a ramp.") is accent, italic, centred, no rule. The
  `quote.*` tokens render the *left-ruled block quotation*, a different object;
  there is no centred display-pull-quote token.
- **Small-caps lead-in** — the opening line runs the first few words in small
  caps after the drop cap ("For most of…"). No lead-in / first-line-caps token.
- **Masthead / publication name** — "The Meridian Monthly" in the running head
  and foot (and the cover nameplate). The header enum offers `title` /
  `runningtitle` but no publication/masthead slot.
- **Date in the running head** — "May 2026". No date value in the header enum.
- **Standalone cover page** — nameplate + centred feature block + full-bleed
  illustration + "Illustration by ——" credit (`atlantic-title`). Needs a
  masthead-page layout, a figure-credit token, and `title.page_break_after`
  (`port`) for the separate leaf.
- **Tracking / letter-spacing** — the kicker (0.26em), byline (0.16em) and
  crossheads (0.28em) are all tracked out; no tracking token.

## Prior errors resolved (was -> fix)
The old ~1.3KB file had **2 hard validation errors** (unprefixed hex) plus
several mis-valued tokens; all now corrected.

| Was | Fix |
|---|---|
| `color.accent: "8F1D14"` (invalid hex — no `#`; also the wrong colour) | `color.accent: "#B2332A"` (model accent red) |
| `color.rule: "8F1D14"` (invalid hex — no `#`; wrong role colour) | `color.rule: "#CFC9BD"` (model head/foot hairline) |
| `color.muted: "#3A352C"` (the deck colour, not the muted role) | `color.muted: "#8A857A"` (palette "muted" swatch) |
| `title.rule.color: rule` (would paint the short rule the grey rule role) | `title.rule.color: accent` (the model rule is red) |
| `headings.h1.scale: 1.45` / `h2 1.18` (chasing the title; crossheads are small) | `h1 0.8` / `h2 0.95` / `h3 0.9` (spaced-caps crossheads) |
| `title.layout: masthead` | `title.layout: essay` (nearest centred layout; both `port`) |
| `code.highlight: kate` | `code.highlight: none` (the extract is unhighlighted) |
| `typography.base_size: "11pt"` | `"11.5pt"` (reconciles spec "~11pt" with the 12pt render) |
| (opener kicker/deck/byline/rule/drop-cap/heads/table largely unauthored) | authored from the models — see sections above |
