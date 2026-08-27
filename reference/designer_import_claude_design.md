# Draft a style scaffold from a Claude Design HTML export

Parses colour, font, and type-scale values out of a Claude Design
"Export as standalone HTML" file and writes a draft `format.yml`, seeded
from an existing style for every token the export cannot answer.

## Usage

``` r
designer_import_claude_design(
  html,
  id,
  from = "minimal",
  path = ".",
  label = id
)
```

## Arguments

- html:

  Path to the exported HTML file.

- id:

  New style id.

- from:

  Existing style to seed unresolved tokens from. Default `"minimal"`.

- path:

  Destination directory (a style bundle folder is created inside, as in
  [`designer_new_style()`](https://jncohen.github.io/docdesigner/reference/designer_new_style.md)).

- label:

  Human-readable style label. Defaults to `id`.

## Value

The new style directory, invisibly. Prints an extraction report.

## Details

This produces a starting point, not a finished style. Tokens with no CSS
analogue – above all `title.layout`, the print-page architecture; also
`page.columns`, `page.margin`, `page.twoside`, `header_footer.*`,
`title.page_break_after`, and heading/table rule and role choices – are
left at the seed style's value and named in the printed report. Set
those by hand, informed by looking at the design on the Claude Design
canvas: see `dev/CLAUDE-DESIGN-IMPORT.md` for why this split exists and
is not automatable, and STYLE-SPEC.md / `title.layout`'s five archetypes
for the vocabulary to choose from.

Run
[`designer_validate_style()`](https://jncohen.github.io/docdesigner/reference/designer_validate_style.md)
on the result before rendering with it – an extracted colour, font, or
scale can still be malformed or reference a font family that is not
bundled and needs to be declared and shipped under `assets/fonts/`.
