# docdesigner 0.9.1

The design layer, as far as it can go without the template port.

- **Tier 1 complete.** Every remaining token the shipped styles declared and
  the engine ignored now renders: figure caption position (via `floatrow`),
  the opening drop cap (via a Lua filter), code line numbers, and the
  `accent2`/`code_bg` colour roles. Declared-but-inert tokens are down from 28
  to 6, and the schema from 102 implemented to 134.
- **The masthead band.** `header_footer.header.{fill,color}` draw a colour band
  across the full paper width, not just the text block -- the Economist red
  flag and the government navy masthead. These are the two styles that did not
  resemble their models, and this is the furniture they were missing.
- **Unhighlighted code no longer escapes its column.** `vset` governs
  fancyvrb environments only, and `code.highlight: none` makes pandoc emit
  LaTeX's built-in `verbatim`, which ignored line breaking entirely. Ten of the
  twelve styles set `highlight: none`; it was visible only in economist, whose
  two columns are narrow enough that the overflow landed on the neighbouring
  column rather than in the margin.
- Running heads no longer overprint: `\headheight` scales with the base size,
  which a two-line head needs and the previous hardcoded 14pt could not hold.
- `footnotes.size` emitted a malformed macro and would break any document with
  a footnote. No specimen had one, so it rendered clean for two commits.
- The specimen gained a captioned table and a footnote, which is what exposed
  the two defects above.

Still incomplete, by design: no style has a true title *page* (that needs the
LaTeX template port), and `policy` awaits its original redesign.

# docdesigner 0.9.0

**Renumbered.** Versions previously tagged 1.0.x were pre-release development,
not a 1.0 release. The series is renumbered to 0.9.x so that **1.0 can mean
"released after beta"**. No code was reverted: 0.9.0 is the state formerly
called 1.0.9 plus the design-token work below.

Everything from the 1.0.4-1.0.9 entries below is included in 0.9.0.

### Design tokens wired (tier 1)

Twenty-eight tokens were declared by the shipped styles, validated clean, and
then silently ignored by the engine. These now render:

- `quote.{indent,style,color,rule}` -- ten styles.
- `figure.caption.{color,size,align,family,label_style}` -- ten styles.
- `headings.run_in` -- six styles; h3 now runs into its paragraph where asked.
- `typography.{numbers,justification}`, `paragraph.indent_after_heading`,
  `table.{size,zebra_color}`, `footnotes.{size,numbering}`.
- `table.header.{weight,case}`, via a Lua filter -- pandoc gives the header row
  no macro for the preamble to hook.
- `title.{case,byline.case,date.show,abstract.rule}`.

Left deliberately unimplemented rather than faked: `links.underline`,
`table.header.rule_below`, `color.background` (ambiguous -- already works as a
colour role; painting the page with it would be a regression), and
`title.keywords.*` (pandoc puts keywords in PDF metadata, not the body).

# docdesigner 1.0.9 (superseded numbering)

- Alpha distribution is by tarball rather than `install_github()`, because the
  GitHub repository is private and a tester cannot reach it. `TESTING.md` now
  gives the local install and an email address for reports; `README.md` no
  longer points at `TESTING.md` with a relative link, which is dead for anyone
  who received only the tarball.

# docdesigner 1.0.8

- Completes the pandoc flag fix 1.0.7 started. **`--highlight-style` is
  deprecated too**, and that is the branch 11 of the 12 styles take, so 1.0.7
  removed the warning only from `economist` and left it on almost every other
  render. Both spellings now become `--syntax-highlighting=<none|style>` on
  pandoc 3.2 and later. Verified as zero deprecation warnings across a full
  12-style run, and that highlighting still applies (`tango` emits
  `\Highlighting` macros, `none` emits plain verbatim).

  1.0.7 shipped incomplete because its check grepped for the exact string just
  fixed rather than for deprecation warnings in general. Match the class, not
  the instance.

# docdesigner 1.0.7

- Styles with `code.highlight: none` made pandoc print
  `Deprecated: --no-highlight. Use --syntax-highlighting=none instead.` on
  **every render**. `dd_preamble()` now emits the new flag on pandoc 3.2 and
  later and keeps the old one below that, so no supported pandoc either warns
  or breaks. The version gate is deliberately conservative: guessing the
  boundary too early would be a hard error on an older pandoc, guessing late
  costs only a cosmetic notice.

# docdesigner 1.0.6

- **`html()` leaked script and stylesheet contents into the body.** The format
  exists to produce body HTML safe to paste into a CMS, and it was doing the
  opposite: the body-only pass dropped the `<script>`/`<style>` tag lines but
  kept everything between them, so the JavaScript and CSS survived as bare
  text. A trivial document rendered six lines of jQuery into its output, which
  a CMS would publish as visible paragraphs. Blocks are now removed whole,
  one-liners included. Found by smoke-testing the output formats that recent
  work had not touched; `snapshot()` was fine.
- CI: `R CMD check` runs on ubuntu and windows on every push and pull request,
  and the pkgdown site rebuilds and redeploys on every push to `main`. Both
  gaps had already caused a failure — the check had never run before 1.0.5, and
  the published site had gone stale invisibly.

# docdesigner 1.0.5

Documentation and portability. No engine or style changes: every style resolves
and renders exactly as it did in 1.0.4.

- `R CMD check` on the built tarball is now **Status: OK** — no errors,
  warnings or notes. It had never been run. It caught one real defect: a
  literal em dash in a string literal in `R/ai_brief.R`. Portable packages must
  keep non-ASCII out of R code, comments aside; replaced with the `—`
  escape, so the generated brief prints identically.
- **The style tables were describing styles that no longer shipped.** Promoting
  the rebuilt styles in 1.0.4 silently falsified them: all ten documented accent
  colours were wrong, `economist` was listed as one column when it sets two, and
  `sociology` and `ajs` were missing. The gallery vignette ships in the tarball
  and renders on the pkgdown site, so this was a reviewer's first contact with
  the package.
- The Style Gallery vignette now **generates** that table from the installed
  styles at build time, reading the resolved tokens, so it cannot disagree with
  what ships. `USER-MANUAL.md` no longer duplicates the per-style values —
  duplicating them is what produced the drift — and points at the vignette and
  `designer_styles()` instead.
- `README.md`: the academic set listing gains `sociology` and `ajs`; two stale
  known-limitations entries corrected (the styles are no longer "ten styles in
  ten accent colours", and `examples/fontset-*.Rmd` no longer exists).
- Added `TESTING.md` for pilot reviewers: setup, four graded tasks, an explicit
  list of the six known-incomplete areas not worth reporting, and what makes a
  bug report actionable. Not shipped in the tarball; read it on GitHub.

# docdesigner 1.0.4

- **All 12 rebuilt styles are now the shipped styles.** `inst/sets/` held the
  thin v1 files while the rebuilt, schema-clean `format.yml` lived only in the
  `design-sets/` workshop, so the package installed last-generation styles no
  matter how clean the run report looked -- the report renders the workshop
  drafts, not the installed sets. `sociology` and `ajs` were designed but
  belonged to no set; both join `academic`. Both sets go to 2.1.0.
- Font validation no longer contradicts the engine. `dd_preamble()`
  deliberately supports naming an unbundled system face, guarded by
  `\IfFontExistsTF` so an absent font degrades to the body face; the validator
  rejected exactly that as an unknown font. `schema.yml` gains `system_fonts:`.
  Unknown families are still rejected.
- `NAMESPACE` is generated by roxygen2 again. It had lost its header, so
  `devtools::document()` silently skipped it on every run. The generated file
  is identical to the hand-maintained one it replaces.
- The build tooling (`run.R`, `render-design-sets.R`, `verify-tokens.R`) moved
  into `dev/` and is version-controlled. Paths derive from each script's own
  location rather than a hardcoded absolute path.
- `verify-tokens.R`'s two-column detector no longer counts running heads and
  folios as body text, and requires enough body lines on a page for the ratio
  to mean anything. It had been reporting single-column `atlantic` as
  two-column off a 7-line final page.
- Test suite: the scaffolding tests asserted on tokens the thin `minimal`
  happened not to declare, so they silently stopped testing defaults once the
  rebuilt `minimal` declared them. They now compare against the seed style's
  own file and cannot rot the same way.

- Added `designer_import_claude_design()`: drafts a `format.yml` from a
  Claude Design "standalone HTML" export by extracting colour, font, and
  type-scale tokens mechanically. Structural tokens (`title.layout`,
  `page.columns`, etc.) are deliberately never guessed: they are left at the
  seed style's value and named in the printed report, for you to set by hand.
  See `?designer_import_claude_design` and `STYLE-SPEC.md`. Adds `xml2` to
  `Suggests`.
- Added `designer_ai_brief()`: generates a Markdown design-constraint brief
  from `inst/engine/schema.yml`, meant to be handed to Claude Design (or any
  design tool/collaborator) before designing a new style.
- **Breaking:** `designer_install_set()`
  signature changed from `(repo, ref, overwrite)` to
  `(set = NULL, repo = "jncohen/docdesigner", ref = "main", overwrite = FALSE)`.
  The canonical style-set library is now one GitHub repo
  (`jncohen/docdesigner`, the package's own repo, `inst/sets/<set>/`)
  instead of one repo per set. `designer_install_set("academic")` now pulls
  the current GitHub state of a bundled set; a dedicated single-set repo
  still works via `designer_install_set(repo = "owner/repo")`. Old-style
  calls passing a repo slug as the first argument now install the wrong
  thing (a `set` id, not a `repo`) — update any saved calls.

# docdesigner 1.0.3

Fidelity fixes found by comparing rendered specimens against style-set
mockups (the per-style findings live in `design-sets/<style>/fidelity.md`):

- **Page margins were never applied at all.** `rmarkdown::pdf_document()`
  appends its own `geometry:margin=1in` after the engine's pandoc `-V` args;
  geometry lets later options win, and `margin` sets all four sides at once.
  So every style has silently rendered at 1in margins regardless of what
  `page.margin` declared, for as long as the engine has existed. The geometry
  options are now also emitted as `\geometry{...}` from `dd_preamble()`, which
  is injected after `\usepackage{geometry}` and so has the last word.
- **`page.margins.top/bottom/inner/outer` and `page.twoside`** are now wired
  (`status: new` -> `impl`). `page.margin` remains a shorthand for all four
  sides and is still the fallback for any side left unset. Previously the
  only margin control was a 3-step scale (0.75/1/1.35in) applied uniformly,
  which no real page design uses: every mockup in `design-sets/` specifies a
  different top, side, and bottom. Under `twoside`, `inner`/`outer` become
  binding edges and the class option is set so running heads alternate.

- **`title.color`**: new token (role). Previously the title was *always*
  rendered in `\color{accent}` regardless of what a style set declared; now a
  style can override it. **The default is `text`, not `accent`**: measuring
  every mockup in `design-sets/` found that ten of eleven specify a near-black
  title (`#1c1913`, `#14140F`, `#111`, ...) and not one asks for an
  accent-coloured one. Defaulting to `accent` would have preserved the old
  hardcoded bug's behaviour as the vocabulary's recommended value.
- **`title.scale`** corrected in eight style sets against the measured `<h1>`
  size in each mockup (e.g. atlantic 2.6 -> 3.68, ssrn 1.7 -> 1.31).
- **`title.subtitle.scale/style/color`** are now wired (`port` -> `impl`).
  These could not be implemented before for a structural reason: pandoc's
  LaTeX template appends the subtitle to `\@title` at a fixed `\large`,
  inheriting the title's face and colour, so no preamble could reach it. But
  pandoc defines `\subtitle` with `\providecommand` — only if undefined — and
  rmarkdown injects our preamble *before* that line. `dd_preamble()` now
  defines `\subtitle` itself, pre-empting pandoc's, which is what makes the
  subtitle independently styleable. The same lever is available for any other
  `\providecommand` the template declares.
- **`title.rule.length`**: new token. The title rule was always `\linewidth`;
  a short centred rule is a distinct design move (atlantic's masthead uses
  64px). Omit for the full measure.
- **The abstract is now designable.** `abstract` is an environment the document
  class defines and pandoc emits verbatim, so `dd_preamble()` renews it and
  takes it over — the same lever as `\subtitle`, and the reason the whole
  `title.abstract.*` family could sit at `status: port`. Every style previously
  got the same centred bold "Abstract" heading regardless of what it declared.
  `title.abstract.size` and `.label` are now `impl`; new: `.show` (false
  suppresses it entirely), `.label_style` (`heading` | `runin` | `none`),
  `.indent` (inset from both margins), `.weight` (`bold` gives a standfirst),
  and `.color`. Applied: demography gets its run-in small-caps label and
  double inset, nature a bold unlabelled standfirst, atlantic none at all.
- **Style files corrected against the schema.** `designer_validate_style()`
  existed but nothing called it, so six styles named tokens that do not exist
  and rendered "OK" regardless — 78 errors in total. Notably
  `headings.case: smallcaps` (demography, humanities): case is per-level, so
  the global key silently did nothing and both styles' stated signature had
  never once rendered. Also `typography.oldstyle_figures` ->
  `typography.numbers`, `notes.*` -> `footnotes.*`, `headings.h3.run_in` ->
  `headings.run_in`, `title.rule.width` -> `title.rule.length`.
  `run.R` now validates every style after install and reports the error count,
  so this cannot rot silently again.
- **Heading weight was inverted.** `dd_preamble()` maps anything that isn't
  exactly `bold` to `\mdseries`, so a style asking for `semibold` (demography,
  government) or `medium` (humanities) rendered *lighter* than the `bold`
  default it would have got by saying nothing. Those values were never in the
  enum; the bundled faces ship Regular and Bold only.
- **`title.align`**: now wired (`status: port` -> `impl`). `center` centres
  the whole title block (title, rule, byline, date), not just the title
  line.
- **h4 headings** (`\paragraph`) are now styled via the same `headings.h4.*`
  tokens the schema already declared but never wired: scale, weight, style
  (italic), case, color, spacing, rule. Rendered as a run-in heading and
  **never** carries a numeric label, fixing a bug where `headings.number_sections:
  true` styles leaked a raw cascading counter (e.g. "1.1.1.1") in front of
  every h4.
- **`headings.<h>.case`**: added `lower` and `smallcaps` (previously only
  `upper` was implemented; the other two silently no-opped).
- **`headings.<h>.style`** (italic) and **`headings.<h>.align`** (left/
  center/right) are now wired for all heading levels (previously
  `status: new`, i.e. declared but inert).
- **`header_footer.header.*`**: running headers are now wired the same way
  the footer already was (`status: port` -> `impl`). Also fixed the
  content switch, which previously only implemented `page`/`title` and
  silently fell back to the page number for `author`, `surname`, `section`,
  and `runningtitle`. `\headheight` is widened to 14pt when a header is
  declared, since LaTeX's 12pt default is too small for a populated running
  head and fancyhdr warns and overprints; header-less styles are untouched.
- **`headings.number_sections`**: h2 and h3 now actually carry their numbers.
  Only `\section` was ever given a titlesec label, so `\subsection` and
  `\subsubsection` were formatted with an empty label and silently dropped
  their `1.1`/`1.1.1` counters. Each level now takes its own counter. h4
  remains unnumbered by design.

Not yet addressed (tracked per style in `design-sets/<style>/fidelity.md`):
`title.layout` archetypes (`journal`/`essay`/`report`/`masthead` still all
render as `plain`), the remaining `title.subtitle.*`/`byline.*`/
`abstract.*`/`keywords.*` port tokens, and `table.style` (`grid`/`zebra`/
`minimal` still inert; only `booktabs` renders).

# docdesigner 1.0.2

- Added a **token-driven style engine**. A style is a flat dotted-key
  `format.yml` of design tokens, resolved through a full `inherits` chain
  (keyed on the declared `id`, not the folder name) into a LaTeX preamble and
  a `pdf()` output format.
- Added a token **schema** (`inst/engine/schema.yml`) as the single source of
  truth for the vocabulary. `designer_validate_style()` reports unknown keys,
  bad values, malformed colours, and undeclared fonts; `designer_tokens()`
  returns the schema. Every token carries an implementation status.
- Introduced distributable **style sets** with `designer_sets()`,
  `designer_install_set()`, and `designer_update_sets()`, plus a set-aware font
  registry that resolves faces style → set → core.
- `designer_new_style()` scaffolds a style from an existing one's declared
  tokens (`complete = FALSE`) or the full schema (`complete = TRUE`).
- `designer_specimens()` renders one specimen PDF per style plus a gallery index.
- Two-column styles (e.g. `nature`) convert tables to spanning `table*` floats,
  so they render with tables intact.
- Retired the legacy `inst/styles/` resolver; `snapshot()` now sources its
  style tokens from the engine's `policy` style.
- Added `STYLE-SPEC.md`, the format-version-2 token reference.

# docdesigner 1.0.1

- Reduced the public output API to `pdf()`, `html()`, and `snapshot()`.
- Added `designer_use()` starters for PDF, HTML, and Snapshot.
- Added `designer_check()` for setup diagnostics.
- Added `designer_update_templates()` for refreshing local editable assets.
- Added a user manual with a style gallery and style-authoring instructions.
- Made Snapshot a fixed official style with optional plain HTML companion output.
- Added plain body HTML output for CMS publishing.
