# Page-level regression baseline for the template port (planning/NOTEBOOK.md
# section 3). The port must change nothing on the page except what each step
# intends, and "nothing changed" needs evidence, not a run report.
#
#   source("repo/dev/page-baseline.R")
#   capture_baseline("port-baseline")             # once, before the port
#   capture_baseline("port-current")              # after each port step
#   compare_baseline("port-baseline", "port-current")
#
# capture_baseline() renders, into <dir>:
#   drafts/<style>.pdf      each design-sets draft, title as a header block
#   titlepage/<style>.pdf   the same with title.page_break_after: true
#   installed/<style>.pdf   designer_specimens() from the INSTALLED package
#   snapshot.pdf            snapshot() on the bundled example
#   preamble/<style>.tex    dd_preamble() for each installed style
#   manifest.txt            commit, package version, pandoc, page counts
#
# compare_baseline() renders every page of both captures to bitmaps and
# reports, per document, the page counts and the share of pixels that differ
# on each page. Pages over the threshold get a diff image in <new>/diffs/.
#
# Run it in a FRESH R session that has not loaded docdesigner: it renders in
# callr subprocesses, like run.R, so the installed package is what renders.

.pb_root <- local({
  of <- NULL
  for (i in rev(seq_len(sys.nframe()))) {
    of <- sys.frame(i)$ofile
    if (!is.null(of)) break
  }
  if (is.null(of)) normalizePath(getwd(), winslash = "/")
  else dirname(dirname(dirname(normalizePath(of, winslash = "/"))))
})

capture_baseline <- function(dir, root = .pb_root) {
  dir <- normalizePath(file.path(root, dir), winslash = "/", mustWork = FALSE)
  for (sub in c("drafts", "titlepage", "installed", "preamble")) {
    dir.create(file.path(dir, sub), recursive = TRUE, showWarnings = FALSE)
  }
  ds <- file.path(root, "repo", "design-sets")
  styles <- setdiff(basename(list.dirs(ds, recursive = FALSE)), "_template")
  styles <- styles[file.exists(file.path(ds, styles, "format.yml"))]

  # Drafts, both title treatments. Each renders in its own temp folder so the
  # workshop's own specimen.pdf files are never touched.
  log <- callr::r(function(ds, styles, dir) {
    out <- character()
    for (s in styles) for (variant in c("drafts", "titlepage")) {
      w <- file.path(tempdir(), "pb", variant, s)
      unlink(w, recursive = TRUE); dir.create(w, recursive = TRUE)
      for (f in c("format.yml", "specimen.Rmd", "specimen.bib", "figure.png")) {
        file.copy(file.path(ds, s, f), w)
      }
      if (variant == "titlepage") {
        cat("\ntitle.page_break_after: true\n", file = file.path(w, "format.yml"), append = TRUE)
      }
      ok <- tryCatch({
        pdf <- rmarkdown::render(file.path(w, "specimen.Rmd"), quiet = TRUE)
        file.copy(pdf, file.path(dir, variant, paste0(s, ".pdf")), overwrite = TRUE)
        "OK"
      }, error = function(e) paste("FAIL:", conditionMessage(e)))
      out <- c(out, sprintf("%-10s %-11s %s", variant, s, ok))
    }
    out
  }, args = list(ds = ds, styles = styles, dir = dir))

  # The installed package's own specimens, every installed preamble, and
  # snapshot() -- the format step 4 folds into pdf().
  log <- c(log, callr::r(function(dir, root) {
    out <- character()
    tmp <- file.path(tempdir(), "pb-installed")
    r <- docdesigner::designer_specimens(output_dir = tmp, index = FALSE, open = FALSE)
    for (i in seq_len(nrow(r))) {
      if (r$status[i] == "OK") {
        file.copy(r$file[i], file.path(dir, "installed", paste0(r$style[i], ".pdf")), overwrite = TRUE)
      }
      out <- c(out, sprintf("%-10s %-11s %s", "installed", r$style[i], r$status[i]))
      writeLines(docdesigner:::dd_preamble(docdesigner:::dd_resolve_style(r$style[i])),
                 file.path(dir, "preamble", paste0(r$style[i], ".tex")))
    }
    ex <- file.path(root, "repo", "examples")
    w <- file.path(tempdir(), "pb-snapshot")
    unlink(w, recursive = TRUE); dir.create(w)
    file.copy(list.files(ex, pattern = "^intro-to-docdesigner-snapshot", full.names = TRUE), w)
    ok <- tryCatch({
      pdf <- rmarkdown::render(file.path(w, "intro-to-docdesigner-snapshot.Rmd"), quiet = TRUE)
      file.copy(pdf, file.path(dir, "snapshot.pdf"), overwrite = TRUE)
      "OK"
    }, error = function(e) paste("FAIL:", conditionMessage(e)))
    c(out, sprintf("%-10s %-11s %s", "snapshot", "-", ok))
  }, args = list(dir = dir, root = root)))

  pdfs <- list.files(dir, pattern = "\\.pdf$", recursive = TRUE)
  pages <- vapply(file.path(dir, pdfs), function(f) pdftools::pdf_info(f)$pages, integer(1))
  sha <- tryCatch(system2("git", c("-C", file.path(root, "repo"), "rev-parse", "--short", "HEAD"),
                          stdout = TRUE), error = function(e) "unknown")
  ver <- callr::r(function() as.character(utils::packageVersion("docdesigner")))
  pan <- callr::r(function() as.character(rmarkdown::pandoc_version()))
  writeLines(c(
    paste("captured:", format(Sys.time(), "%Y-%m-%d %H:%M")),
    paste("commit:", sha), paste("installed docdesigner:", ver), paste("pandoc:", pan), "",
    "== renders ==", log, "",
    "== page counts ==", sprintf("%-28s %d", pdfs, pages)),
    file.path(dir, "manifest.txt"))
  cat(sprintf("Captured %d PDFs into %s\n", length(pdfs), dir))
  fails <- grep("FAIL", log, value = TRUE)
  if (length(fails)) cat("FAILURES:\n", paste(fails, collapse = "\n"), "\n")
  invisible(dir)
}

# Share of pixels that differ between two page bitmaps (any channel off by
# more than `tol` of 255). Pages of different sizes count as fully changed.
.pb_page_diff <- function(a, b, tol = 24) {
  if (!identical(dim(a), dim(b))) return(1)
  d <- abs(as.integer(a) - as.integer(b)) > tol
  dim(d) <- dim(a)
  mean(apply(d, c(2, 3), any))
}

compare_baseline <- function(base, new, root = .pb_root, dpi = 40, threshold = 0.001) {
  base <- file.path(root, base); new <- file.path(root, new)
  pdfs <- intersect(list.files(base, pattern = "\\.pdf$", recursive = TRUE),
                    list.files(new, pattern = "\\.pdf$", recursive = TRUE))
  diffs <- file.path(new, "diffs"); dir.create(diffs, showWarnings = FALSE)
  rows <- lapply(pdfs, function(p) {
    nb <- pdftools::pdf_info(file.path(base, p))$pages
    nn <- pdftools::pdf_info(file.path(new, p))$pages
    changed <- character()
    for (pg in seq_len(min(nb, nn))) {
      a <- pdftools::pdf_render_page(file.path(base, p), page = pg, dpi = dpi, numeric = FALSE)
      b <- pdftools::pdf_render_page(file.path(new, p), page = pg, dpi = dpi, numeric = FALSE)
      share <- .pb_page_diff(a, b)
      if (share > threshold) {
        changed <- c(changed, sprintf("p%d %.1f%%", pg, 100 * share))
        stem <- file.path(diffs, paste0(gsub("[/.]", "_", p), "-p", pg))
        pdftools::pdf_convert(file.path(base, p), pages = pg, dpi = 2 * dpi,
                              filenames = paste0(stem, "-base.png"), verbose = FALSE)
        pdftools::pdf_convert(file.path(new, p), pages = pg, dpi = 2 * dpi,
                              filenames = paste0(stem, "-new.png"), verbose = FALSE)
      }
    }
    data.frame(document = p, pages_base = nb, pages_new = nn,
               changed = if (length(changed)) paste(changed, collapse = ", ") else "",
               status = if (nb != nn || length(changed)) "CHANGED" else "same",
               stringsAsFactors = FALSE)
  })
  res <- do.call(rbind, rows)
  print(res, row.names = FALSE)
  cat(sprintf("\n%d of %d documents identical at %d dpi.\n", sum(res$status == "same"), nrow(res), dpi))
  invisible(res)
}
