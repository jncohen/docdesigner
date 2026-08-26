# CLAUDE.md — orientation for AI coding sessions

Read this before touching anything. It exists so a fresh session does not have
to rediscover the architecture or repeat mistakes already made.

**For deep detail, read `planning/NOTEBOOK.md` — the single canonical developer
reference** (architecture, the template port, engine traps, authoring workflow,
distribution, and the open-decision checklist, all in one place). This file is
the short version.

## What this package is

A token-driven rendering engine for R Markdown → PDF, plus distributable style
sets. A style is a YAML file of design tokens; `dd_preamble()` turns tokens
into a LaTeX preamble.

## State as of 2026-07-17

Version **1.0.3**, branch `feature/phase-a`, **not merged to `main`** (the
design layer is unfinished — see below). Latest `run-report.txt`: all 11
authored styles render **OK**, `ajs` skipped (no `format.yml` yet). A new
token-faithful model set (four `.dc.html` pages per style) is installed under
`repo/design-sets/<style>/`. `sociology` is active.

`devtools::check()` passes clean; `designer_specimens()` renders every style.

## The one thing you must understand

**`pdf()` does not use `inst/templates/docdesignertemplate.tex`.** It builds a
preamble from tokens and passes it to `rmarkdown::pdf_document()`'s *stock*
template via `includes(in_header=)`. Only `snapshot()` renders through the
bundled template. Consequences:

1. Two renderers coexist; every design change is made twice.
2. `pdf()` silently lost every structural feature the `.tex` provides
   (`subtitle` title pages, `institution`/`series`, author metadata,
   `keywords`, `anonymize`, running heads, …).
3. **Styles look alike, and this is expected.** The token vocabulary reaches
   fonts, colours, type scale, and a rule under the title — not page
   architecture. The `title.layout` archetypes still all render as `plain`.

**Do not "fix" the blandness by adding tokens to `dd_preamble()`.** That deepens
the fork. The fix is to port `pdf()` onto the template — see `planning/NOTEBOOK.md` §3.

## Verification, honestly

- `devtools::check()` and `tests/test-package.R` verify **token resolution**,
  not rendering. Nothing in the test suite invokes xelatex.
- `designer_specimens()` is the only code path that compiles a PDF — the real
  smoke test. `run.R` (project root) does install + validate + render + verify
  in a `callr` subprocess.

## Key files

| File | Role |
|---|---|
| `inst/engine/schema.yml` | Token schema + defaults. Single source of truth. |
| `R/engine.R` | resolution, font registry, `dd_preamble()`, `pdf()` |
| `R/sets.R` | install / list / update / scaffold |
| `R/specimens.R` | `designer_specimens()` — renders one PDF per style |
| `R/utils.R` | `%||%`, `dd_hex()`. **Define `%||%` nowhere else.** |
| `inst/templates/docdesignertemplate.tex` | ~1,430 lines. `snapshot()` only. The design `pdf()` is missing lives here. |
| `planning/NOTEBOOK.md` | **The canonical developer reference.** Start here for anything non-trivial. |

## Invariants

- Styles are keyed on the **`id` in `format.yml`**, not the folder name.
- A user set shadows a core style of the same id, with a warning.
- `inherits` resolves root-first with cycle/missing-parent errors; stripped from
  the resolved spec.
- `set.yml` declares `format_version`; the engine refuses newer sets.
- `designer_new_style()` seeds from **declared** tokens, never the resolved spec.
- `dd_font_family_dir()` returns a path **with a trailing slash**; do not
  `normalizePath()` it.
- Font faces of one family live in one directory: style → set → core.
- `NAMESPACE` is hand-maintained — roxygen skips it. Add exports by hand.

## Environment (Windows)

R is not on `PATH`. R 4.5.1; `xelatex` from TinyTeX; pandoc from RStudio's
quarto tools. PowerShell 5.1 has no `&&`; use `;`.

```powershell
$env:Path = 'C:\Program Files\R\R-4.5.1\bin;' + $env:Path
$env:Path += ';C:\Program Files\RStudio\resources\app\bin\quarto\bin\tools'
Rscript -e "devtools::document(); devtools::install(quick=TRUE, upgrade='never')"
Rscript -e "docdesigner::designer_specimens(open=FALSE)"
```

## Next work, in order (full detail in `planning/NOTEBOOK.md` §2, §9)

1. **Port `pdf()` onto the `.tex`** — the biggest remaining engine task. Two
   decisions need Joe's sign-off before any LaTeX is written (`planning/NOTEBOOK.md` §3).
2. Rebuild each `format.yml` from its new stylesheet; clear the validation debt.
3. Slim `inst/fonts/` (3.4 MB).
4. Gallery, release, CRAN decision.

Step 1(b) is where the design vocabulary gets decided. It is not a mechanical edit.
