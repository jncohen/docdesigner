# Check a docdesigner setup

Reports whether the package can find its bundled assets and common
rendering tools.

## Usage

``` r
designer_check(path = ".", engine = c("xelatex", "pdflatex", "lualatex"))
```

## Arguments

- path:

  Project directory to inspect.

- engine:

  LaTeX engines to check.

## Value

A data frame with check results, invisibly printed as a compact report.
