# CLAUDE.md — orientation for AI coding sessions

Read this before touching anything. It exists so a fresh session does not have to rediscover the architecture, and does not repeat mistakes already made.

## What this package is

A token-driven rendering engine for R Markdown → PDF, plus distributable style sets. A style is a YAML file of design tokens; `dd_preamble()` turns tokens into a LaTeX preamble.

## State as of 2026-07-10

Version 1.0.2, on branch `feature/phase-a`, **pushed** to `origin/feature/phase-a`. `origin/main` is at `16e6e3b`; the branch is 5 commits ahead and **not yet merged** (the design layer is unfinished — see below and the README's "Known limitations"). Do not merge to `main` until the template port lands.

`devtools::check()` passes clean (0/0/0). `designer_specimens()` renders all ten styles.

## The one thing you must understand

**`pdf()` does not use `inst/templates/docdesignertemplate.tex`.**

It builds a preamble from tokens and passes it to `rmarkdown::pdf_document()`'s *stock* LaTeX template via `includes(in_header=)`. Only `snapshot()` renders through the bundled template.

This was a bypass, not a refactor. Three consequences follow, and most confusion about this package traces back to one of them:

1. Two renderers coexist. Every design change must be made twice.
2. `pdf()` silently lost every document feature the `.tex` provides: `subtitle` title pages, `institution`/`series`/`number`, `author_dept`/`_inst`/`_addr`/`_email`/`_orcid`, `keywords`, `acknowledgements`, `anonymize`, `doublespace`, `linenumbers`, running heads.
3. **The styles look alike, and this is expected.** The token vocabulary reaches fonts, sizes, four colour roles, heading scales, and a rule under the title. It does not reach page architecture. Ten styles render one layout in ten accent colours.

**Do not "fix" the blandness by adding tokens to `dd_preamble()`.** That deepens the fork. The fix is to port `pdf()` onto the template and tokenize the template's branching. See `docdesigner.md`, Phase A.

## Verification, honestly

- `devtools::check()` and `tests/test-package.R` verify **token resolution**, not rendering. Nothing in the test suite invokes xelatex.
- `designer_specimens()` is the only code path that compiles a PDF. It is the real smoke test.
- `tools/render_style.py` is a Python harness and the historical executable spec. It does **not** apply the two-column lua filter, so `nature` behaves differently there than in production. Trust the R path.

## Key files

| File | Role |
|---|---|
| `inst/engine/schema.yml` | Token schema + defaults. Every style inherits these. |
| `R/engine.R` | `dd_style_index()`, `dd_resolve_style()`, font registry, `dd_preamble()`, `pdf()` |
| `R/sets.R` | install / list / update / scaffold |
| `R/specimens.R` | `designer_specimens()` — renders one PDF per style + gallery index |
| `R/utils.R` | `%||%`, `dd_hex()`. **Define `%||%` nowhere else.** |
| `inst/templates/docdesignertemplate.tex` | ~1,430 lines. `snapshot()` only. The design that `pdf()` is missing lives here. |

## Invariants

- Styles are keyed on the **`id` declared in `format.yml`**, not the folder name.
- A user set shadows a core style of the same id, with a warning.
- `inherits` resolves a full chain, root-first, with cycle and missing-parent errors. It is stripped from the resolved spec — it is a resolution instruction, not a token.
- `set.yml` declares `format_version`. The engine (`DD_FORMAT_VERSION`) refuses newer sets rather than mis-rendering them.
- `designer_new_style()` seeds a scaffold from the source style's **declared** tokens, never the resolved spec. Copying the resolved spec freezes engine defaults into the scaffold.
- `dd_font_family_dir()` returns a path **with a trailing slash** (fontspec's `Path=` needs one). Do not `normalizePath()` its return value; that strips the slash.
- Font faces of one family must all live in one directory. Lookup order: style `assets/fonts/` → set `assets/fonts/` → core `inst/fonts/`.

## Environment (Windows)

R is not on `PATH`.

```powershell
$env:Path = 'C:\Program Files\R\R-4.5.1\bin;' + $env:Path
$env:Path += ';C:\Program Files\RStudio\resources\app\bin\quarto\bin\tools'   # pandoc
```

`xelatex` comes from TinyTeX. Windows PowerShell 5.1 has no `&&`; use `;`.

```powershell
Rscript -e "devtools::document(); devtools::install(quick=TRUE, upgrade='never')"
Rscript -e "source('tests/test-package.R')"
Rscript -e "docdesigner::designer_specimens(open=FALSE)"
```

`NAMESPACE` is hand-maintained — roxygen skips it. Add exports by hand.

## Next work, in order

1. **Port `pdf()` onto the `.tex`.** Staged: (a) tokenize the `\ifx\docdesignerfontset` branching; (b) collapse the five hard-coded title pages into one token-driven block; (c) point `pdf()` at the template; (d) fold in `snapshot()`; (e) delete `examples/fontset-*.Rmd`. Render between every step.
2. Slim `inst/fonts/` (3.4 MB) — unblocked by the set-aware font registry.
3. Write the style-set format spec.

Step 1(b) is where the design vocabulary actually gets decided. It is not a mechanical edit.
