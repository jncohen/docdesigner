# design-sets

The non-shipped **style workshop**: where each style is designed and proven
before its `format.yml` is promoted into `repo/inst/sets/`. Nothing here installs
via `designer_install_set()`.

Each per-style folder holds the draft `format.yml`, its `fidelity.md` report,
and the render test (`specimen.Rmd`/`.bib`, `figure.png`, `specimen.pdf`). The
page designs each style was built from (title, first page, body page and
stylesheet) are kept outside the repository. `_template/` is the master
specimen; `docdesigner-design-brief.md` is the authoring-constraint brief;
`index.html` is the showcase gallery.

**Workflow.** Edit a draft `format.yml` here, render it with
`dev/render-design-sets.R` (or `dev/run.R`, which also validates and verifies),
check the rendered page, then promote: copy the file to
`inst/sets/<set>/styles/<style>/format.yml` and list the style in that set's
`set.yml`. Editing only `inst/sets/` changes nothing that `run.R` renders.
