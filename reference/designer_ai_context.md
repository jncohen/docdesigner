# Write a context folder for designing a style with an AI assistant

Writes the files an AI assistant needs to design a docdesigner style
well, into one folder to add to the assistant's context (attach the
files to a chat, or open the folder in a coding assistant):

## Usage

``` r
designer_ai_context(
  path = "docdesigner-context",
  from = "minimal",
  examples = NULL,
  overwrite = FALSE
)
```

## Arguments

- path:

  Folder to write. Created if it does not exist.

- from:

  The shipped style the new style will start from. It is copied into
  `examples/` and named in the instructions as the scaffold.

- examples:

  Further shipped styles to copy into `examples/`. Two or three that
  differ from one another give an assistant a better sense of the range
  than one.

- overwrite:

  If `FALSE` (default), refuse to write into a folder that already holds
  a context folder.

## Value

The folder path, invisibly.

## Details

- `AI-INSTRUCTIONS.md`: how the assistant should work, what each file is
  for, the validator's rules and the common mistakes. Load this first.

- `brief.md`: the engine's hard constraints, from
  [`designer_design_brief()`](https://jncohen.github.io/docdesigner/reference/designer_design_brief.md).

- `tokens.csv`: every token with its allowed values, default and status,
  from
  [`designer_tokens()`](https://jncohen.github.io/docdesigner/reference/designer_tokens.md).
  The only keys that exist.

- `examples/<id>.yml`: shipped styles copied with their authors'
  comments, as models of a well-reasoned `format.yml`.

- `specimen.md`: a test document with every element a style sets.

- `check-style.R`: a script that validates a style, renders a document
  with it and writes each page as a PNG, so the assistant (or you) can
  look at the result. Run `Rscript check-style.R path/to/style`.

Everything is generated from the installed package, so it describes the
version you will render with. Regenerate it after updating docdesigner.
