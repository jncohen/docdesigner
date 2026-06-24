# Render the PDF style gallery into rendered-examples/gallery/.
#
# Usage:
#   Rscript render-gallery.R

if (!requireNamespace("rmarkdown", quietly = TRUE)) {
  stop("The rmarkdown package is required to render the gallery.", call. = FALSE)
}

script_path <- tryCatch(
  normalizePath(sys.frame(1)$ofile, winslash = "/", mustWork = TRUE),
  error = function(e) {
    flag <- grep("--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
    if (length(flag)) {
      normalizePath(sub("--file=", "", flag), winslash = "/", mustWork = TRUE)
    } else {
      normalizePath("render-gallery.R", winslash = "/", mustWork = TRUE)
    }
  }
)

repo_dir <- dirname(script_path)
examples_dir <- normalizePath(file.path(repo_dir, "examples"),
                              winslash = "/", mustWork = TRUE)
gallery_dir <- file.path(repo_dir, "rendered-examples", "gallery")
dir.create(gallery_dir, recursive = TRUE, showWarnings = FALSE)

if (requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(repo_dir, quiet = TRUE)
} else {
  source(file.path(repo_dir, "R", "styles.R"))
  source(file.path(repo_dir, "R", "snapshot.R"))
  source(file.path(repo_dir, "R", "html.R"))
}

doc_input <- file.path(examples_dir, "gallery-document.Rmd")
latex_engine <- Sys.getenv("DOCDESIGNER_LATEX_ENGINE", "xelatex")
styles <- designer_styles()$style

results <- data.frame(
  output = character(),
  status = character(),
  message = character(),
  stringsAsFactors = FALSE
)

record <- function(output, status, message = "") {
  results[nrow(results) + 1, ] <<- list(output, status, message)
}

for (style in styles) {
  output_file <- sprintf("pdf-%s.pdf", style)
  cat("Rendering ", output_file, "\n", sep = "")
  tryCatch({
    rmarkdown::render(
      input = doc_input,
      output_format = pdf(style = style,
                          latex_engine = latex_engine,
                          keep_tex = TRUE),
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

cat("\nStyle gallery render summary\n")
cat("============================\n")
print(results, row.names = FALSE)

if (any(results$status == "FAIL")) {
  quit(status = 1)
}

invisible(results)
