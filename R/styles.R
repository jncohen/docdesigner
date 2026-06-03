#' Document Designer output styles
#'
#' Lists the publication-inspired styles available to the package output
#' formats. The styles are suggestive design systems rather than copies of any
#' publication brand.
#'
#' @return A data frame with style metadata.
#' @export
designer_styles <- function() {
  data.frame(
    style = names(.dd_style_registry),
    reminiscent_of = vapply(.dd_style_registry, `[[`, character(1),
                            "reminiscent_of"),
    fontset = vapply(.dd_style_registry, `[[`, character(1), "fontset"),
    accent = vapply(.dd_style_registry, `[[`, character(1), "accent"),
    highlight = vapply(.dd_style_registry, `[[`, character(1), "highlight"),
    stringsAsFactors = FALSE
  )
}

#' @rdname designer_styles
#' @export
docdesigner_styles <- designer_styles

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

#' Render a designed PDF document
#'
#' This is the simplest entry point for ordinary use. Choose the document
#' structure with `type` and the publication-inspired visual language with
#' `style`.
#'
#' @param ... Arguments passed to [rmarkdown::pdf_document()].
#' @param type One of `paper`, `book_chapter`, `report`, `brief`, or `snapshot`.
#' @param style One of [designer_styles()]$style.
#' @param template LaTeX template path. Defaults to the bundled template.
#' @param latex_engine LaTeX engine. Defaults to `xelatex`.
#' @return An R Markdown output format.
#' @export
document_pdf <- function(...,
                         type = c("paper", "book_chapter", "report",
                                  "brief", "snapshot"),
                         style = "minimal",
                         template = dd_template(),
                         latex_engine = "xelatex") {
  type <- match.arg(type)
  if (identical(type, "snapshot")) {
    return(snapshot_pdf(...,
                        style = style,
                        template = template,
                        latex_engine = latex_engine,
                        wordpress = "none"))
  }

  scholarly_pdf_document(...,
                         document_type = type,
                         style = style,
                         template = template,
                         latex_engine = latex_engine)
}

#' Render a scholarly paper PDF
#'
#' @param ... Arguments passed to [rmarkdown::pdf_document()].
#' @param style One of [designer_styles()]$style.
#' @param template LaTeX template path. Defaults to the bundled template.
#' @param latex_engine LaTeX engine. Defaults to `xelatex`.
#' @return An R Markdown output format.
#' @export
paper_pdf <- function(...,
                      style = "demography",
                      template = dd_template(),
                      latex_engine = "xelatex") {
  scholarly_pdf_document(...,
                         document_type = "paper",
                         style = style,
                         template = template,
                         latex_engine = latex_engine)
}

#' Render a book chapter PDF
#'
#' @inheritParams paper_pdf
#' @return An R Markdown output format.
#' @export
book_chapter_pdf <- function(...,
                             style = "humanities",
                             template = dd_template(),
                             latex_engine = "xelatex") {
  scholarly_pdf_document(...,
                         document_type = "book_chapter",
                         style = style,
                         template = template,
                         latex_engine = latex_engine)
}

#' Render a research report PDF
#'
#' @inheritParams paper_pdf
#' @return An R Markdown output format.
#' @export
report_pdf <- function(...,
                       style = "policy",
                       template = dd_template(),
                       latex_engine = "xelatex") {
  scholarly_pdf_document(...,
                         document_type = "report",
                         style = style,
                         template = template,
                         latex_engine = latex_engine)
}

#' Render a research brief PDF
#'
#' @inheritParams paper_pdf
#' @return An R Markdown output format.
#' @export
brief_pdf <- function(...,
                      style = "economist",
                      template = dd_template(),
                      latex_engine = "xelatex") {
  scholarly_pdf_document(...,
                         document_type = "brief",
                         style = style,
                         template = template,
                         latex_engine = latex_engine)
}

#' Render an ioslides presentation
#'
#' @param ... Arguments passed to [rmarkdown::ioslides_presentation()].
#' @param style One of [designer_styles()]$style.
#' @return An R Markdown output format.
#' @export
document_slides <- function(..., style = "minimal") {
  if (!requireNamespace("rmarkdown", quietly = TRUE)) {
    stop("The rmarkdown package is required for this output format.",
         call. = FALSE)
  }

  spec <- dd_style(style)
  base_css <- system.file("slides", "minimal.css", package = "docdesigner")
  style_css <- system.file("slides", paste0(style, ".css"),
                           package = "docdesigner")
  css <- unique(c(base_css, style_css))
  css <- css[nzchar(css)]

  args <- list(...)
  args$css <- c(args$css %||% character(), css)
  args$highlight <- args$highlight %||% spec$highlight
  args$pandoc_args <- c(args$pandoc_args %||% character(),
                        "--metadata", paste0("style=", style),
                        "--metadata", paste0("accent=", spec$accent))

  do.call(rmarkdown::ioslides_presentation, args)
}

#' @rdname document_slides
#' @export
slides_ioslides <- document_slides

scholarly_pdf_document <- function(...,
                                   document_type,
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
    "--metadata", paste0("document_type=", document_type),
    "--metadata", paste0("style=", style),
    "--metadata", paste0("fontset=", spec$fontset),
    "--metadata", paste0("accent=", spec$accent),
    "--metadata", paste0("maincolumns=", spec$maincolumns),
    "--metadata", paste0("numbersections=", spec$numbersections),
    "--metadata", paste0("link-citations=", spec$link_citations)
  )

  do.call(rmarkdown::pdf_document, args)
}

dd_template <- function() {
  template <- system.file("templates/docdesignertemplate.tex",
                          package = "docdesigner")
  if (!nzchar(template)) {
    "docdesignertemplate.tex"
  } else {
    template
  }
}

dd_style <- function(style) {
  style <- match.arg(style, names(.dd_style_registry))
  .dd_style_registry[[style]]
}

.dd_style_registry <- list(
  nature = list(
    reminiscent_of = "Nature/Science scientific article style",
    fontset = "methods",
    accent = "2F6F8F",
    maincolumns = 2,
    numbersections = "true",
    highlight = "tango",
    link_citations = "true"
  ),
  economist = list(
    reminiscent_of = "The Economist and public data journalism",
    fontset = "docdesigner",
    accent = "B21F24",
    maincolumns = 1,
    numbersections = "false",
    highlight = "pygments",
    link_citations = "true"
  ),
  ssrn = list(
    reminiscent_of = "SSRN/NBER working paper style",
    fontset = "demography",
    accent = "000000",
    maincolumns = 1,
    numbersections = "true",
    highlight = "tango",
    link_citations = "true"
  ),
  demography = list(
    reminiscent_of = "Demography/Social Forces social-science article style",
    fontset = "demography",
    accent = "000000",
    maincolumns = 1,
    numbersections = "true",
    highlight = "tango",
    link_citations = "true"
  ),
  humanities = list(
    reminiscent_of = "Critical Inquiry/university press essay style",
    fontset = "humanities",
    accent = "000000",
    maincolumns = 1,
    numbersections = "false",
    highlight = "kate",
    link_citations = "true"
  ),
  methods = list(
    reminiscent_of = "Computational social science and methods journals",
    fontset = "methods",
    accent = "003DA5",
    maincolumns = 1,
    numbersections = "true",
    highlight = "tango",
    link_citations = "true"
  ),
  policy = list(
    reminiscent_of = "Brookings/Urban Institute/OECD policy report style",
    fontset = "docdesigner",
    accent = "006A71",
    maincolumns = 1,
    numbersections = "false",
    highlight = "pygments",
    link_citations = "true"
  ),
  atlantic = list(
    reminiscent_of = "The Atlantic/long-form public scholarship",
    fontset = "humanities",
    accent = "8F1D14",
    maincolumns = 1,
    numbersections = "false",
    highlight = "kate",
    link_citations = "true"
  ),
  government = list(
    reminiscent_of = "Census/Federal Reserve/statistical bulletin style",
    fontset = "demography",
    accent = "2F4F3E",
    maincolumns = 1,
    numbersections = "true",
    highlight = "tango",
    link_citations = "true"
  ),
  minimal = list(
    reminiscent_of = "Clean arXiv/modern university preprint style",
    fontset = "default",
    accent = "333333",
    maincolumns = 1,
    numbersections = "true",
    highlight = "tango",
    link_citations = "true"
  )
)

docdesigner_template <- dd_template
docdesigner_style <- dd_style
