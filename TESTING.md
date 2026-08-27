# Testing docdesigner

Thanks for taking a look. This is a pre-release pilot: the rendering
engine is solid, the *design* layer is deliberately unfinished. **Please
read [What not to report](#what-not-to-report) first** — it will save
you writing up three or four things we already know about.

Version 1.0.9. Fifteen minutes gets you through “Setup” and the first
task.

------------------------------------------------------------------------

## Setup

You need R, a LaTeX installation with `xelatex`, and pandoc. RStudio
bundles pandoc; TinyTeX or MiKTeX both work for LaTeX.

You will have been sent **`docdesigner_1.0.9.tar.gz`**. Install it from
wherever you saved it — there is no CRAN or GitHub install, so the path
is the only fiddly part:

``` r

install.packages("~/Downloads/docdesigner_1.0.9.tar.gz",
                 repos = NULL, type = "source")
library(docdesigner)

designer_check()      # reports anything missing from the toolchain
designer_styles()     # the twelve styles, with their sets
```

On Windows use forward slashes or doubled backslashes in that path
(`"C:/Users/you/Downloads/docdesigner_1.0.9.tar.gz"`). If R reports that
the package is not available, it is nearly always the path rather than
the file.

The tarball carries everything — engine, all twelve styles, fonts. There
is nothing else to download.

If
[`designer_check()`](https://jncohen.github.io/docdesigner/reference/designer_check.md)
complains, fix that before anything else — almost every confusing
failure downstream is a missing `xelatex` or a missing font.

------------------------------------------------------------------------

## What to try

Work through as many as you have appetite for. Tasks 1 and 2 are the
ones we most need eyes on.

### 1. Render one document in several styles

The core promise is *same content, any style*. Take a real paper of your
own — one with sections, a table, a figure, footnotes and a bibliography
— and render it under three or four styles:

``` yaml
output:
  docdesigner::pdf:
    style: minimal      # then nature, sociology, humanities, ...
```

We want to know: does your content survive the switch? Tables that
overflow the measure, figures that land in the wrong column, citations
that stop resolving, headings that collide with the running head — that
is the interesting failure class, and it is the one we cannot find by
rendering our own specimen.

**`nature` and `economist` are two-column.** Wide tables and code blocks
are the usual casualty there; we would like to know how badly.

### 2. Judge a style against its model

Every style imitates a real publication.
[`designer_specimens()`](https://jncohen.github.io/docdesigner/reference/designer_specimens.md)
renders our specimen document in each:

``` r

designer_specimens(styles = c("sociology", "demography", "nature"))
```

Look at one whose real-world model you know well — if you publish in
demography journals, look at `demography`. Tell us where it reads
*wrong* to a practised eye. “The section heads are too heavy”, “that gap
belongs above the author, not below”, “no journal in this field numbers
sections like that” is exactly the feedback we want. Be specific about
which element.

### 3. Build a style of your own

``` r

designer_new_style("my-style", from = "minimal", path = "~/styles")
```

Edit `format.yml`, then:

``` r

designer_validate_style("~/styles/my-style")
designer_specimens(styles = "my-style")
```

We want to know whether the token vocabulary lets you express what you
had in mind, and whether the validator’s messages actually tell you how
to fix things. **A token you went looking for and could not find is a
finding** — please report those.

### 4. Install a style set from GitHub

``` r

designer_install_set("academic")
designer_sets()
```

Sets install to your R user data directory and survive package updates.

------------------------------------------------------------------------

## What not to report

These are known, deliberate, and already scheduled. Reporting them costs
you time and tells us nothing new.

1.  **Every style renders a plain title block.** `title.layout` accepts
    five archetypes (`plain`, `essay`, `journal`, `report`, `masthead`)
    and the engine currently ignores all of them, because
    [`pdf()`](https://jncohen.github.io/docdesigner/reference/pdf.md)
    does not yet use the bundled LaTeX template. No style has a real
    title *page*.
2.  **`economist` and `government` do not look like The Economist or a
    federal statistical bulletin.** Both depend on full-bleed coloured
    masthead bands and boxed panels — page furniture the token
    vocabulary cannot yet express. They are known to be the two weakest
    styles.
3.  **`policy` is an imitation and is being redesigned** from scratch as
    a token-native design.
4.  **Validation reports “not yet implemented” tokens.** That list is
    accurate and expected: those tokens are declared and schema-valid
    but the engine ignores them. It is a roadmap, not a fault.
5.  **Fonts substitute.** Proprietary faces are replaced by bundled open
    ones — XITS for Times, EB Garamond for oldstyle, Source Serif 4 for
    various. The substitution is intentional; that a style is “not quite
    the real typeface” is not a bug. A substitution that looks *wrong at
    the size used* is.
6.  **CRAN.** Not submitted, deliberately.

------------------------------------------------------------------------

## How to report

Email **<josephncohen@gmail.com>**, one message per problem, with
`docdesigner alpha` somewhere in the subject line. What makes a report
actionable, in rough order of value:

1.  **Attach the PDF**, or a screenshot of the part that is wrong. We
    cannot judge a layout complaint from prose.
2.  **Which style**, and whether other styles do the same thing.
    “`sociology` only” and “all twelve” are different bugs.
3.  **A minimal `.Rmd` that reproduces it.** If your document is
    confidential, cut it down until it is not — that usually localises
    the problem anyway.
4.  **The output of
    [`designer_check()`](https://jncohen.github.io/docdesigner/reference/designer_check.md)**,
    and [`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html).
5.  **What you expected instead.** For fidelity complaints, name the
    publication and, if you can, point at a page of it.

For a fidelity judgement — “this doesn’t look like the real thing” — the
single most useful thing you can send is a side-by-side: our specimen
next to a real article from that publication, with the difference
circled.

### A note on what counts as evidence

We check tokens against the rendered page, not against the mockup, so a
style can pass every automated check and still look wrong. That gap is
exactly what we need a human for. If it looks wrong on the page, it is
wrong, regardless of what the tooling says — please report it even if
you suspect it is intentional.
