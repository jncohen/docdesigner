# docdesigner Starter Templates

Blank R Markdown starters for common Document Designer outputs.

Before rendering a new project, install the package and copy the shared template
bundle into the project folder:

```r
docdesigner::designer_use()
```

That creates the files expected by these starters:

- `docdesignertemplate.tex`
- `default.csl`
- `fonts/`

## Templates

| File | Use | Output |
|---|---|---|
| `research-note.Rmd` | Short empirical working paper | PDF, `fontset: methods` |
| `technical-note.Rmd` | Software, methods, data, or measurement note | PDF, `fontset: methods` |
| `snapshot.Rmd` | One-page public empirical snapshot | Snapshot PDF plus WordPress companion |
| `blog-post.Rmd` | Generic public-facing docdesigner blog post | Blog PDF plus WordPress companion |

Working papers use the `methods` fontset. Snapshots and Blog Posts use their
dedicated output formats because they have different page architecture and web
handoff needs.

The Snapshot starter includes editable footer fields for the license declaration
and data/source note, plus an optional GitHub/code URL below the author box.
