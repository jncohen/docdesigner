library(docdesigner)

# --- Engine: style discovery -------------------------------------------------
styles <- designer_styles()
stopifnot(is.data.frame(styles))
stopifnot(all(c("style", "label", "description", "set") %in% names(styles)))
stopifnot(all(c("minimal", "demography", "policy", "nature") %in% styles$style))

# --- Engine: sets ------------------------------------------------------------
sets <- designer_sets()
stopifnot(is.data.frame(sets))
stopifnot(all(c("academic", "public") %in% sets$set))

# --- Engine: resolved tokens (defaults + style, inheritance applied) ---------
minimal_tokens <- designer_style("minimal")
stopifnot(is.list(minimal_tokens))
stopifnot(identical(minimal_tokens$id, "minimal"))
stopifnot(!is.null(minimal_tokens$color$accent))
stopifnot(!is.null(minimal_tokens$typography$body))

# An unknown style fails with a clear message.
unknown <- tryCatch(designer_style("does-not-exist"),
                    error = function(e) conditionMessage(e))
stopifnot(grepl("Unknown docdesigner style", unknown))

# --- Bundled assets are discoverable -----------------------------------------
template <- docdesigner:::dd_template()
fonts <- docdesigner:::dd_fonts()
stopifnot(nzchar(template))
stopifnot(nzchar(fonts))

# --- Output formats build ----------------------------------------------------
minimal_format <- pdf(style = "minimal")
stopifnot(inherits(minimal_format, "rmarkdown_output_format"))
stopifnot(identical(minimal_format$pandoc$latex_engine, "xelatex"))

html_format <- html()
stopifnot(inherits(html_format, "rmarkdown_output_format"))

snapshot_format <- snapshot(html = FALSE)
stopifnot(inherits(snapshot_format, "rmarkdown_output_format"))

# --- Local gallery -----------------------------------------------------------
gallery <- designer_gallery(output_dir = tempfile("docdesigner-gallery-"),
                            open = FALSE)
stopifnot(file.exists(gallery))
