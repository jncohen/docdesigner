#' Render plain HTML for web publishing
#'
#' Produces body-only HTML suitable for copying into a CMS such as WordPress.
#' It does not try to reproduce the PDF layout.
#'
#' @param ... Arguments passed to [rmarkdown::html_document()].
#' @param assets If `TRUE`, copy local image assets beside the HTML file and
#'   rewrite local image paths.
#' @param checklist If `TRUE`, write a short publishing checklist.
#' @param body_only If `TRUE`, keep only the HTML body content.
#' @return An R Markdown output format.
#' @export
html <- function(...,
                 assets = TRUE,
                 checklist = TRUE,
                 body_only = TRUE) {
  if (!requireNamespace("rmarkdown", quietly = TRUE)) {
    stop("The rmarkdown package is required for this output format.",
         call. = FALSE)
  }

  args <- list(...)
  args$self_contained <- args$self_contained %||% FALSE
  args$theme <- args$theme %||% NULL
  args$css <- args$css %||% NULL
  args$toc <- args$toc %||% FALSE
  args$pandoc_args <- c(args$pandoc_args %||% character(),
                        "--section-divs",
                        "--wrap=none")

  format <- do.call(rmarkdown::html_document, args)
  previous_post_processor <- format$post_processor

  format$post_processor <- function(metadata, input_file, output_file, clean, verbose) {
    final_output <- output_file
    if (is.function(previous_post_processor)) {
      final_output <- previous_post_processor(
        metadata = metadata,
        input_file = input_file,
        output_file = output_file,
        clean = clean,
        verbose = verbose
      )
    }

    if (isTRUE(body_only)) {
      write_body_only_html(final_output)
    }

    assets_dir <- NULL
    if (isTRUE(assets)) {
      assets_dir <- copy_html_assets(
        companion_file = final_output,
        input_file = input_file,
        companion = "html"
      )
    }

    if (isTRUE(checklist)) {
      write_publishing_checklist(
        output_file = final_output,
        companion_file = final_output,
        assets_dir = assets_dir,
        metadata = metadata
      )
    }

    final_output
  }

  format
}

write_body_only_html <- function(path) {
  text <- readLines(path, warn = FALSE, encoding = "UTF-8")
  start <- grep("<body[^>]*>", text, ignore.case = TRUE)
  end <- grep("</body>", text, ignore.case = TRUE)
  if (!length(start) || !length(end) || end[1] <= start[1]) {
    return(invisible(path))
  }

  body <- text[(start[1] + 1):(end[1] - 1)]
  body <- body[!grepl("^<script\\b|^</script>|^<style\\b|^</style>",
                      trimws(body), ignore.case = TRUE)]
  writeLines(body, path, useBytes = TRUE)
  invisible(path)
}
