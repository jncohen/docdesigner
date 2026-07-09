# docdesigner News

## docdesigner 1.0.1

- Added a token-driven style engine (`R/engine.R`): styles are `format.yml`
  manifests with inheritance, resolved into a LaTeX preamble and a `pdf()`
  output format.
- Introduced distributable **style sets** with `designer_sets()`,
  `designer_install_set()`, `designer_update_sets()`, and `designer_new_style()`.
- Reduced the public output API to `pdf()`, `html()`, and `snapshot()`.
- Added `designer_use()` starters for PDF, HTML, and Snapshot.
- Added `designer_check()` for setup diagnostics.
- Added `designer_update_templates()` for refreshing local editable template, font, CSL, and style assets.
- Moved PDF styles into modular `inst/styles/<style>/style.yml` bundles.
- Added a user manual with a style gallery and style-authoring instructions.
- Made Snapshot a fixed official style with optional plain HTML companion output.
- Added plain body HTML output for CMS publishing.
