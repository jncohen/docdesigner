# Render the specimen gallery: every installed style, twice -- once with the
# title as a block at the head of the first page (title.layout: header) and
# once with a title page of its own (title.layout: page) -- and combine the
# renders into one PDF behind a contents page.
#
# The document is examples/gallery-document.Rmd: a short real analysis of R's
# airquality data with three figures, three tables, a quotation, a code
# block, a callout and a bibliography.
#
# Usage (renders the INSTALLED package, so install the current source first):
#   Rscript render-gallery.R
#   Rscript render-gallery.R nature economist       # a subset of styles
#   Rscript render-gallery.R design-sets/policy      # a draft style folder
#
# Output: rendered-examples/gallery/docdesigner-specimens.pdf, plus each
# render on its own under rendered-examples/gallery/renders/.

for (pkg in c("rmarkdown", "docdesigner", "pdftools")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("render-gallery.R needs the '", pkg, "' package.", call. = FALSE)
  }
}

script_path <- tryCatch(
  normalizePath(sys.frame(1)$ofile, winslash = "/", mustWork = TRUE),
  error = function(e) {
    flag <- grep("--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
    if (length(flag)) normalizePath(sub("--file=", "", flag), winslash = "/", mustWork = TRUE)
    else normalizePath("render-gallery.R", winslash = "/", mustWork = TRUE)
  }
)
repo_dir    <- dirname(script_path)
doc_src     <- file.path(repo_dir, "examples", c("gallery-document.Rmd", "gallery-document.bib"))
gallery_dir <- file.path(repo_dir, "rendered-examples", "gallery")
render_dir  <- file.path(gallery_dir, "renders")
dir.create(render_dir, recursive = TRUE, showWarnings = FALSE)

styles <- docdesigner::designer_styles()
styles <- styles[order(styles$set, styles$style), c("style", "set")]
wanted <- commandArgs(trailingOnly = TRUE)
if (length(wanted)) {
  # A folder holding format.yml is a draft: render it by path, labelled "draft".
  is_draft <- file.exists(file.path(wanted, "format.yml"))
  drafts <- if (any(is_draft)) data.frame(
    style = normalizePath(wanted[is_draft], winslash = "/"), set = "draft") else NULL
  styles <- rbind(styles[styles$style %in% wanted[!is_draft], ], drafts)
}
layouts <- c(header = "Title block on page 1", page = "Title page")

# Render in a scratch copy so knitr's intermediate files never land in examples/.
work <- file.path(tempdir(), "dd-gallery")
unlink(work, recursive = TRUE); dir.create(work)
file.copy(doc_src, work)

results <- data.frame(style = character(), set = character(), layout = character(),
                      file = character(), pages = integer(), status = character(),
                      message = character(), stringsAsFactors = FALSE)

for (i in seq_len(nrow(styles))) for (lay in names(layouts)) {
  st  <- styles$style[i]
  out <- file.path(render_dir, sprintf("%s-%s.pdf", basename(st), lay))
  cat(sprintf("Rendering %-11s %-6s ", st, lay))
  res <- tryCatch({
    pdf <- rmarkdown::render(
      file.path(work, "gallery-document.Rmd"),
      output_format = docdesigner::pdf(style = st, title_layout = lay),
      params = list(style = st, title_layout = lay),
      output_file = basename(out), output_dir = render_dir,
      quiet = TRUE, envir = new.env(parent = globalenv()))
    list(file = pdf, pages = pdftools::pdf_info(pdf)$pages, status = "OK", message = "")
  }, error = function(e) list(file = NA, pages = 0L, status = "FAIL",
                              message = conditionMessage(e)))
  cat(res$status, "\n")
  results[nrow(results) + 1, ] <- list(st, styles$set[i], lay, res$file, res$pages,
                                       res$status, res$message)
}

ok <- results[results$status == "OK", ]
if (!nrow(ok)) stop("No style rendered; nothing to combine.", call. = FALSE)

# Contents page: one row per render with the page it starts on. It is set in
# `minimal` so the cover itself is a docdesigner document.
ok$start <- 2L + cumsum(c(0L, head(ok$pages, -1)))
rows <- sprintf("| %s | %s | %s | %d |", basename(ok$style), ok$set, layouts[ok$layout], ok$start)
cover <- file.path(work, "contents.Rmd")
writeLines(c(
  "---",
  "title: \"docdesigner specimens\"",
  sprintf("subtitle: \"%d style%s, two title layouts each\"", length(unique(ok$style)),
          if (length(unique(ok$style)) == 1L) "" else "s"),
  sprintf("date: \"%s. docdesigner %s\"", format(Sys.Date(), "%B %d, %Y"),
          as.character(utils::packageVersion("docdesigner"))),
  "---",
  "",
  "Every style below sets the same document: a short analysis of R's",
  "`airquality` data with three figures, three tables, a quotation, a code",
  "block, a callout and a reference list. Each style appears twice. *Title",
  "block on page 1* is `title.layout: header`; *Title page* is",
  "`title.layout: page`. Page numbers refer to this combined file.",
  "",
  "| Style | Set | Title layout | Page |",
  "|:--|:--|:--|--:|",
  rows), cover)
cover_pdf <- rmarkdown::render(cover, output_format = docdesigner::pdf(style = "minimal"),
                               output_dir = work, quiet = TRUE)
if (pdftools::pdf_info(cover_pdf)$pages != 1L) {
  warning("The contents page ran past one page, so its page numbers are off.", call. = FALSE)
}

combined <- file.path(gallery_dir, "docdesigner-specimens.pdf")
pdftools::pdf_combine(c(cover_pdf, ok$file), output = combined)

cat("\nSpecimen gallery\n================\n")
print(results[, c("style", "layout", "pages", "status", "message")], row.names = FALSE)
cat(sprintf("\n%d of %d renders OK. Combined: %s (%d pages)\n", nrow(ok), nrow(results),
            combined, pdftools::pdf_info(combined)$pages))
if (any(results$status == "FAIL")) quit(status = 1)
invisible(results)
