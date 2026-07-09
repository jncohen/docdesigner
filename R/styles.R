# Shared asset locators for the publishing formats (snapshot(),
# designer_use(), designer_check()): the bundled LaTeX template and font
# directory. The token-driven document engine lives in R/engine.R; snapshot
# now resolves its style tokens through that engine (see R/snapshot.R).

`%||%` <- function(x, y) if (is.null(x)) y else x

dd_template <- function() {
  template <- system.file("templates/docdesignertemplate.tex", package = "docdesigner")
  if (!nzchar(template)) {
    local_template <- file.path(getwd(), "inst", "templates", "docdesignertemplate.tex")
    if (file.exists(local_template)) normalizePath(local_template, winslash = "/", mustWork = FALSE)
    else "docdesignertemplate.tex"
  } else template
}

dd_fonts <- function() {
  fonts <- system.file("fonts", package = "docdesigner")
  if (!nzchar(fonts)) {
    local_fonts <- file.path(getwd(), "inst", "fonts")
    if (dir.exists(local_fonts)) paste0(normalizePath(local_fonts, winslash = "/", mustWork = FALSE), "/")
    else "fonts/"
  } else paste0(normalizePath(fonts, winslash = "/", mustWork = FALSE), "/")
}

dd_fontpath_metadata <- function(pandoc_args = character()) {
  if (any(grepl("(^|=)fontpath(=|$)", pandoc_args))) return(character())
  c("--metadata", paste0("fontpath=", dd_fonts()))
}

