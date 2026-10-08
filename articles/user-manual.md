# User Manual

This manual gathers the main package documentation in one place.

## Outputs

- [`docdesigner::pdf`](https://jncohen.github.io/docdesigner/reference/pdf.md)
  creates a designed PDF document.
- [`docdesigner::html`](https://jncohen.github.io/docdesigner/reference/html.md)
  creates plain body HTML for WordPress or another CMS.
- [`docdesigner::snapshot`](https://jncohen.github.io/docdesigner/reference/snapshot.md)
  creates the official Snapshot PDF and, by default, a plain HTML
  companion.

## Start

``` r

docdesigner::designer_use(template = "pdf")
docdesigner::designer_use(template = "html")
docdesigner::designer_use(template = "snapshot")
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
or `STYLE-SPEC.md` for the full token vocabulary. See the *Style
Gallery* article for details.

## Update Local Assets

Most projects use bundled package assets. Projects with local editable
copies can refresh them:

``` r

docdesigner::designer_update_templates()
```

## Diagnostics

``` r

docdesigner::designer_check()
```
