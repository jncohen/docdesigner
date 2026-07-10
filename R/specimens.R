# Render one PDF specimen per installed style and index them in a gallery page.
#
# This is the only code path in the package that actually invokes xelatex, so
# it is also the package's real smoke test: a style can resolve its tokens
# cleanly and still fail to compile.

dd_specimen <- function() dd_pkg_file("specimen", "specimen.md")

# Keep error reports short. A xelatex failure surfaces through rmarkdown as a
# long message whose informative line is rarely the first one.
dd_error_digest <- function(msg, n = 3L) {
  lines <- trimws(unlist(strsplit(msg, "\n", fixed = TRUE)))
  lines <- lines[nzchar(lines)]
  if (!length(lines)) return("(no message)")
  paste(utils::tail(lines, n), collapse = " / ")
}

#' Render a PDF specimen for every installed style
#'
#' Renders the bundled specimen document once per style, then writes an HTML
#' index grouped by style set. Styles are rendered independently: one failure
#' does not stop the rest, and failures are reported rather than thrown.
#'
#' Requires a working LaTeX installation (`xelatex`) and Pandoc. Run
#' [designer_check()] first if you are unsure.
#'
#' @param styles Character vector of style ids. Defaults to every installed
#'   style, as reported by [designer_styles()].
#' @param output_dir Directory to write specimens and the index into.
#' @param index If `TRUE`, write `index.html` linking every specimen.
#' @param open If `TRUE`, open the index in a browser.
#' @param quiet Passed to [rmarkdown::render()].
#' @return A data frame of results, invisibly: one row per style with its
#'   status, output path, render time, and any error digest.
#' @export
designer_specimens <- function(styles = NULL,
                               output_dir = "rendered-examples/specimens",
                               index = TRUE,
                               open = interactive(),
                               quiet = TRUE) {
  if (!requireNamespace("rmarkdown", quietly = TRUE)) {
    stop("The rmarkdown package is required to render specimens.", call. = FALSE)
  }
  src <- dd_specimen()
  if (!file.exists(src)) {
    stop("Bundled specimen document not found: ", src, call. = FALSE)
  }

  all <- suppressWarnings(designer_styles())
  if (!nrow(all)) stop("No styles are installed.", call. = FALSE)
  if (!is.null(styles)) {
    unknown <- setdiff(styles, all$style)
    if (length(unknown)) {
      stop("Unknown style(s): ", paste(unknown, collapse = ", "),
           "\nAvailable: ", paste(all$style, collapse = ", "), call. = FALSE)
    }
    all <- all[all$style %in% styles, , drop = FALSE]
  }

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output_dir <- normalizePath(output_dir, winslash = "/", mustWork = FALSE)

  rows <- lapply(seq_len(nrow(all)), function(i) {
    style <- all$style[i]
    # render() writes intermediates beside its input, so give each style its
    # own copy inside output_dir rather than polluting inst/.
    input <- file.path(output_dir, paste0("specimen-", style, ".md"))
    file.copy(src, input, overwrite = TRUE)
    out <- paste0("specimen-", style, ".pdf")
    t0 <- Sys.time()
    err <- NULL
    ok <- tryCatch({
      rmarkdown::render(input,
                        output_format = pdf(style = style),
                        output_file = out,
                        output_dir = output_dir,
                        quiet = quiet)
      TRUE
    }, error = function(e) {
      err <<- conditionMessage(e)
      FALSE
    })
    unlink(input)
    if (!isTRUE(quiet)) message("")
    message(sprintf("%-5s %-12s %s", if (ok) "OK" else "FAIL", style,
                    if (ok) out else dd_error_digest(err)))
    data.frame(
      style = style,
      set = all$set[i],
      status = if (ok) "OK" else "FAIL",
      file = if (ok) file.path(output_dir, out) else NA_character_,
      seconds = round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1),
      error = if (ok) NA_character_ else dd_error_digest(err),
      stringsAsFactors = FALSE)
  })
  res <- do.call(rbind, rows)

  n_ok <- sum(res$status == "OK")
  message("\n", n_ok, " of ", nrow(res), " styles rendered.")
  if (n_ok < nrow(res)) {
    message("Failed: ", paste(res$style[res$status == "FAIL"], collapse = ", "))
    message("Run designer_check() to confirm xelatex and pandoc are available.")
  }

  if (isTRUE(index) && n_ok > 0) {
    idx <- write_specimen_index(res, output_dir)
    message("Gallery: ", idx)
    if (isTRUE(open)) {
      utils::browseURL(normalizePath(idx, winslash = "/", mustWork = FALSE))
    }
  }

  invisible(res)
}

write_specimen_index <- function(res, output_dir) {
  output <- file.path(output_dir, "index.html")

  card <- function(i) {
    style <- res$style[i]
    spec <- suppressWarnings(designer_style(style))
    accent <- dd_hex(spec$color$accent)
    failed <- res$status[i] == "FAIL"
    body <- if (failed) {
      paste0("<p class=\"fail\">Render failed: ", html_escape(res$error[i]), "</p>")
    } else {
      paste0("<p><a href=\"", html_escape(basename(res$file[i])), "\">",
             "Open specimen PDF</a> <span class=\"muted\">(",
             res$seconds[i], "s)</span></p>")
    }
    paste0(
      "<article class=\"card", if (failed) " card-fail" else "", "\">",
      "<div class=\"bar\" style=\"background:#", accent, "\"></div>",
      "<h3>", html_escape(spec$label %||% style), "</h3>",
      "<p class=\"muted\">", html_escape(spec$description %||% ""), "</p>",
      "<dl>",
      "<dt>id</dt><dd><code>", html_escape(style), "</code></dd>",
      "<dt>body</dt><dd>", html_escape(spec$typography$body), "</dd>",
      "<dt>heading</dt><dd>", html_escape(spec$typography$heading), "</dd>",
      "<dt>size</dt><dd>", html_escape(spec$typography$base_size), "</dd>",
      "<dt>columns</dt><dd>", html_escape(as.character(spec$page$columns %||% 1)), "</dd>",
      "<dt>accent</dt><dd><code>#", accent, "</code></dd>",
      "<dt>title</dt><dd><code>", html_escape(spec$title$layout %||% "plain"), "</code></dd>",
      "<dt>highlight</dt><dd><code>", html_escape(spec$code$highlight %||% "tango"), "</code></dd>",
      "</dl>", body, "</article>")
  }

  sections <- unlist(lapply(sort(unique(res$set)), function(set) {
    rows <- which(res$set == set)
    c(paste0("<h2>", html_escape(set), " <span class=\"muted\">(",
             length(rows), " styles)</span></h2>"),
      "<div class=\"grid\">",
      vapply(rows, card, character(1)),
      "</div>")
  }))

  page <- c(
    "<!doctype html>", "<html lang=\"en\">", "<head>",
    "<meta charset=\"utf-8\">",
    "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
    "<title>docdesigner Style Gallery</title>", "<style>",
    "body{font-family:system-ui,-apple-system,Segoe UI,sans-serif;margin:2rem;line-height:1.45;color:#222}",
    "main{max-width:1100px;margin:0 auto}",
    "h1{font-size:1.8rem;margin-bottom:.25rem}",
    "h2{font-size:1.1rem;text-transform:uppercase;letter-spacing:.05em;color:#444;",
    "border-bottom:1px solid #ddd;padding-bottom:.4rem;margin-top:2.5rem}",
    ".muted{color:#666;font-weight:400}",
    ".grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:1.25rem;margin-top:1.25rem}",
    ".card{border:1px solid #ddd;border-radius:6px;padding:0 1rem 1rem;overflow:hidden}",
    ".card-fail{border-color:#c00;background:#fff8f8}",
    ".bar{height:6px;margin:0 -1rem 1rem}",
    ".card h3{margin:.2rem 0 .3rem;font-size:1.05rem}",
    ".card p{margin:.35rem 0;font-size:.9rem}",
    "dl{display:grid;grid-template-columns:auto 1fr;gap:.15rem .75rem;font-size:.82rem;margin:.75rem 0}",
    "dt{color:#666}", "dd{margin:0}",
    ".fail{color:#c00;font-size:.8rem;word-break:break-word}",
    "code{font-family:ui-monospace,SFMono-Regular,Consolas,monospace;font-size:.9em}",
    "a{color:#06c}",
    "</style>", "</head>", "<body>", "<main>",
    "<h1>docdesigner Style Gallery</h1>",
    paste0("<p class=\"muted\">", nrow(res), " styles from ",
           length(unique(res$set)), " installed sets. Rendered ",
           format(Sys.Date(), "%d %B %Y"), ".</p>"),
    sections,
    "</main>", "</body>", "</html>")

  writeLines(page, output, useBytes = TRUE)
  output
}
