# One command: install, render, verify, and write a report to disk.
#
#   setwd("D:/Google Drive/Documents/Software/docdesigner"); source("run.R")
#
# (that root run.R is a two-line shim onto this file, which is the real one)
#
# Why this exists:
#
# 1. No Restart R. Installing docdesigner while it is loaded in the calling
#    session corrupts the lazy-load database and fails every style at once
#    ("R_decompress1 with libdeflate"). The usual fix is to restart by hand,
#    which is easy to forget and has cost several cycles. callr::r() runs the
#    render in a FRESH subprocess that has never loaded the package, so it
#    picks up the new install with no restart and cannot hit the corruption.
#    The calling session must therefore never load docdesigner -- that is why
#    everything below goes through callr rather than a plain source().
#
# 2. The report lands on disk. Console output has to be copied back by hand;
#    a file can be read directly.
#
# 3. YAML is parsed before anything is built. A truncated format.yml resolves
#    to defaults SILENTLY -- the same class of bug as page.margin rendering at
#    1in for years. A truncated schema.yml at least fails loudly. Both are
#    checked first so a broken file is never mistaken for a design problem.

# Locate the project root from this script's own path, rather than hardcoding
# it: repo/dev/run.R -> repo/ -> the project root. The script moved inside the
# repo on 2026-08-26 to be version-controlled, and deriving the root is what
# lets it travel with the checkout.
#
# ofile is consulted BEFORE --file= on purpose. When this file is source()d
# from a callr subprocess, --file= names callr's own script, not this one.
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
root <- if (!is.null(.dd_script)) {
  dirname(dirname(dirname(normalizePath(.dd_script, winslash = "/"))))
} else normalizePath(getwd(), winslash = "/")
.dd_anchor <- function(r) file.exists(file.path(r, "repo/inst/engine/schema.yml"))
if (!.dd_anchor(root)) root <- normalizePath(getwd(), winslash = "/")
if (!.dd_anchor(root)) {
  stop("Cannot find the project root: no repo/inst/engine/schema.yml under '",
       root, "'. Run it as source(\"repo/dev/run.R\") from the project root.",
       call. = FALSE)
}
repo <- file.path(root, "repo")
# The style workshop moved inside the repo (2026-08-25) so the 12 rebuilt
# format.yml files are version-controlled. It is .Rbuildignore'd, so it is
# tracked by git but never ships in the package tarball.
workshop <- file.path(repo, "design-sets")
setwd(root)

for (p in c("devtools", "callr", "yaml")) {
  if (!requireNamespace(p, quietly = TRUE)) stop("Package '", p, "' is required.", call. = FALSE)
}

report <- file.path(root, "run-report.txt")
lines <- c(paste("docdesigner run report —", format(Sys.time())), "")

# ---- 1. parse every YAML source before building anything -------------------
lines <- c(lines, "== YAML parse check ==")
bad <- 0L
for (f in c(file.path(repo, "inst/engine/schema.yml"), Sys.glob("repo/design-sets/*/format.yml"))) {
  n <- tryCatch(length(unlist(yaml::read_yaml(f))),
                error = function(e) paste("ERROR:", conditionMessage(e)))
  if (is.character(n)) bad <- bad + 1L
  lines <- c(lines, sprintf("  %-42s %s", sub(paste0(root, "/"), "", f, fixed = TRUE), n))
}
if (bad > 0L) {
  lines <- c(lines, "", sprintf("%d file(s) failed to parse — stopping before install.", bad))
  writeLines(lines, report); cat(paste(lines, collapse = "\n"), "\n")
  stop("Fix the YAML above first.", call. = FALSE)
}
lines <- c(lines, "  all parsed OK", "")

# ---- 2. install ------------------------------------------------------------
cat("Installing...\n")
devtools::install(repo, quiet = TRUE, upgrade = FALSE)

# ---- 2b. validate every style against the schema ---------------------------
# designer_validate_style() has always existed; nothing ever called it, so a
# style could name 19 tokens that do not exist and still render "OK". That is
# how demography's `headings.case: smallcaps` -- its stated signature -- has
# never once rendered: wrong key, no error, no small caps. Same shape as the
# margin bug. Errors are reported here but do NOT stop the render, because
# most of the current ones are unimplemented vocabulary rather than mistakes;
# the point is that they can no longer be invisible.
cat("Validating styles...\n")
vres <- callr::r(function(root) {
  setwd(root)
  out <- list()
  for (d in Sys.glob("repo/design-sets/*/format.yml")) {
    s <- dirname(d)
    r <- tryCatch(docdesigner::designer_validate_style(s), error = function(e) NULL)
    n <- if (is.null(r)) NA_integer_ else sum(r$severity == "error", na.rm = TRUE)
    out[[basename(s)]] <- n
  }
  out
}, args = list(root = root), show = FALSE)

lines <- c(lines, "== schema validation (errors per style) ==")
for (nm in names(vres)) {
  n <- vres[[nm]]
  lines <- c(lines, sprintf("  %-12s %s", nm,
                            if (is.na(n)) "could not validate" else paste(n, "error(s)")))
}
lines <- c(lines, "  (designer_validate_style(\"repo/design-sets/<style>\") for detail)", "")

# ---- 3. render + verify in a clean subprocess ------------------------------
cat("Rendering in a fresh R subprocess (no restart needed)...\n")
out <- callr::r(
  function(root) {
    setwd(root)
    r <- capture.output(source(file.path(root, "repo/dev/render-design-sets.R")))
    v <- capture.output({ source(file.path(root, "repo/dev/verify-tokens.R")); verify_tokens() })
    list(render = r, verify = v)
  },
  args = list(root = root),
  show = FALSE
)

lines <- c(lines, "== render ==", out$render, "", "== verify ==", out$verify)
writeLines(lines, report)
cat("\nWrote", report, "\n")
cat(paste(tail(lines, 30), collapse = "\n"), "\n")
