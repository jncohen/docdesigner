# Style Gallery

To see every style as a PDF, with YAML to copy, open the [Style
gallery](https://jncohen.github.io/docdesigner/articles/gallery.html).

Styles apply to
[`docdesigner::pdf`](https://jncohen.github.io/docdesigner/reference/pdf.md).
They do not apply to
[`docdesigner::html`](https://jncohen.github.io/docdesigner/reference/html.md).

You can inspect styles from R:

``` r

docdesigner::designer_styles()
docdesigner::designer_style("policy")
docdesigner::designer_gallery()
```

## Built-In Styles

The 17 built-in styles ship in two sets, `academic` and `public`.

| Style | Set | Use | Body | Accent | Sections | Columns |
|:---|:---|:---|:---|:---|:---|---:|
| `ajs` | `academic` | Modelled on the American Journal of Sociology | XITS | `1A1A1A` | unnumbered | 1 |
| `demography` | `academic` | Modelled on social-demography journals | EB Garamond | `2A4B6E` | unnumbered | 1 |
| `methods` | `academic` | For methods and computational papers | Source Serif 4 | `0F766E` | numbered | 1 |
| `minimal` | `academic` | The look of an unstyled R Markdown PDF | Latin Modern | `000000` | unnumbered | 1 |
| `modern` | `academic` | A clean preprint | Source Serif 4 | `244A7A` | numbered | 1 |
| `nature` | `academic` | Modelled on Nature and Science articles | Source Serif 4 | `0B4F8A` | unnumbered | 2 |
| `qc-thesis` | `academic` | The thesis style with the Queens College title page for the MA in Data Analytics and Applied Social Research, including a committee signature block. | XITS | `000000` | numbered | 1 |
| `review` | `academic` | For drafts printed to read and mark up by hand | Source Serif 4 | `0B5B6B` | numbered | 1 |
| `sociology` | `academic` | Modelled on ASA journals | Source Serif 4 | `1C1A19` | unnumbered | 1 |
| `ssrn` | `academic` | A working paper in the NBER and SSRN tradition | XITS | `000000` | numbered | 1 |
| `thesis` | `academic` | A thesis or dissertation | XITS | `000000` | numbered | 1 |
| `atlantic` | `public` | Modelled on long features in The Atlantic | EB Garamond | `B2332A` | unnumbered | 1 |
| `bulletin` | `public` | A two-column statistical bulletin | Source Serif 4 | `1F5F8B` | numbered | 2 |
| `economist` | `public` | Modelled on The Economist | Source Serif 4 | `E3120B` | numbered | 2 |
| `government` | `public` | Modelled on federal statistical reports | Source Serif 4 | `1A3A5C` | numbered | 1 |
| `humanities` | `public` | Modelled on university-press essays | EB Garamond | `5A3A2E` | unnumbered | 1 |
| `policy` | `public` | A think-tank policy brief | Source Serif 4 | `1E6B3A` | unnumbered | 1 |

Use a style:

``` yaml
output:
  docdesigner::pdf:
    style: methods
```

## Create a Style

A style is a folder with a `format.yml` file of design tokens, written
as flat dotted keys — one `key: value` per line:

``` yaml
id: my-style
label: My Style
description: A concise description of where this style should be used

typography.body: "Source Serif 4"
typography.heading: "Source Serif 4"
typography.base_size: "10pt"

color.accent: "005EA8"
color.rule: "005EA8"

headings.number_sections: true
headings.h1.scale: 1.30

title.layout: header
code.highlight: tango
```

The easiest way to start is to scaffold from an existing style and edit
only what differs:

``` r

docdesigner::designer_new_style("my-style", from = "minimal")
```

[`designer_tokens()`](https://jncohen.github.io/docdesigner/reference/designer_tokens.md)
lists every available token, and the *Creating a style* article
documents them in full. Validate a style against the schema before
rendering:

``` r

docdesigner::designer_validate_style("my-style")
```

Use a local style by its folder path:

``` yaml
output:
  docdesigner::pdf:
    style: "path/to/my-style"
```

Keep styles declarative. They describe a visual system through tokens,
not arbitrary R code.
