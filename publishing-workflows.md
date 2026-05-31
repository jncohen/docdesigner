# Publishing workflows

The package supports two public-facing Lab workflows in addition to ordinary manuscript PDFs.

## Empirical Snapshots

Use Snapshots for short, visual-forward empirical outputs. A Snapshot should be built around one featured visualization and a compact lead.

```yaml
---
title: "Bachelor's Degree Completion Marks the Largest Wealth Divide"
subtitle: "Survey of Consumer Finances, 2022"
snapshot: true
snapshot_label: "Empirical Snapshot"
snapshot_abstract_label: "Lead"
snapshot_feature: "figures/education-wealth.png"
snapshot_feature_caption: |
  Median household net worth by educational attainment, Survey of Consumer
  Finances, 2022. Dollar amounts are shown in 2022 dollars.

series: "Snapshot"
number: 1
accent: 0066CC
fontset: docdesigner

snapshot_license: "cc-by-nc-sa-4.0"
snapshot_data_note: "Data: 2022 Survey of Consumer Finances. For more information, visit: hhfinance.commons.gc.cuny.edu"
snapshot_code_url: "https://github.com/your-org/your-repo"

abstract: |
  Households headed by college graduates hold substantially more wealth than
  households without a bachelor's degree, and the largest visible break occurs
  at bachelor's degree completion.

output:
  docdesigner::snapshot_pdf:
    wordpress: html
    wordpress_assets: true
    wordpress_checklist: true
---
```

`snapshot_license` controls the lower-left footer license declaration. The default is `cc-by-nc-sa-4.0`; supported presets are `cc-by-4.0`, `cc-by-sa-4.0`, `cc-by-nc-4.0`, `cc-by-nc-sa-4.0`, `cc0-1.0`, `all-rights-reserved`, and `none`. Use `snapshot_license_text` for custom license wording. `snapshot_data_note` controls the lower-right footer note; update it to match the data source and URL for each Snapshot. `snapshot_code_url` optionally adds `Download the code: <URL>` below the About the Author box.

The PDF uses a compact first-page header rather than a full manuscript title page. The abstract is treated as the lead paragraph. The optional `snapshot_feature` image is placed immediately below the lead.

The body should follow the Snapshot style sequence:

1. Context
2. Finding
3. Implication
4. Methodological footer

## Blogposts

Use Blogposts for public-facing Lab posts that should keep the standard docdesigner report PDF style. They are not necessarily built around one featured visualization.

```yaml
---
title: "A Standard Lab Post"
subtitle: "A short public-facing report"
series: "Blogpost"
number: 1
fontset: docdesigner

abstract: |
  This post uses the standard docdesigner report layout and also emits a WordPress
  companion file.

output:
  docdesigner::blogpost_pdf:
    wordpress: html
    wordpress_assets: true
    wordpress_checklist: true
---
```

The PDF uses the normal title page and body styling. The companion file is still created for WordPress.

## WordPress companion files

Both publishing formats accept the same companion options:

```yaml
wordpress: html          # writes paper-wordpress.html
wordpress: markdown      # writes paper-wordpress.md
wordpress: none          # PDF only
wordpress_file: "custom-wordpress.html"
wordpress_assets: true   # writes paper-wordpress-assets/
wordpress_checklist: true
```

The HTML output is a conservative paste source for the CUNY Academic Commons WordPress editor. It does not assume that Markdown, table, PDF, or shortcode plugins are active. The Markdown output is available for local editing, but HTML is the recommended default for research assistants.

When `wordpress_assets: true`, local image references in the companion file are copied into a sibling assets folder and rewritten to point to that folder. Upload those images to the WordPress Media Library, then replace local image paths with the uploaded Media Library URLs if WordPress does not do that automatically.

When `wordpress_checklist: true`, the render writes a short checklist file next to the companion output. This is intended for the RStudio-to-WordPress handoff: paste the HTML, upload/relink images, set metadata, preview desktop/mobile, and attach or link the PDF.

## Manual inspection tests

Generate or render the publishing fixtures with:

```r
Rscript tests/knit-publishing-formats.R --no-render
Rscript tests/knit-publishing-formats.R
Rscript tests/knit-publishing-formats.R snapshot
Rscript tests/knit-publishing-formats.R blogpost
Rscript tests/knit-snapshot.R --no-render
Rscript tests/knit-snapshot.R
```

The script writes:

- `tests/publishing-snapshot.Rmd`
- `tests/publishing-blogpost.Rmd`

When rendered, each should produce a PDF, a `-wordpress.html` companion file, a `-wordpress-assets/` folder when images are detected, and a `-wordpress-checklist.txt` handoff file.
