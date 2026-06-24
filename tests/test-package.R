library(docdesigner)

styles <- designer_styles()
stopifnot(is.data.frame(styles))
stopifnot(all(c("style", "label", "description", "fontset", "accent") %in% names(styles)))
stopifnot(all(c("minimal", "demography", "policy") %in% styles$style))

template <- docdesigner:::dd_template()
fonts <- docdesigner:::dd_fonts()
stopifnot(nzchar(template))
stopifnot(nzchar(fonts))

minimal_format <- pdf(style = "minimal")
stopifnot(inherits(minimal_format, "rmarkdown_output_format"))
stopifnot(any(grepl("^fontpath=", minimal_format$pandoc$args)))

html_format <- html()
stopifnot(inherits(html_format, "rmarkdown_output_format"))

snapshot_format <- snapshot(html = FALSE)
stopifnot(inherits(snapshot_format, "rmarkdown_output_format"))
stopifnot(any(grepl("^fontpath=", snapshot_format$pandoc$args)))

policy <- designer_style("policy")
stopifnot(identical(policy$name, "policy"))

gallery <- designer_gallery(output_dir = tempfile("docdesigner-gallery-"),
                            open = FALSE)
stopifnot(file.exists(gallery))

asset_dir <- tempfile("docdesigner-assets-")
asset_dir <- designer_update_templates(asset_dir, source = "installed")
stopifnot(file.exists(file.path(asset_dir, "docdesignertemplate.tex")))
stopifnot(file.exists(file.path(asset_dir, "default.csl")))
stopifnot(dir.exists(file.path(asset_dir, "fonts")))
stopifnot(file.exists(file.path(asset_dir, "styles", "policy", "style.yml")))
