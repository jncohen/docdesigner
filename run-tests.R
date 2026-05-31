# run-tests.R
# Knit every test document and report pass / fail.
#
# Usage:
#   From RStudio: open this file and click Source, or run source("tests/run-tests.R")
#   From terminal: Rscript tests/run-tests.R
#
# Working directory is set automatically to the tests/ folder so relative
# paths in each Rmd (../inst/...) resolve correctly.

library(rmarkdown)

# -- locate this script's directory regardless of how it is invoked ----------
this_file <- tryCatch(
  normalizePath(sys.frame(1)$ofile),          # when source()'d
  error = function(e) {
    flag <- grep("--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
    if (length(flag)) normalizePath(sub("--file=", "", flag)) else NA_character_
  }
)
tests_dir <- if (!is.na(this_file)) dirname(this_file) else getwd()
setwd(tests_dir)
message("Working directory: ", getwd())

# -- scripts to render -------------------------------------------------------
scripts <- c(
  "fontset-default.Rmd",
  "fontset-demography.Rmd",
  "fontset-humanities.Rmd",
  "fontset-methods.Rmd",
  "fontset-docdesigner.Rmd",
  "intro-to-docdesigner-snapshot.Rmd",
  "intro-to-docdesigner-blogpost.Rmd"
)

# -- render loop -------------------------------------------------------------
results <- data.frame(
  script  = scripts,
  status  = NA_character_,
  message = NA_character_,
  stringsAsFactors = FALSE
)

for (i in seq_along(scripts)) {
  cat(sprintf("\n[%d/%d] %s\n", i, length(scripts), scripts[i]))
  tryCatch({
    rmarkdown::render(scripts[i], quiet = TRUE)
    results$status[i] <- "PASS"
    cat("      OK\n")
  }, error = function(e) {
    results$status[i]  <<- "FAIL"
    results$message[i] <<- conditionMessage(e)
    cat(sprintf("      FAIL: %s\n", conditionMessage(e)))
  })
}

# -- summary -----------------------------------------------------------------
cat("\n", strrep("=", 55), "\n", sep = "")
cat(sprintf("  %-42s %s\n", "Script", "Result"))
cat(strrep("-", 55), "\n", sep = "")
for (i in seq_along(scripts)) {
  cat(sprintf("  %-42s %s\n", results$script[i], results$status[i]))
}
cat(strrep("=", 55), "\n", sep = "")

n_pass <- sum(results$status == "PASS", na.rm = TRUE)
n_fail <- sum(results$status == "FAIL", na.rm = TRUE)
cat(sprintf("  %d passed  |  %d failed\n\n", n_pass, n_fail))

if (n_fail > 0) {
  cat("Failed scripts and errors:\n")
  for (i in which(results$status == "FAIL")) {
    cat(sprintf("  %s:\n    %s\n\n", results$script[i], results$message[i]))
  }
}

invisible(results)
