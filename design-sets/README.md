# design-sets

The non-shipped **style workshop**: where each style is designed and proven
before its `format.yml` is promoted into `repo/inst/sets/`. Nothing here installs
via `designer_install_set()`.

Per-style folder holds the four `.dc.html` design models
(`<style>-{title,firstpage,page,stylesheet}.dc.html` + `support.js`/`doc-page.js`),
the draft `format.yml`, `fidelity.md`, and the render test
(`specimen.Rmd`/`.bib`, `figure.png`, `specimen.pdf`). `_template/` is the master
specimen; `docdesigner-design-brief.md` is the authoring-constraint prompt;
`index.html` is the showcase gallery.

**Full workflow, layout, promotion rules, and the repo boundary live in
[`../repo/dev/NOTEBOOK.md`](../repo/dev/NOTEBOOK.md) §6.** Read it before
authoring or promoting a style.
