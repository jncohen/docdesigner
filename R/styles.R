#' Document Designer output styles
#'
#' Lists the available style bundles. Built-in styles live under
#' `inst/styles/<style-name>/style.yml`; user styles can be read from the same
#' folder shape with [designer_style()].
#'
#' @return A data frame with style metadata.
#' @export
designer_styles <- function() {
  specs <- lapply(dd_style_dirs(), read_style_manifest)
  specs <- specs[!vapply(specs, is.null, logical(1))]

  data.frame(
    style = vapply(specs, `[[`, character(1), "name"),
    label = vapply(specs, `[[`, character(1), "label"),
    description = vapply(specs, `[[`, character(1), "description"),
    fontset = vapply(specs, `[[`, character(1), "fontset"),
    accent = vapply(specs, `[[`, character(1), "accent"),
    highlight = vapply(specs, `[[`, character(1), "highlight"),
    stringsAsFactors = FALSE
  )
}

#' Read one style bundle
#'
#' @param style Built-in style name or path to a style bundle directory.
#' @return A list with style metadata.
#' @export
designer_style <- function(style = "minimal") {
  dd_style(style)
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

#' Render a designed PDF
#'
#' This is the main PDF output format for ordinary documents. Pick a visual
#' style with `style`; use document content and metadata to signal genre.
#'
#' @param ... Arguments passed to [rmarkdown::pdf_document()].
#' @param style One of [designer_styles()]$style or a style bundle path.
#' @param template LaTeX template path. Defaults to the bundled template.
#' @param latex_engine LaTeX engine. Defaults to `xelatex`.
#' @return An R Markdown output format.
#' @export
pdf <- function(...,
                style = "minimal",
                template = dd_template(),
                latex_engine = "xelatex") {
  scholarly_pdf_document(...,
                         style = style,
                         template = template,
                         latex_engine = latex_engine)
}

scholarly_pdf_document <- function(...,
                                   style,
                                   template,
                                   latex_engine) {
  if (!requireNamespace("rmarkdown", quietly = TRUE)) {
    stop("The rmarkdown package is required for this output format.",
         call. = FALSE)
  }

  spec <- dd_style(style)
  args <- list(...)
  args$template <- template
  args$latex_engine <- latex_engine
  args$highlight <- args$highlight %||% spec$highlight
  args$pandoc_args <- c(
    args$pandoc_args %||% character(),
    dd_fontpath_metadata(args$pandoc_args),
    style_metadata_args(spec)
  )

  do.call(rmarkdown::pdf_document, args)
}

style_metadata_args <- function(spec) {
  c("--metadata", paste0("style=", spec$name),
    "--metadata", paste0("fontset=", spec$fontset),
    "--metadata", paste0("accent=", spec$accent),
    "--metadata", paste0("maincolumns=", spec$maincolumns),
    "--metadata", paste0("numbersections=", spec$numbersections),
    "--metadata", paste0("link-citations=", spec$link_citations))
}

dd_template <- function() {
  template <- system.file("templates/docdesignertemplate.tex",
                          package = "docdesigner")
  if (!nzchar(template)) {
    local_template <- file.path(getwd(), "inst", "templates",
                                "docdesignertemplate.tex")
    if (file.exists(local_template)) {
      normalizePath(local_template, winslash = "/", mustWork = FALSE)
    } else {
      "docdesignertemplate.tex"
    }
  } else {
    template
  }
}

dd_fonts <- function() {
  fonts <- system.file("fonts", package = "docdesigner")
  if (!nzchar(fonts)) {
    local_fonts <- file.path(getwd(), "inst", "fonts")
    if (dir.exists(local_fonts)) {
      paste0(normalizePath(local_fonts, winslash = "/", mustWork = FALSE), "/")
    } else {
      "fonts/"
    }
  } else {
    paste0(normalizePath(fonts, winslash = "/", mustWork = FALSE), "/")
  }
}

dd_fontpath_metadata <- function(pandoc_args = character()) {
  if (any(grepl("(^|=)fontpath(=|$)", pandoc_args))) {
    return(character())
  }

  c("--metadata", paste0("fontpath=", dd_fonts()))
}

dd_style <- function(style) {
  dir <- if (dir.exists(style)) {
    normalizePath(style, winslash = "/", mustWork = TRUE)
  } else {
    file.path(dd_styles_root(), style)
  }

  spec <- read_style_manifest(dir)
  if (is.null(spec)) {
    available <- designer_styles()$style
    stop("Unknown docdesigner style: ", style, "\nAvailable styles: ",
         paste(available, collapse = ", "), call. = FALSE)
  }

  spec
}

dd_styles_root <- function() {
  root <- system.file("styles", package = "docdesigner")
  if (!nzchar(root)) {
    file.path(getwd(), "inst", "styles")
  } else {
    root
  }
}

dd_style_dirs <- function() {
  root <- dd_styles_root()
  if (!dir.exists(root)) {
    return(character())
  }
  dirs <- list.dirs(root, recursive = FALSE, full.names = TRUE)
  dirs[file.exists(file.path(dirs, "style.yml"))]
}

read_style_manifest <- function(dir) {
  path <- file.path(dir, "style.yml")
  if (!file.exists(path)) {
    return(NULL)
  }

  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  lines <- trimws(lines)
  lines <- lines[nzchar(lines) & !startsWith(lines, "#")]
  parts <- strsplit(lines, ":", fixed = TRUE)
  parts <- parts[lengths(parts) >= 2]
  spec <- stats::setNames(
    lapply(parts, function(x) trimws(paste(x[-1], collapse = ":"))),
    vapply(parts, `[[`, character(1), 1)
  )
  spec <- lapply(spec, unquote_yaml_scalar)

  defaults <- list(
    name = basename(dir),
    label = basename(dir),
    description = "",
    fontset = "default",
    accent = "333333",
    highlight = "tango",
    maincolumns = "1",
    numbersections = "true",
    link_citations = "true"
  )
  spec <- modifyList(defaults, spec)
  spec$maincolumns <- as.character(spec$maincolumns)
  spec$numbersections <- as.character(spec$numbersections)
  spec$link_citations <- as.character(spec$link_citations)
  spec
}

unquote_yaml_scalar <- function(x) {
  x <- trimws(x)
  sub('^"(.*)"$', "\\1", sub("^'(.*)'$", "\\1", x))
}
