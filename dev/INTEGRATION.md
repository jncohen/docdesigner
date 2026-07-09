# Phase A/B integration notes

The token-driven engine is built and **proven by rendering** (see `dev/proofs/`),
but the R layer was written without R in the build sandbox. Verify it in RStudio.

## What was added
- `inst/engine/defaults.yml` — engine default tokens (the base every style inherits).
- `inst/sets/academic/`, `inst/sets/public/` — two built-in sets, ten styles as
  self-contained `format.yml` manifests.
- `R/engine.R` — yaml reader, inheritance merge, style resolution (core + user
  library), font registry, preamble generator, and the new `pdf()` output format.
- `R/sets.R` — `designer_sets()`, `designer_install_set()`, `designer_update_sets()`,
  `designer_new_style()`.
- `tools/render_style.py` — the dev harness that renders a style; it is the
  executable spec `R/engine.R` mirrors.
- `dev/specimen.md`, `dev/verify.R`, `dev/proofs/` — specimen, R test script, proofs.

## What changed
- `R/styles.R` — trimmed to the legacy helpers still used by `snapshot()`; the old
  `pdf()`/`designer_styles()`/`designer_style()` were removed (replaced by `R/engine.R`).
- `R/gallery.R` — updated to the new `designer_styles()` columns (`set`, resolved accent).
- `DESCRIPTION` — added `yaml`; dropped the stale "ioslides" claim.
- `NAMESPACE` — exported the four new set commands.

## To verify (in RStudio, with R + XeLaTeX)
1. `devtools::document()`  (regenerate Rd/NAMESPACE)
2. `source("dev/verify.R")`  (lists styles + renders four specimens)
3. `devtools::check()`  and fix anything it flags.

## Known remaining (Phase A/C)
- Two-column styles (`nature`) + tables need a table filter (longtable is
  incompatible with twocolumn). Currently two-column is defined but tables break.
- `snapshot()` still uses the legacy `inst/styles/` resolver; migrate it onto the
  new engine, then delete `inst/styles/` and `inst/slides/`.
- High-fidelity design matching of each style is Phase C.
- Font slimming (ship minimal, fetch the rest) not yet done.
