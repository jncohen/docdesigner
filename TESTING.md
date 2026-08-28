# Testing docdesigner

Alpha, version 1.0.9. Thank you for taking a look.

**The full instructions are in `alpha-testing-instructions.pdf`**, sent along
with the link to this repository. This file is the short version, so nothing is
lost if the PDF isn't to hand.

## What we're testing

Two questions, and only two:

1. **Does it work** — on your machine, on your documents?
2. **Is it easy to learn** — where did you get stuck, what did you have to look
   up, what did you expect to find and not find?

The *visual design* of the styles is deliberately unfinished and is **not** what
this round is about. See "What we are not asking about" below.

## Setup

You need R, a LaTeX installation providing `xelatex`, and pandoc. If you have
knitted an R Markdown document to PDF before, you have all three.

```r
# install.packages("remotes")
remotes::install_github("jncohen/docdesigner")

library(docdesigner)
designer_check()      # reports anything missing from the toolchain
designer_styles()     # the twelve styles, with their sets
```

Fix anything `designer_check()` flags before going further. Please tell us how
this step went even if it went fine — installation is the step most likely to
lose a new user, and the one we can least easily test ourselves.

## What to try

1. **Render something.** Any small R Markdown document, with
   `output: docdesigner::pdf: {style: minimal}`. One line names the style; that
   is the whole interface.
2. **Render a real document of your own** — the messier the better — then switch
   the `style:` line three or four times. *This is the one that matters.* We
   want to know whether your content survives the switch: tables overflowing,
   figures in the wrong column, citations not resolving, code running off the
   edge. `nature` and `economist` are two-column, where wide content suffers
   most.
3. **Install a style set**: `designer_install_set("academic")`.

## What we are not asking about

Known, deliberate, already scheduled — reporting these costs you time and tells
us nothing new:

1. Every style renders a plain title block; no style has a real title *page* yet.
2. `economist` and `government` do not look like their models — they need page
   furniture the engine cannot yet express.
3. `policy` is being redesigned from scratch.
4. Validation reports "not yet implemented" tokens. That is a roadmap, not a
   fault.
5. Fonts substitute (XITS for Times, EB Garamond for oldstyle, Source Serif 4
   for various). Intentional.

Do tell us a style looks **broken**. Don't tell us it looks **unfinished** — we
know, and that's a later round.

## How to report

Email **josephncohen@gmail.com**, one message per problem, `docdesigner alpha`
in the subject line. Most useful, in order: the PDF or a screenshot; which style,
and whether others do the same; a small `.Rmd` that reproduces it; the output of
`designer_check()` and `sessionInfo()`; what you expected instead.

If something failed to install, the full console output including the error is
usually enough on its own.
