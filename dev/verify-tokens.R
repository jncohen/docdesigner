# Assert that each style's DECLARED tokens actually survived to the rendered
# page. This is deliberately not a mockup-fidelity check — it asks only "did
# the engine do what the format.yml said", which is a yes/no question with a
# measurable answer.
#
# Why this exists: page.margin never worked. rmarkdown appended its own
# `geometry:margin=1in` after the engine's options, geometry let the later one
# win, and every style rendered at 1in for the entire life of the engine. The
# token was right in format.yml, right in the resolved spec, right in the
# pandoc args — and wrong on the page. Nothing checked the page, so nobody
# noticed. Two entries on FIDELITY-ASSESSMENT.md's "what's working" list
# (margins, h2/h3 numbering) turned out to be false the same way: asserted from
# a visual read, never measured.
#
# Scope is intentionally narrow. Only checks that are mechanically unambiguous
# are included. A small harness that is always right beats a broad one that
# cries wolf — a flaky check gets ignored, and an ignored check is worse than
# no check, because it looks like coverage.
#
# Usage (RStudio console):
#   setwd("D:/Google Drive/Documents/Software/docdesigner")
#   source("repo/dev/verify-tokens.R")
#   v <- verify_tokens()            # all styles
#   v <- verify_tokens("humanities")
#   subset(v, status != "PASS")     # just the failures

verify_tokens <- function(styles = NULL, root = getwd(), tol = 0.03,
                          page = 2L) {

  if (!requireNamespace("pdftools", quietly = TRUE)) {
    stop("The pdftools package is required: install.packages('pdftools').",
         call. = FALSE)
  }
  if (!requireNamespace("docdesigner", quietly = TRUE)) {
    stop("docdesigner must be installed.", call. = FALSE)
  }

  # Workshop moved to repo/design-sets on 2026-08-25; fall back to the old
  # sibling location for older checkouts.
  sets <- file.path(root, "repo", "design-sets")
  if (!dir.exists(sets)) sets <- file.path(root, "design-sets")
  dirs <- list.dirs(sets, recursive = FALSE, full.names = TRUE)
  dirs <- dirs[basename(dirs) != "_template"]
  if (!is.null(styles)) dirs <- dirs[basename(dirs) %in% styles]

  rows <- list()
  emit <- function(style, check, expected, got, status, note = "") {
    rows[[length(rows) + 1]] <<- data.frame(
      style = style, check = check,
      expected = as.character(expected), got = as.character(got),
      status = status, note = note, stringsAsFactors = FALSE)
  }

  for (dir in dirs) {
    style <- basename(dir)
    pdf <- file.path(dir, "specimen.pdf")
    if (!file.exists(file.path(dir, "format.yml")) || !file.exists(pdf)) {
      emit(style, "-", "-", "-", "SKIP", "no format.yml or no specimen.pdf")
      next
    }

    s <- tryCatch(docdesigner::designer_style(dir), error = function(e) NULL)
    if (is.null(s)) { emit(style, "-", "-", "-", "ERROR", "style won't resolve"); next }

    # pdf_info()$pages is the page COUNT, not per-page dimensions; page size
    # comes from pdf_pagesize(), one row per page.
    ps <- pdftools::pdf_pagesize(pdf)
    pg <- min(page, nrow(ps))
    pw <- ps$width[pg]; ph <- ps$height[pg]

    # ---- page size -------------------------------------------------------
    want_paper <- s$page$papersize %||% "letter"
    ref <- if (identical(want_paper, "a4")) c(595.28, 841.89) else c(612, 792)
    ok <- abs(pw - ref[1]) < 2 && abs(ph - ref[2]) < 2
    emit(style, "page.papersize", want_paper,
         sprintf("%.0f x %.0f pt", pw, ph),
         if (ok) "PASS" else "FAIL")

    # ---- margins ---------------------------------------------------------
    # Left/right only. The top and bottom ink includes any running head or
    # folio, which geometry deliberately places OUTSIDE the text block, so
    # measuring them against page.margins.top would produce false failures.
    # Left/right have no such furniture and are exactly where the design error
    # showed up, so this is the check that earns its keep.
    d <- tryCatch(pdftools::pdf_data(pdf)[[pg]], error = function(e) NULL)
    if (is.null(d) || !nrow(d)) {
      emit(style, "page.margins", "-", "-", "SKIP", "no text on page")
    } else {
      shorthand <- switch(as.character(s$page$margin %||% "normal"),
                          narrow = 0.75, wide = 1.35, 1)
      mg <- s$page$margins
      want_l <- (mg$inner %||% shorthand)
      want_r <- (mg$outer %||% shorthand)
      # Measure BODY ink only. A style with header_footer.header.fill draws a
      # masthead band that deliberately bleeds to the paper edge, and including
      # it made economist report a 0.000in left margin -- the band, not the
      # text block. Same lesson as the two-column detector: page furniture is
      # not body text. Trim the top and bottom bands before measuring.
      ph_pt <- max(d$y, na.rm = TRUE)
      body <- d[d$y > 0.06 * ph_pt & d$y < 0.94 * ph_pt, , drop = FALSE]
      if (!nrow(body)) body <- d
      got_l <- min(body$x) / 72
      got_r <- (pw - max(body$x + body$width)) / 72
      emit(style, "page.margins.inner (left)", sprintf("%.3f in", want_l),
           sprintf("%.3f in", got_l),
           if (abs(got_l - want_l) < tol) "PASS" else "FAIL")
      # The right edge is ragged whenever the text isn't justified, so a short
      # last line makes max(x) understate it. Only assert it when the style
      # actually justifies; otherwise report it for the eye.
      justified <- identical(s$typography$justify %||% TRUE, TRUE)
      emit(style, "page.margins.outer (right)", sprintf("%.3f in", want_r),
           sprintf("%.3f in", got_r),
           if (!justified) "INFO" else if (abs(got_r - want_r) < tol) "PASS" else "FAIL",
           if (!justified) "ragged right: not asserted" else "")
    }

    # ---- fonts -----------------------------------------------------------
    # pdffonts reports subset names like "ABCDEF+EBGaramond-Regular"; the
    # registry knows which file each family resolves to, so compare on the
    # file stem rather than the human-facing family name.
    reg <- tryCatch(docdesigner:::dd_font_registry(s), error = function(e) NULL)
    embedded <- tryCatch(pdftools::pdf_fonts(pdf)$name, error = function(e) character())
    embedded <- sub("^[A-Z]{6}\\+", "", embedded)
    for (role in c("body", "heading", "mono")) {
      fam <- s$typography[[role]]
      if (is.null(fam)) next
      stem <- tools::file_path_sans_ext(reg[[fam]]$regular %||% "")
      if (!nzchar(stem)) {
        emit(style, paste0("typography.", role), fam, "-", "ERROR",
             "family not in font registry")
        next
      }
      hit <- any(grepl(stem, embedded, fixed = TRUE))
      emit(style, paste0("typography.", role), fam,
           if (hit) stem else paste(utils::head(embedded, 3), collapse = " "),
           if (hit) "PASS" else "FAIL")
    }

    # ---- columns ---------------------------------------------------------
    # Count LINE STARTS right of the page midpoint. Under two columns roughly
    # half of all lines begin in the right half; under one column almost none
    # do. Two cruder tests failed here first: word-starts near the centre (the
    # second column begins at about the midpoint, so it never fired) and words
    # straddling the centre (nature's twocolumn-tables.lua promotes tables to
    # spanning table* floats, whose rows legitimately cross it). Line starts are
    # immune to both -- a spanning float still starts at the left margin.
    # Scan EVERY page and take the max: a single page proves nothing. nature is
    # genuinely two-column, but its page 2 is dominated by a spanning float, so
    # testing one page reported it as single-column. Any page that is clearly
    # two-column settles it; no page of a one-column document ever will be.
    want_cols <- s$page$columns %||% 1
    pages <- tryCatch(pdftools::pdf_data(pdf), error = function(e) NULL)
    # Two corrections learned from atlantic, which failed here as a phantom
    # two-column document. (1) The running head and the folio sit right of
    # centre on EVERY page -- they are furniture, not body text, and they
    # inflate the fraction on every page. Trim the top and bottom bands before
    # measuring. (2) The old guard, nrow(p) < 30, counted WORDS but the ratio
    # is taken over LINES; atlantic's page 5 (the tail of the references) held
    # 7 body lines, of which the head and folio were 2 -- 29%, over the 0.25
    # threshold, from a page that proves nothing. Require enough body lines
    # for the fraction to mean something.
    fracs <- vapply(pages, function(p) {
      if (is.null(p) || nrow(p) < 30) return(NA_real_)
      ph <- max(p$y, na.rm = TRUE)
      body <- p[p$y > 0.06 * ph & p$y < 0.94 * ph, , drop = FALSE]
      if (nrow(body) < 30) return(NA_real_)
      starts <- tapply(body$x, round(body$y), min)  # leftmost word of each line
      if (length(starts) < 15) return(NA_real_)
      sum(starts > pw / 2) / length(starts)
    }, numeric(1))
    if (any(!is.na(fracs))) {
      frac <- max(fracs, na.rm = TRUE)
      got_cols <- if (frac > 0.25) 2 else 1
      emit(style, "page.columns", want_cols, got_cols,
           if (identical(as.integer(want_cols), as.integer(got_cols))) "PASS" else "FAIL",
           sprintf("max %.0f%% line-starts right of centre over %d pages",
                   100 * frac, sum(!is.na(fracs))))
    }
  }

  res <- do.call(rbind, rows)
  n <- table(factor(res$status, levels = c("PASS", "FAIL", "INFO", "SKIP", "ERROR")))
  cat("\n== docdesigner token -> page verification ==\n\n")
  print(res[res$status %in% c("FAIL", "ERROR"), , drop = FALSE], row.names = FALSE)
  if (!any(res$status %in% c("FAIL", "ERROR"))) cat("No failures.\n")
  cat("\n", paste(sprintf("%s: %d", names(n), as.integer(n)), collapse = "   "), "\n", sep = "")
  cat("\nThis checks tokens against the page, not the page against the mockup.\n")
  invisible(res)
}

`%||%` <- function(a, b) if (is.null(a)) b else a
