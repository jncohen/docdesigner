# docdesigner News

## docdesigner 1.0.2

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

## docdesigner 1.0.1

- Reduced the public output API to `pdf()`, `html()`, and `snapshot()`.
- Added `designer_use()` starters for PDF, HTML, and Snapshot.
- Added `designer_check()` for setup diagnostics.
- Added `designer_update_templates()` for refreshing local editable assets.
- Added a user manual with a style gallery and style-authoring instructions.
- Made Snapshot a fixed official style with optional plain HTML companion output.
- Added plain body HTML output for CMS publishing.
