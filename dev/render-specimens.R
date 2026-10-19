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
#   <style>-thesis.pdf   a thesis style, in the thesis layout
#   review-header.pdf    the review style, on examples/specimen-review.Rmd: the
#                        short specimen revised (flags, rewritten headings, a
#                        reworded paragraph), with changebars against it
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
  file.copy(file.path(repo, "examples", c("specimen-short.Rmd", "specimen-review.Rmd",
                                          "specimen-short.bib", "scf2022-specimen.csv")), work)
  rows <- list()
  # A thesis style is shown in its own layout (title page, front matter,
  # chapters); every other style with the title on page 1 and on a page
  # of its own.
  # A markup style (review) is a working draft: shown once, title on page 1,
  # on the revised specimen so its flags and changebars have work to do.
  markup_style <- function(st) docdesigner:::dd_markup_on(
    docdesigner:::dd_flatten_dotted(docdesigner::designer_style(st)))
  layouts_of <- function(st) {
    if (identical(docdesigner:::dd_title_layout(docdesigner::designer_style(st)), "thesis")) "thesis"
    else if (markup_style(st)) "header"
    else c("header", "page")
  }
  for (i in seq_len(nrow(styles))) for (lay in layouts_of(styles$style[i])) {
    st <- styles$style[i]
    out <- sprintf("%s-%s.pdf", st, lay)
    r <- tryCatch({
      review <- markup_style(st)
      src <- if (review) "specimen-review.Rmd" else "specimen-short.Rmd"
      pdf <- rmarkdown::render(file.path(work, src),
        output_format = docdesigner::pdf(style = st, title_layout = lay, toc = identical(lay, "thesis"),
                                         changes_since = if (review) file.path(work, "specimen-short.Rmd")),
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
