# docdesigner (development version)

- **New style: `review`.** A working draft printed to be read and marked up by
  hand, in the academic set. A 3in right-hand margin on every page and space
  between paragraphs
  for handwritten insertions; a short, ragged, unhyphenated measure; line
  numbers (every 5th, per page) and paragraph numbers (continuous) to find a
  mark again in the source; a map of the argument (every heading, its words
  and page) opening the body; the section's claim in the running head; a
  stamp of title, git version and date on every page; and nothing floats.
  `examples/specimen-review.Rmd` shows it on a revised copy of the short
  specimen.
- **New: draft markup tokens, `markup.*`.** Each is off by default, so no
  other style changes: `line_numbers`, `paragraph_numbers`, `flags`
  (`[[TODO]]`, `[[CITE]]`, `[[WEAK]]`, `[[CUT]]`, `[[CHECK]]`, `[[FIX]]` in the
  text print as margin tags; `[[TODO: words]]` keeps the words inline),
  `cite_keys` (each citation's key after it), `map`, `claim_check` (a heading
  of fewer than four words is flagged `[[LABEL?]]`), `changebars` (a rule
  beside each paragraph changed since a reference version) and `floats`.
  New filters `markup.lua` and `headings.lua` carry them.
- **New `pdf()` arguments.** `markup = list(...)` overrides the style's
  markup for one render; `version` sets the version the stamp prints (by
  default the document's git short hash, `+` when it has uncommitted
  changes); `changes_since` names the reference for changebars: a git tag,
  branch or commit, or an earlier copy of the source (default: the latest
  tag). Changebars compare prose: inline R code, citations and numbers are
  ignored, so an `.Rmd` reference works without knitting it.
- **New running-head values and tokens.** `folio` prints page of pages;
  `stamp` the running title, version and date. `header_footer.alternate`
  mirrors the slots under `page.twoside`, so `right` is always the outer
  edge, and the markup (line numbers, flags, changebars) follows the outer
  margin; one-sided, it stays on the right. `header_footer.section_chars` makes `section` name the first level-1
  section starting on the page (else the one carried over), numbered and cut
  to length. `title.warning.auto`, or `warning: auto` in the document, prints
  a stamped "Review draft" line.
- **The 1.25in margin cap exempts a markup style's outer margin**, which is a
  writing workspace rather than a page proportion. `page.margins.outer` now
  accepts up to 3.5in.
- `markup.floats: false` keeps every table a longtable and sets figures with
  `[H]`: in a draft, "the table below" must be below.

- **Underlined links build.** A reference underlined with `{.underline}` and
  holding its URL stopped LaTeX, in every style: soul's `\ul` cannot take
  `\url`. The link now comes out of the underline.
- **Quotes and dashes in heading and label faces.** A heading such as
  *Many Conceptions of "Entrepreneurs"* printed its backticks in styles whose
  headings or labels use a face of their own; those faces now get TeX
  ligatures.
- **review: the footer stamp fits.** A long title wrapped in the foot and ran
  into the folio; the stamp prints the title before its colon, cut at 45
  characters. changebar's `.cb` files are cleaned up after a render.
- **No margin wider than 1.25in.** ssrn (1.9in), humanities (1.75in), atlantic
  and government (1.65in) had side margins wide enough to waste the page;
  all four now use 1.25in. `designer_validate_style()` warns when a style
  sets any margin over 1.25in. The thesis styles are exempt, since the college
  sets their 1.5in binding margin.

# docdesigner 0.11.0

- **New: `kicker:` in the document YAML.** It replaces the label a style sets
  above the title (policy's "Policy Brief", ssrn's "Working Paper"), adds one
  to a style that has none, or with `kicker: ""` removes it. The style's
  `title.kicker.text` is the default.
- **Page 1 starts at the top margin.** titling's `\maketitle` set an empty
  line and 2em of space above the title, and kept the space after it, so the
  first page began a third of an inch or more below every other page. The
  title block now starts where the text block does, in every style.
- **New specimen document.** The specimens and the website gallery now set a
  short household-finance note, *Divorce and Net Worth*, from the public
  2022 Survey of Consumer Finances (`examples/specimen-short.Rmd`, with a
  one-implicate extract built by `dev/make-specimen-data.R`).
- **Design review.** Block quotations are inset further than a paragraph
  indent, with no first-line indent, so they no longer read as ordinary
  paragraphs. Footnotes sit at the foot of the page even when a page ends
  early. Table captions take the figure-caption style and a readable width,
  centred over the table. Small-caps headings are letterspaced. In
  two-column justified styles, hyphenation is cheaper and loose lines rarer.
  Per style: ajs, demography and ssrn set body text at 1.3 leading, atlantic
  and humanities at 1.45; atlantic's and humanities' grey is darker, for
  readable contrast; atlantic's title is smaller; demography's,
  atlantic's and humanities' section heads are larger; bulletin orders its
  title block kicker, byline, date, title and sets its summary in regular
  weight; government's Highlights label is flush left; economist and nature
  set quotations in text colour.
- **Spacing review.** The warning line sits evenly between its two rules.
  Reference lists have a small gap between entries again; the template port
  had restored a full blank line. Keywords print inside the abstract, above
  any closing rule, and never in bold. Headings no longer sit alone at the
  foot of a page. A page-1 note never splits across pages. A page holding
  only floats starts at the top. In a table whose standard errors sit under
  their coefficients, the two rows are shaded and ruled as one.
- **Rules above headings and titles.** `headings.<h>.rule.position: above` and
  `title.rule.position: above` / `both` now place the rule above, as
  sociology's headings and nature's title were designed; both rendered it
  below before.
- **Three new styles.** `bulletin` (public set) is a two-column statistical
  bulletin: sans headings in blue bars lettered A, B, C, shaded table rows,
  framed figures and a rule between the columns. `thesis` (academic set) is a
  plain thesis or dissertation: double-spaced 12pt Times-like type, a
  1.5-inch binding margin and chapters on new pages. `qc-thesis` is `thesis`
  with the Queens College title page for the MA in Data Analytics and Applied
  Social Research.
- **Thesis title layout.** `title.layout: thesis` (or
  `pdf(title_layout = "thesis")`) sets a title page with the degree statement
  and, with `signatures: true`, signature lines for the committee; a
  copyright page with `copyright: true`; then the contents,
  acknowledgements and abstract numbered i, ii, iii, before the body starts
  at page 1. A document sets `degree`, `institution`, `committee`,
  `signatures` and `copyright` in its YAML; a style supplies defaults with
  `thesis.*` tokens.
- **Every token now works.** Tokens that were accepted but ignored now render:
  grid, zebra and minimal tables (`table.style`) and `table.header.rule_below`;
  heading bars (`headings.<h>.bar.*`), heading faces (`headings.<h>.family`),
  chapters on new pages (`headings.<h>.new_page`) and lettered or roman section
  numbers (`headings.numbering`); a display face (`typography.display`,
  `title.family`); `typography.hyphenation`; the column gap and rule
  (`page.gutter`, `page.column_rule`); figure frames, width and placement
  (`figure.style`, `figure.width`, `figure.placement`); the byline above the
  title (`title.byline.position`); a narrower abstract
  (`title.abstract.width`); and roman front-matter page numbers
  (`header_footer.page_number.format`). government's tables are now gridded
  and shaded, as designed.
- **Keywords are printed.** A document's `keywords:` field appears under the
  abstract (`title.keywords.show`, `title.keywords.label`).
- **Removed tokens:** `links.underline`, `citations.link`,
  `figure.span_columns` and `headings.<h>.rule.length`, which never did
  anything.
- **TeX Gyre Heros** is available as a font family, a Helvetica-like sans
  that full TeX installations include.
- **Fixed: running titles.** In a document without a subtitle, a running head
  set to the title printed the section number instead.
- **Fixed: paragraph indents in ragged-right styles.** A ragged-right style
  lost its `paragraph.indent`.

# docdesigner 0.10.0

- **Removed: `snapshot()`.** The Household Finance Lab's one-page Snapshot
  format now lives in the Lab's own package, hflsnap. Its template
  (`docdesignertemplate.tex`), RStudio starter and examples are gone, and
  `designer_use()` offers `"pdf"` and `"html"`. The `masthead` title layout,
  reserved for it, is retired; a style that names it renders as `header`.
- **Title-page furniture.** A document can carry a contact block, a warning
  line and acknowledgements. The corresponding author's `dept`, `inst`,
  `address`, `email` and `web` (author fields; mark one author
  `corresponding: true`, or the first with contact details is used) make the
  contact block; `warning:` ("DRAFT IN PROGRESS: DO NOT CIRCULATE") is set
  between two rules; `acknowledgements:` (or `acknowledgments:`) follows. On a
  title page (`title_layout: page`) the three stack at the foot of the page.
  In the header layout the warning sits above the title, and the contact
  details and acknowledgements become an unnumbered note at the foot of
  page 1. Every style.
- **Title pages.** `title.layout` is now a structural choice with two
  values: `header` (the title block at the head of page 1, as before) and
  `page` (title and abstract on a page of their own). Any style can use either layout,
  and `docdesigner::pdf(title_layout = "page")` chooses it per document.
  A title page sets the title about a third of the way down
  (`title.page.offset`), carries no running head, band or folio, and keeps
  the abstract or moves it to the first body page (`title.page.abstract`).
  All twelve styles default to `header`, so no existing document changes.
  The old archetype names (`plain`, `essay`, `journal`, `report`) are read as
  `header`, and `title.page_break_after: true` as `page`; the validator flags
  both. Two-column styles get a full-width title page.
- **`pdf()` renders through the package's own LaTeX template**
  (`inst/templates/docdesigner.tex`) instead of pandoc's default. Pages set in
  the `header` layout are unchanged: every style was compared against the
  previous renders page by page.
- **New: callouts.** A fenced div, `::: {.callout title="Key finding"}`,
  sets an emphasis block in every style. `callout.style` is `filled`,
  `ruled`, `boxed` or `plain`; `callout.color`, `callout.tint`,
  `callout.rule`, `callout.size` and `callout.title.*` tune it. Eight
  styles set their own treatment so that callouts stay distinct from their
  quotes; the rest use a tinted panel in their accent colour.
- **Pandoc 3.1.8 or newer is required.** Older versions write bibliographies
  in a form the template cannot typeset; `pdf()` now says so plainly instead
  of failing in LaTeX. `DESCRIPTION` records the requirement.
- **New article: *Creating a style*.** The workflow, the rules for setting
  tokens, principles of good document design (measure, leading, hierarchy,
  colour and contrast, tables), and a full token reference generated from the
  schema. It replaces `STYLE-SPEC.md`, which had drifted from the engine.
- **New specimen gallery.** `examples/gallery-document.Rmd` is a short real
  analysis of R's `airquality` data with three figures, three tables, a
  quotation, code, a callout and a bibliography. `render-gallery.R` renders
  it in every style and both title layouts and combines the results into one
  PDF with a contents page; it also accepts a draft style folder.
- The design brief (`designer_design_brief()`) describes the title layouts,
  the callout, and the CSS conventions `designer_import_html()` needs.
- **`minimal` is now LaTeX's own look; the old `minimal` is `modern`.** The
  new `minimal`, still the default for `pdf()`, looks like an unstyled R
  Markdown PDF: Latin Modern, 1-inch margins, a centred unbolded title, bold
  unnumbered headings, black ink, and no page number on page 1. The previous
  default, a clean modern preprint, is unchanged apart from its margins and
  is now called `modern`. Documents that named `style: minimal` for that look
  should name `style: modern`.
- **Style review.** Wider text blocks: ajs, demography, modern, sociology and
  policy now have 1.25-inch side margins; atlantic, government and humanities
  are slightly narrower than before. ajs and demography put the folio at the
  centre of the foot; demography's running head is set in text ink and ajs's
  captions are no longer grey. sociology is monochrome. ssrn's block
  quotations are italic with a left rule. methods no longer numbers code
  lines. economist carries the running title top left and the folio top
  right, with no running title on page 1. government's masthead bar now
  aligns with the text block. humanities shows no folio on page 1. atlantic
  (as a standfirst) and humanities now show the abstract, so every style
  does.
- **Tables stay in their column in two-column styles.** A table narrow
  enough for one column is now a float within it; only a wider table spans
  both columns. The README, user manual and getting-started
  vignette now warn what floating tables mean in these styles: tables move,
  never split across pages, and lose their column widths.
- **New tokens:** `header_footer.header.bleed` (a band to the paper edge or
  to the text measure), `header_footer.footer.color`, `title.weight`
  (`regular` for an unbolded title), `figure.caption.label_style: plain`, and
  `header_footer.first_page: folio` (page 1 keeps the folio but not the
  running title). `header_footer.first_page: none` now works; it had no
  effect. `header_footer.header.color` now also sets the ink of a plain
  running head, which stays muted when it is unset.
- **Latin Modern** and **Latin Modern Mono** are available as font families.
  They come with every TeX distribution, so they are not bundled.
- **Titles, headings and other display text keep their own line spacing.** A
  style's body line spacing (`typography.line_height`) was multiplying the
  spacing of everything set at an explicit size. In loosely leaded styles a
  two-line title split with a near-blank line between its lines (atlantic),
  bylines drifted apart from affiliations, and tables were set at about 1.8×
  their declared `table.row_stretch`. Title, subtitle, kicker, byline, date,
  headings, abstract, captions, tables and footnotes now use the spacing
  they declare; body text is unchanged.
- **Comfortable line length in every single-column style.** The ten
  single-column styles set 83–104 characters per line, well past the 45–75
  range that reads comfortably. Their side margins (and, for six of them,
  the body size) now give 66–71 characters per line. The two-column styles
  (economist, nature) were already in range and are unchanged.
- **Fixed: structured authors.** An author written as an object (`- name:
  ...`, with `dept`, `inst`, etc.) printed "true" in the title block in every
  style, and two or more authors of either form failed to compile. Names now
  reach the title block and PDF metadata; several authors are stacked, and
  joined by commas in running heads.
- **New: `doublespace` option for `pdf()`.** `docdesigner::pdf: {style: ...,
  doublespace: true}` double-spaces the body text, as for a manuscript under
  review, in any style. Titles, headings, tables, captions, footnotes and code
  stay single-spaced. It replaces loading `setspace` and `\doublespacing`
  through `header-includes`.
- **methods uses journal-article margins:** 1 inch all round with an 11pt body
  (about 95 characters per line), like a downloaded article PDF. The shorter
  line-length pass left it a narrow text block with nearly 2-inch side
  margins, which cramped its wide regression tables.
- **ajs, sociology and ssrn now look distinct.** They had been near-clones: the
  same Times-like face, centred titles and loose leading.
  - ajs: centred capital title over a short hairline, small-caps byline,
    centred capital and italic heads, indented paragraphs, monochrome.
  - sociology: Source Serif 4, a flush-left title under a sans "Research
    Article" kicker with a burgundy rule, burgundy capital section heads, and
    a small-caps run-in abstract.
  - ssrn: a "Working Paper" series line over a centred title, numbered
    sections, paragraphs separated by space, no running head, no colour.
- **policy is redesigned.** Its earlier description promised a wordmark, a
  stat rail and a recommendation callout, none of which the tokens can
  express. It is now a token-native think-tank brief: a sans "Policy Brief"
  kicker over a large flush-left headline, a summary deck and a short heavy
  forest-green bar, a green "Summary" block in place of the abstract, large
  green section heads, and ragged-right text, the only ragged style.
- **Short tables no longer split across pages.** In single-column styles a
  table could break after its header and one row. Short, simple tables (up to
  25 rows, plain columns) are now floats that stay whole, sitting where they
  fall or moving to the top of the next page while the text keeps filling
  the current one. Long tables, and tables with wrapping text columns, still
  cross pages as before. The table filter is now `inst/engine/tables.lua`
  (formerly `twocolumn-tables.lua`).
- Table captions stay above their tables in styles that also put figure
  captions above (ajs, demography, sociology, government).
- Floats may now share a page with text more readily, so a table and a figure
  no longer end up alone on a mostly empty page.

# docdesigner 0.9.10

A bug-fix release from a full review of the package. Upgrade before testing:
the first item stopped every render for anyone using RStudio's pandoc.

- **Renders no longer fail on RStudio's bundled pandoc.** `pdf()` switched to
  pandoc's new `--syntax-highlighting` option from pandoc 3.2 onwards, but the
  option only exists from 3.8. RStudio ships 3.6.3, which rejected it, so
  every style failed to render unless a newer pandoc was installed alongside.
- **The masthead band now appears on page 1.** economist and government ask
  for it there (`header_footer.first_page: header`), but page 1 showed a plain
  grey running head; the band started on page 2.
- **Two-column tables** (nature, economist): the caption now sits above the
  table, as `table.caption.position` declares, and keeps its inline markup. A
  caption containing `&`, `%`, `$`, `#` or `_` no longer breaks the build.
  `table.size` and `table.zebra_color` now apply to these tables too; before,
  they reached only single-column styles.
- **`title.page_break_after` breaks in the right place.** With an abstract,
  the break had landed inside it, moving `title.abstract.rule` onto the body
  page and splitting a boxed abstract; with the abstract hidden it never broke
  at all. No shipped style sets it yet.
- `designer_update_templates(source = "github")` requested a `defaults.yml`
  that no longer exists and stopped before fetching anything. It now fetches
  `schema.yml`, the fonts and the styles.
- A colour written as bare digits (`color.text: 000000`) now gets clear
  advice to quote it, and the validator accepts exactly the colours that
  render (an unquoted `333333` used to render but fail validation).
- The HTML image-path rewrite no longer mangles `data.png` when `a.png` is
  also referenced.
- Removed pointers to developer notes that were never in the repository, from
  `designer_design_brief()` output and the importer's documentation.
- The HTML mockup importer and the design brief generator now have
  tool-neutral names: `designer_import_html()` and `designer_design_brief()`.

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
- **Unhighlighted code no longer escapes its column.** `\fvset` governs
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
  literal em dash in a string literal in `R/design_brief.R`. Portable packages must
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

- Added `designer_import_html()`: drafts a `format.yml` from a standalone
  HTML design mockup by extracting colour, font, and type-scale tokens
  mechanically. Structural tokens (`title.layout`, `page.columns`, etc.) are
  deliberately never guessed: they are left at the seed style's value and
  named in the printed report, for you to set by hand. See
  `?designer_import_html` and `STYLE-SPEC.md`. Adds `xml2` to `Suggests`.
- Added `designer_design_brief()`: generates a Markdown design-constraint
  brief from `inst/engine/schema.yml`, meant to be handed to whoever designs
  a new style, before they start.
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
