# Render docdesigner example documents into rendered-examples/.
#
# Usage:
#   Rscript run-tests.R
#
# This is an example-render workflow, not the package test suite. Package tests
# live under tests/ and are run by R CMD check.

if (!requireNamespace("rmarkdown", quietly = TRUE)) {
  stop("The rmarkdown package is required to render examples.", call. = FALSE)
}

script_path <- tryCatch(
  normalizePath(sys.frame(1)$ofile, winslash = "/", mustWork = TRUE),
  error = function(e) {
    flag <- grep("--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
    if (length(flag)) {
      normalizePath(sub("--file=", "", flag), winslash = "/", mustWork = TRUE)
    } else {
      normalizePath("run-tests.R", winslash = "/", mustWork = TRUE)
    }
  }
)

repo_dir <- dirname(script_path)
examples_dir <- file.path(repo_dir, "examples")
output_dir <- file.path(repo_dir, "rendered-examples")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

if (requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(repo_dir, quiet = TRUE)
} else {
  source(file.path(repo_dir, "R", "styles.R"))
  source(file.path(repo_dir, "R", "snapshot.R"))
  source(file.path(repo_dir, "R", "html.R"))
}

examples <- c(
  "research-note.Rmd",
  "technical-note.Rmd",
  "blog-post.Rmd",
  "snapshot.Rmd",
  "intro-to-docdesigner-snapshot.Rmd",
  "intro-to-docdesigner-blogpost.Rmd"
)

results <- data.frame(
  input = examples,
  status = NA_character_,
  message = NA_character_,
  stringsAsFactors = FALSE
)

for (i in seq_along(examples)) {
  input <- file.path(examples_dir, examples[i])
  cat(sprintf("\n[%d/%d] %s\n", i, length(examples), examples[i]))

  tryCatch({
    rmarkdown::render(
      input = input,
      output_dir = output_dir,
      quiet = TRUE,
      envir = new.env(parent = globalenv())
    )
    results$status[i] <- "PASS"
    cat("      OK\n")
  }, error = function(e) {
    results$status[i] <<- "FAIL"
    results$message[i] <<- conditionMessage(e)
    cat("      FAIL: ", conditionMessage(e), "\n", sep = "")
  })
}

cat("\nExample render summary\n")
cat("======================\n")
print(results, row.names = FALSE)

if (any(results$status == "FAIL", na.rm = TRUE)) {
  quit(status = 1)
}

invisible(results)
