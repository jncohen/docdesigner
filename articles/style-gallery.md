# Style Gallery

Styles apply to
[`docdesigner::pdf`](https://jncohen.github.io/docdesigner/reference/pdf.md).
They do not apply to
[`docdesigner::html`](https://jncohen.github.io/docdesigner/reference/html.md),
and Snapshot uses its official house style.

You can inspect styles from R:

``` r

docdesigner::designer_styles()
docdesigner::designer_style("policy")
docdesigner::designer_gallery()
```

## Built-In Styles

The 12 built-in styles ship in two sets, `academic` and `public`.

| Style | Set | Use | Body | Accent | Sections | Columns |
|:---|:---|:---|:---|:---|:---|---:|
| `ajs` | `academic` | The classic footnoted-journal look of the American Journal of Sociology (Chicago house style) | XITS | `333333` | unnumbered | 1 |
| `demography` | `academic` | The classic oldstyle look of long-running social-demography journals | EB Garamond | `2A4B6E` | unnumbered | 1 |
| `methods` | `academic` | Built for computational and methods journals, with code shown clearly | Source Serif 4 | `0F766E` | numbered | 1 |
| `minimal` | `academic` | A clean, modern preprint in the arXiv tradition | Source Serif 4 | `244A7A` | numbered | 1 |
| `nature` | `academic` | The compact two-column look of Nature and Science research articles | Source Serif 4 | `0B4F8A` | unnumbered | 2 |
| `sociology` | `academic` | The structured ASA-tradition journal look (ASR / AJS family) | XITS | `333333` | unnumbered | 1 |
| `ssrn` | `academic` | The austere working-paper look of the NBER / SSRN tradition | XITS | `333333` | numbered | 1 |
| `atlantic` | `public` | The Atlantic’s long-form feature look | EB Garamond | `B2332A` | unnumbered | 1 |
| `economist` | `public` | The dense two-column look of The Economist, adapted to academic papers | Source Serif 4 | `E3120B` | numbered | 2 |
| `government` | `public` | The official statistical-bulletin look of a federal statistics agency (Census / Federal Reserve tradition) | Source Serif 4 | `1A3A5C` | numbered | 1 |
| `humanities` | `public` | The unhurried look of a university-press humanities essay | EB Garamond | `5A3A2E` | unnumbered | 1 |
| `policy` | `public` | The polished think-tank policy-brief look (OECD / Brookings tradition) | Source Serif 4 | `C1442A` | unnumbered | 1 |

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

title.layout: plain
code.highlight: tango
```

The easiest way to start is to scaffold from an existing style and edit
only what differs:

``` r

docdesigner::designer_new_style("my-style", from = "minimal")
```

[`designer_tokens()`](https://jncohen.github.io/docdesigner/reference/designer_tokens.md)
lists every available token, and `STYLE-SPEC.md` documents them in full.
Validate a style against the schema before rendering:

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
