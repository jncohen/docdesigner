# Testing docdesigner

Alpha, version 0.10.0. Thank you for taking a look.

**The full instructions are in
[alpha-testing-instructions.pdf](alpha-testing-instructions.pdf)**, in this
repository — click it above, then use the download button. This file is the
short version, so nothing is lost if you would rather not open the PDF.

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
designer_styles()     # the sixteen styles, with their sets
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

## What we already know about

Please do comment on how the styles look. These are known and do not need
reporting:

1. Tables in `nature`, `economist` and `bulletin` move: in a two-column style
   every table is placed by LaTeX, and one wider than a column goes to the top
   of the next page.
2. `minimal` changed in 0.10.0. It is now the plain look of an unstyled R
   Markdown PDF; the clean preprint style it used to be is `modern`.
3. Fonts substitute (XITS for Times, EB Garamond for oldstyle, Source Serif 4
   for various). Intentional.

## How to report

Email **josephncohen@gmail.com**, one message per problem, `docdesigner alpha`
in the subject line. Most useful, in order: the PDF or a screenshot; which style,
and whether others do the same; a small `.Rmd` that reproduces it; the output of
`designer_check()` and `sessionInfo()`; what you expected instead.

If something failed to install, the full console output including the error is
usually enough on its own.
