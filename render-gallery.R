# Render every gallery document type and style into gallery/.
#
# Usage:
#   Rscript gallery/tests/render-gallery.R

script_path <- tryCatch(
  normalizePath(sys.frame(1)$ofile, winslash = "/", mustWork = TRUE),
  error = function(e) {
    flag <- grep("--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
    if (length(flag)) {
      normalizePath(sub("--file=", "", flag), winslash = "/", mustWork = TRUE)
    } else {
      normalizePath("gallery/tests/render-gallery.R",
                    winslash = "/", mustWork = TRUE)
    }
  }
)

gallery_tests_dir <- dirname(script_path)
gallery_dir <- normalizePath(file.path(gallery_tests_dir, ".."),
                             winslash = "/", mustWork = TRUE)
repo_dir <- normalizePath(file.path(gallery_dir, ".."),
                          winslash = "/", mustWork = TRUE)

if (requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(repo_dir, quiet = TRUE)
} else if (!requireNamespace("docdesigner", quietly = TRUE)) {
  source(file.path(repo_dir, "R", "styles.R"))
  source(file.path(repo_dir, "R", "snapshot.R"))
}

library(rmarkdown)

template <- file.path(repo_dir, "inst", "templates", "docdesignertemplate.tex")
doc_input <- file.path(gallery_dir, "gallery-document.Rmd")
slides_input <- file.path(gallery_dir, "gallery-slides.Rmd")
latex_engine <- Sys.getenv("DOCDESIGNER_LATEX_ENGINE", "xelatex")

styles <- designer_styles()$style

pdf_formats <- list(
  paper = paper_pdf,
  book_chapter = book_chapter_pdf,
  report = report_pdf,
  brief = brief_pdf,
  snapshot = function(..., style, template) {
    snapshot_pdf(..., style = style, template = template, wordpress = "none")
  }
)

results <- data.frame(
  output = character(),
  status = character(),
  message = character(),
  stringsAsFactors = FALSE
)

record <- function(output, status, message = "") {
  results[nrow(results) + 1, ] <<- list(output, status, message)
}

for (doc_type in names(pdf_formats)) {
  for (style in styles) {
    output_file <- sprintf("%s-%s.pdf", doc_type, style)
    cat("Rendering ", output_file, "\n", sep = "")
    tryCatch({
      format <- pdf_formats[[doc_type]](
        style = style,
        template = template,
        latex_engine = latex_engine,
        keep_tex = TRUE
      )
      rmarkdown::render(
        input = doc_input,
        output_format = format,
        output_file = output_file,
        output_dir = gallery_dir,
        quiet = TRUE,
        envir = new.env(parent = globalenv())
      )
      record(output_file, "PASS")
    }, error = function(e) {
      record(output_file, "FAIL", conditionMessage(e))
    })
  }
}

for (style in styles) {
  output_file <- sprintf("slides-%s.html", style)
  cat("Rendering ", output_file, "\n", sep = "")
  tryCatch({
    rmarkdown::render(
      input = slides_input,
      output_format = slides_ioslides(style = style, self_contained = TRUE),
      output_file = output_file,
      output_dir = gallery_dir,
      quiet = TRUE,
      envir = new.env(parent = globalenv())
    )
    record(output_file, "PASS")
  }, error = function(e) {
    record(output_file, "FAIL", conditionMessage(e))
  })
}

cat("\nGallery render summary\n")
cat("======================\n")
print(results, row.names = FALSE)

if (any(results$status == "FAIL")) {
  quit(status = 1)
}

invisible(results)
