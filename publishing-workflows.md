# Publishing Workflows

`docdesigner` supports three publishing paths:

- `docdesigner::pdf` for designed PDF documents.
- `docdesigner::html` for plain body HTML that can be pasted into a CMS.
- `docdesigner::snapshot` for the official Snapshot PDF plus optional plain HTML.

## Designed PDF

Use this for reports, papers, briefs, technical notes, and other general documents.

```yaml
---
title: "Document Title"
author: "Your Name"
output:
  docdesigner::pdf:
    style: policy
---
```

Choose a style with `docdesigner::designer_styles()`. Styles apply only to general PDFs.

If a project uses local editable assets, refresh them with:

```r
docdesigner::designer_update_templates()
```

## Plain HTML

Use this when the target is a web editor such as WordPress.

```yaml
---
title: "Article Title"
author: "Your Name"
output:
  docdesigner::html
---
```

The HTML output is intentionally plain. It is a paste source, not a web theme.

## Snapshot

Use this for the official Snapshot publication format.

```yaml
---
title: "Finding-Forward Headline"
author: "Your Name"
snapshot_feature: "figures/chart.png"
snapshot_feature_caption: "Caption text."
snapshot_byline_name: "Author Name"
snapshot_byline_title: "Title"
snapshot_byline_affiliation: "Affiliation"
snapshot_byline_bio: "Short bio."
snapshot_data_note: "Data: source note."
output:
  docdesigner::snapshot:
    html: true
---
```

Snapshot has one official style. Do not add `style`, `fontset`, or `accent` to Snapshot YAML.

## Handoff Checks

Before sharing:

1. Render the document.
2. Open the PDF or HTML output locally.
3. Confirm figures, tables, citations, and links.
4. Upload copied image assets to the CMS media library when using HTML.
5. Preview the web post on desktop and mobile.
