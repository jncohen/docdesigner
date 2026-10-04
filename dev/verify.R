# Verify the docdesigner engine in a real R session.
#   From the repo root:  source("dev/verify.R")
# Requires: devtools, rmarkdown, yaml, and a working XeLaTeX (TinyTeX is fine).

stopifnot(requireNamespace("devtools", quietly = TRUE))
for (p in c("yaml", "rmarkdown")) if (!requireNamespace(p, quietly = TRUE)) install.packages(p)

devtools::load_all(".")

cat("\n== designer_styles() ==\n"); print(designer_styles())
cat("\n== designer_sets() ==\n");   print(designer_sets())

out <- file.path(tempdir(), "dd-verify"); dir.create(out, showWarnings = FALSE)
for (st in c("minimal", "economist", "humanities", "methods", "nature")) {
  cat("\nRendering specimen in style:", st, "... ")
  ok <- tryCatch({
    rmarkdown::render("dev/specimen.md",
      output_format = docdesigner::pdf(style = st),
      output_file = file.path(out, paste0(st, ".pdf")), quiet = TRUE)
    TRUE
  }, error = function(e) { cat("FAILED\n", conditionMessage(e), "\n"); FALSE })
  if (ok) cat("OK ->", file.path(out, paste0(st, ".pdf")), "\n")
}
cat("\nDone. PDFs in:", out, "\n")
