# User Manual

This manual gathers the main package documentation in one place.

## Outputs

- [`docdesigner::pdf`](https://jncohen.github.io/docdesigner/reference/pdf.md)
  creates a designed PDF document.
- [`docdesigner::html`](https://jncohen.github.io/docdesigner/reference/html.md)
  creates plain body HTML for WordPress or another CMS.

## Start

``` r

docdesigner::designer_use(template = "pdf")
docdesigner::designer_use(template = "html")
```

## Styles

Use
[`docdesigner::designer_styles()`](https://jncohen.github.io/docdesigner/reference/designer_styles.md)
to inspect built-in PDF styles. Use
[`docdesigner::designer_gallery()`](https://jncohen.github.io/docdesigner/reference/designer_gallery.md)
to write a local HTML style gallery, or
[`docdesigner::designer_specimens()`](https://jncohen.github.io/docdesigner/reference/designer_specimens.md)
to render a specimen PDF of every style.

A style is a `format.yml` file of design tokens. Scaffold one with
[`docdesigner::designer_new_style()`](https://jncohen.github.io/docdesigner/reference/designer_new_style.md),
check it with
[`docdesigner::designer_validate_style()`](https://jncohen.github.io/docdesigner/reference/designer_validate_style.md),
and see
[`docdesigner::designer_tokens()`](https://jncohen.github.io/docdesigner/reference/designer_tokens.md)
for the full token vocabulary. The *Creating a style* article covers the
workflow and the principles of a good style.

## Update Local Assets

Most projects use bundled package assets. Projects with local editable
copies can refresh them:

``` r

docdesigner::designer_update_templates()
```

## Reviewing a Draft

The `review` style prints a manuscript to read and mark up by hand: a
3in writing margin, line and paragraph numbers, a map of the argument
from the headings, margin flags, citation keys, and changebars against
an earlier version.

``` yaml
output:
  docdesigner::pdf:
    style: review
    changes_since: v1.0          # a git tag, commit, or earlier copy; default: latest tag
    markup:
      line_numbers: 0            # turn one feature off for this printout
```

In the text, `[[TODO: words]]`, `[[CITE]]`, `[[WEAK]]`, `[[CUT]]`,
`[[CHECK]]` and `[[FIX]]` print as margin tags. Write headings as
claims: a heading of fewer than four words is flagged `LABEL?`.
`warning: auto` prints a stamped “Review draft” line with the git
version and date.

## Diagnostics

``` r

docdesigner::designer_check()
```
