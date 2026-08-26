# Render every design-sets/<style>/specimen.Rmd against that same folder's
# DRAFT format.yml — not whatever the installed package currently ships under
# that style id. This is the regression check for styles still being designed
# (see design-sets/README.md for the per-style layout and the promotion
# workflow once a draft is validated and ready to move into repo/inst/sets/).
#
# Usage (Windows PowerShell, per repo/CLAUDE.md's documented environment):
#   $env:Path = 'C:\Program Files\R\R-4.5.1\bin;' + $env:Path
#   $env:Path += ';C:\Program Files\RStudio\resources\app\bin\quarto\bin\tools'
#   cd "D:\Google Drive\Documents\Software\docdesigner"
#   Rscript render-design-sets.R
#
# Requires docdesigner to be installed (devtools::install() from repo/) and a
# working xelatex (TinyTeX). Run docdesigner::designer_check() first if unsure.
#
# A style folder is picked up automatically if it has both format.yml and
# specimen.Rmd. Folders that are archive-only (no format.yml yet, e.g. a style
# whose tokens haven't been authored) are skipped and reported as SKIPPED, not
# FAILED — that's expected mid-design, not a regression.

if (!requireNamespace("rmarkdown", quietly = TRUE)) {
  stop("The rmarkdown package is required to render design-sets specimens.",
       call. = FALSE)
}
if (!requireNamespace("docdesigner", quietly = TRUE)) {
  stop("The docdesigner package must be installed first: ",
       "devtools::install() from repo/.", call. = FALSE)
}
# Fail fast with a clear message if the installed package predates the
# current repo/ source, rather than failing 11 times with a cryptic
# "'pdf' is not an exported object" per style.
if (!"pdf" %in% getNamespaceExports("docdesigner")) {
  stop("The installed docdesigner package is out of date (no exported ",
       "pdf() found) and doesn't match repo/NAMESPACE. Reinstall from the ",
       "current source first: Rscript -e \"devtools::install()\" from ",
       "repo/, then re-run this script.", call. = FALSE)
}

# Resolve this script's own directory so it can be run from anywhere, then the
# project root above it. This file moved to repo/dev/ on 2026-08-26, so the
# root is two levels up; a copy sitting loose at the project root still works.
#
# ofile is consulted BEFORE --file= on purpose. When run.R source()s this file
# inside a callr subprocess, --file= names callr's own script, not this one.
.dd_script <- local({
  for (i in rev(seq_len(sys.nframe()))) {
    of <- sys.frame(i)$ofile
    if (!is.null(of)) return(of)
  }
  a <- commandArgs(trailingOnly = FALSE)
  f <- sub("^--file=", "", a[grepl("^--file=", a)])
  if (length(f)) return(f[[1]])
  NULL
})
here <- if (!is.null(.dd_script)) {
  d <- dirname(normalizePath(.dd_script, winslash = "/"))
  if (basename(d) == "dev") dirname(dirname(d)) else d
} else {
  normalizePath(getwd(), winslash = "/")
}

# The workshop moved to repo/design-sets on 2026-08-25 so it is version-
# controlled. Fall back to the old sibling location so an older checkout,
# or a copy of this script sitting beside a loose design-sets/, still works.
workshop_dir <- file.path(here, "repo", "design-sets")
if (!dir.exists(workshop_dir)) workshop_dir <- file.path(here, "design-sets")
if (!dir.exists(workshop_dir)) {
  stop("No design-sets/ folder found at ", file.path(here, "repo", "design-sets"),
       " or ", file.path(here, "design-sets"), call. = FALSE)
}

candidates <- list.dirs(workshop_dir, recursive = FALSE, full.names = TRUE)
candidates <- candidates[basename(candidates) != "_template"]

results <- data.frame(style = character(), status = character(),
                       message = character(), stringsAsFactors = FALSE)

for (dir in candidates) {
  style <- basename(dir)
  fmt <- file.path(dir, "format.yml")
  input <- file.path(dir, "specimen.Rmd")

  if (!file.exists(fmt) || !file.exists(input)) {
    results <- rbind(results, data.frame(
      style = style, status = "SKIPPED",
      message = if (!file.exists(fmt)) "no format.yml yet (design not started)"
                else "no specimen.Rmd yet"
    ))
    next
  }

  ok <- tryCatch({
    rmarkdown::render(
      input,
      output_format = docdesigner::pdf(style = dir),
      output_file = "specimen.pdf",
      output_dir = dir,
      quiet = TRUE,
      envir = new.env(parent = globalenv())
    )
    TRUE
  }, error = function(e) {
    results <<- rbind(results, data.frame(style = style, status = "FAIL",
                                           message = conditionMessage(e)))
    FALSE
  })
  if (ok) {
    results <- rbind(results, data.frame(style = style, status = "OK", message = ""))
  }
}

cat("\n== docdesigner design-sets render report ==\n")
print(results, row.names = FALSE)

n_fail <- sum(results$status == "FAIL")
n_skip <- sum(results$status == "SKIPPED")
cat("\n", sum(results$status == "OK"), " OK, ", n_fail, " failed, ", n_skip,
    " skipped (no draft yet).\n", sep = "")
if (n_fail > 0) {
  cat("See messages above for the failed style(s).\n")
}
