# Copy the rendered specimens into the website's assets, with thumbnails, so
# the Style gallery article (vignettes/articles/gallery.Rmd) can show them.
#
#   source("dev/render-specimens.R")    # first: renders dev/out/specimens/
#   source("dev/publish-specimens.R")   # then: refreshes pkgdown/assets/specimens/
#
# pkgdown copies pkgdown/assets/ to the site root, so the files are served at
# <site>/specimens/. They are committed: the site is built on CI, which has no
# TeX installation to render them, and specimens change only with the styles.
# Stale files (a style that no longer ships) are removed.

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
src  <- file.path(repo, "dev", "out", "specimens")
dest <- file.path(repo, "pkgdown", "assets", "specimens")
idx  <- utils::read.csv(file.path(src, "index.csv"), stringsAsFactors = FALSE)
if (any(idx$status != "OK")) stop("Some specimens failed; re-render them first.", call. = FALSE)

dir.create(dest, recursive = TRUE, showWarnings = FALSE)
unlink(list.files(dest, full.names = TRUE))
for (f in idx$file) {
  file.copy(file.path(src, f), dest)
  # 40 dpi gives a 340 px wide page: a sharp thumbnail at gallery size on a
  # high-density screen, at about 30 KB.
  pdftools::pdf_convert(file.path(src, f), pages = 1, dpi = 40, verbose = FALSE,
                        filenames = file.path(dest, sub("pdf$", "png", f)))
  # A markup style's specimen (review) also gets its first body page, where
  # the line and paragraph numbers, flags and changebars show.
  if (identical(sub("-header\\.pdf$", "", f), "review")) {
    pdftools::pdf_convert(file.path(src, f), pages = 2, dpi = 40, verbose = FALSE,
                          filenames = file.path(dest, sub("\\.pdf$", "-body.png", f)))
  }
  # A thesis specimen also gets its first chapter page, the first page whose
  # text opens with the chapter "1 Introduction".
  if (grepl("-thesis\\.pdf$", f)) {
    txt <- pdftools::pdf_text(file.path(src, f))
    body <- which(grepl("^\\s*1\\s+Introduction", txt))[1]
    if (!is.na(body)) {
      pdftools::pdf_convert(file.path(src, f), pages = body, dpi = 40, verbose = FALSE,
                            filenames = file.path(dest, sub("\\.pdf$", "-body.png", f)))
    }
  }
}
size <- sum(file.size(list.files(dest, full.names = TRUE)))
cat(sprintf("Published %d specimens (%.1f MB) to %s\n", nrow(idx), size / 2^20, dest))
