# Render the short specimens: examples/specimen-short.Rmd in every installed
# style, once per title layout, each as its own PDF, plus a PNG of each first
# page for the gallery.
#
#   source("dev/render-specimens.R")              # from the repository
#   Rscript dev/render-specimens.R nature ssrn    # a subset of styles
#
# Renders the INSTALLED package, in a fresh R process, so install first
# (dev/run.R does). Output, under dev/out/specimens/ (not tracked):
#   <style>-header.pdf   title block at the head of page 1
#   <style>-page.pdf     title page of its own
#   <style>-<layout>.png page 1 at 110 dpi
#   index.csv            style, set, layout, pages, status

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
repo <- if (!is.null(.dd_script)) dirname(dirname(normalizePath(.dd_script, winslash = "/"))) else
  normalizePath(getwd(), winslash = "/")
outdir <- file.path(repo, "dev", "out", "specimens")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
wanted <- if (sys.nframe() == 0L) commandArgs(trailingOnly = TRUE) else character()

res <- callr::r(function(repo, outdir, wanted) {
  styles <- docdesigner::designer_styles()
  styles <- styles[order(styles$set, styles$style), c("style", "set")]
  if (length(wanted)) styles <- styles[styles$style %in% wanted, ]
  work <- file.path(tempdir(), "dd-specimens")
  unlink(work, recursive = TRUE); dir.create(work)
  file.copy(file.path(repo, "examples", c("specimen-short.Rmd", "gallery-document.bib")), work)
  rows <- list()
  for (i in seq_len(nrow(styles))) for (lay in c("header", "page")) {
    st <- styles$style[i]
    out <- sprintf("%s-%s.pdf", st, lay)
    r <- tryCatch({
      pdf <- rmarkdown::render(file.path(work, "specimen-short.Rmd"),
        output_format = docdesigner::pdf(style = st, title_layout = lay),
        params = list(style = st), output_file = out, output_dir = outdir,
        quiet = TRUE, envir = new.env(parent = globalenv()))
      pdftools::pdf_convert(pdf, pages = 1, dpi = 110, verbose = FALSE,
                            filenames = file.path(outdir, sub("pdf$", "png", out)))
      list(pages = pdftools::pdf_info(pdf)$pages, status = "OK")
    }, error = function(e) list(pages = 0L, status = paste("FAIL:", conditionMessage(e))))
    rows[[length(rows) + 1]] <- data.frame(style = st, set = styles$set[i], layout = lay,
                                           file = out, pages = r$pages, status = r$status)
  }
  do.call(rbind, rows)
}, args = list(repo = repo, outdir = outdir, wanted = wanted), show = FALSE)

utils::write.csv(res, file.path(outdir, "index.csv"), row.names = FALSE)
print(res[, c("style", "layout", "pages", "status")], row.names = FALSE)
cat(sprintf("\n%d of %d specimens OK in %s\n", sum(res$status == "OK"), nrow(res), outdir))
