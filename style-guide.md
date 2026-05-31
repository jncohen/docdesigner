# Document Types and Styles

Document Designer separates document structure from visual language. A document type
answers "what kind of research object is this?" A style answers "which
publication tradition should it evoke?"

## Document Types

| Type | Purpose | Best used for |
|---|---|---|
| `paper` | Full scholarly article or working paper with abstract, sections, figures, tables, references, and appendices. | Journal submissions, preprints, conference papers, serious drafts. |
| `book_chapter` | Long-form scholarly contribution with flexible sectioning and prose-forward hierarchy. | Edited volumes, handbooks, theoretical chapters, qualitative chapters. |
| `report` | Longer institutional research product with stronger hierarchy and visual navigation. | Lab reports, funder reports, institutional white papers, data reports. |
| `brief` | Concise research communication designed for scanning and decision support. | Policy briefs, research summaries, public-facing memos. |
| `snapshot` | One-page visual-forward finding built around one empirical claim. | Shareable data findings, public snapshots, lab posts. |
| `slides` | Presentation format sharing the same style vocabulary as the PDF outputs. | Talks, workshops, teaching, stakeholder briefings. |

## Styles

| Style | Reminiscent of | Design intent |
|---|---|---|
| `nature` | Nature/Science scientific article style | Compact, precise, figure-disciplined scientific communication. |
| `economist` | The Economist and public data journalism | Editorial clarity, strong ledes, readable analytical prose. |
| `ssrn` | SSRN/NBER working paper style | Familiar, reviewable, low-friction working paper presentation. |
| `demography` | Demography/Social Forces social-science article style | Conventional quantitative social-science polish. |
| `humanities` | Critical Inquiry/university press essay style | Bookish, prose-forward, generous, footnote-friendly typography. |
| `methods` | Computational social science and methods journals | Calm technical design for code, equations, algorithms, and diagnostics. |
| `policy` | Brookings/Urban Institute/OECD policy reports | Institutional credibility, clear signposting, key finding emphasis. |
| `atlantic` | The Atlantic/long-form public scholarship | Narrative public scholarship with stronger editorial entry points. |
| `government` | Census/Federal Reserve/statistical bulletins | Official, archival, rule-based, source-note-heavy presentation. |
| `minimal` | Clean arXiv/modern university preprint style | Quiet typographic improvement with little visible decoration. |

The styles are intentionally reminiscent of publication genres rather than
copies of brand systems.

## Interface Principle

The package follows the same low-friction idea that makes packages like
`prettydoc` approachable: users choose a format and a style, while the package
chooses the coordinated defaults. In practice, a user should usually need only:

```yaml
output:
  docdesigner::document_pdf:
    type: brief
    style: policy
```

Each style can still carry richer behavior behind that simple choice: fonts,
accent color, section numbering, column layout, citation links, syntax
highlighting, slide CSS, and future figure/table defaults.
