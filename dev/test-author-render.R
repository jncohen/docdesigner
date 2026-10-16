# Render a structured-author document in EVERY installed style and check the
# name reaches both the .tex \author{} line and the PDF text. Needs xelatex,
# so it lives in dev/ rather than tests/ (which must stay CRAN-safe).
#
#   Rscript repo/dev/test-author-render.R
#
# Regression for: a list of author objects printed "TRUE" in the title block.

res <- callr::r(function() {
  styles <- docdesigner::designer_styles()$style
  forms <- list(
    string = 'author: "Joseph N. Cohen"',
    object = c("author:", '  - name: "Joseph N. Cohen"', '    dept: "Department of Sociology"'),
    two    = c("author:", '  - name: "Joseph N. Cohen"', '    inst: "Queens College"',
               '  - name: "Ada Lovelace"'))
  out <- list()
  for (s in styles) for (f in names(forms)) {
    d <- file.path(tempdir(), "authors", s, f)
    dir.create(d, recursive = TRUE, showWarnings = FALSE)
    rmd <- file.path(d, "t.Rmd")
    writeLines(c("---", 'title: "T"', forms[[f]], "---", "", "Hello."), rmd)
    fmt <- docdesigner::pdf(style = s, keep_tex = TRUE)
    ok <- tryCatch({
      pdf <- rmarkdown::render(rmd, output_format = fmt, quiet = TRUE)
      tex <- readLines(sub("\\.pdf$", ".tex", pdf), warn = FALSE)
      line <- grep("^\\\\author\\{", tex, value = TRUE)
      text <- paste(pdftools::pdf_text(pdf), collapse = " ")
      # Case-insensitive: some styles set the byline in capitals or small caps.
      name_tex <- grepl("Joseph N. Cohen", paste(line, collapse = " "), fixed = TRUE)
      name_pdf <- grepl("joseph n. cohen", tolower(text), fixed = TRUE)
      no_true  <- !grepl("\\btrue\\b", tolower(text))
      second   <- f != "two" || grepl("ada lovelace", tolower(text), fixed = TRUE)
      if (name_tex && name_pdf && no_true && second) "PASS"
      else sprintf("FAIL tex=%s pdf=%s no_true=%s second=%s", name_tex, name_pdf, no_true, second)
    }, error = function(e) paste("ERROR:", conditionMessage(e)))
    out[[length(out) + 1]] <- data.frame(style = s, form = f, result = ok)
  }
  do.call(rbind, out)
})
print(res, row.names = FALSE)
cat(sprintf("\n%d of %d passed\n", sum(res$result == "PASS"), nrow(res)))
