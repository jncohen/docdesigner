#' Write a local style gallery
#'
#' Creates a small HTML page that lists the installed PDF styles with color
#' swatches and style metadata. This is a local browsing aid; it does not
#' require a website.
#'
#' @param output_dir Directory where the gallery HTML should be written.
#' @param file Gallery filename.
#' @param open If `TRUE`, open the gallery in a browser.
#' @return The gallery path, invisibly.
#' @export
designer_gallery <- function(output_dir = "rendered-examples/gallery",
                             file = "style-gallery.html",
                             open = interactive()) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output <- file.path(output_dir, file)
  styles <- designer_styles()

  rows <- vapply(seq_len(nrow(styles)), function(i) {
    spec <- designer_style(styles$style[i])
    accent <- sub("^#", "", spec$color$accent %||% "333333")
    paste0(
      "<tr>",
      "<td><code>", html_escape(styles$style[i]), "</code></td>",
      "<td>", html_escape(styles$label[i]), "</td>",
      "<td>", html_escape(styles$description[i]), "</td>",
      "<td><code>", html_escape(styles$set[i]), "</code></td>",
      "<td><span class=\"swatch\" style=\"background:#", html_escape(accent),
      "\"></span><code>", html_escape(accent), "</code></td>",
      "<td><code>", html_escape(spec$highlight %||% "tango"), "</code></td>",
      "</tr>"
    )
  }, character(1))

  page <- c(
    "<!doctype html>",
    "<html lang=\"en\">",
    "<head>",
    "<meta charset=\"utf-8\">",
    "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
    "<title>docdesigner Style Gallery</title>",
    "<style>",
    "body{font-family:system-ui,-apple-system,Segoe UI,sans-serif;margin:2rem;line-height:1.45;color:#222}",
    "main{max-width:1100px;margin:0 auto}",
    "h1{font-size:1.8rem;margin-bottom:.25rem}",
    "p{margin-top:0;color:#555}",
    "table{width:100%;border-collapse:collapse;margin-top:1.5rem}",
    "th,td{text-align:left;vertical-align:top;border-bottom:1px solid #ddd;padding:.65rem}",
    "th{font-size:.85rem;text-transform:uppercase;letter-spacing:.04em;color:#555}",
    "code{font-family:ui-monospace,SFMono-Regular,Consolas,monospace;font-size:.9em}",
    ".swatch{display:inline-block;width:1.1rem;height:1.1rem;border:1px solid #aaa;margin-right:.45rem;vertical-align:-.18rem}",
    "</style>",
    "</head>",
    "<body>",
    "<main>",
    "<h1>docdesigner Style Gallery</h1>",
    "<p>Styles apply to <code>docdesigner::pdf</code>. Snapshot uses the official house style, and HTML is intentionally plain.</p>",
    "<table>",
    "<thead><tr><th>Style</th><th>Label</th><th>Description</th><th>Set</th><th>Accent</th><th>Highlight</th></tr></thead>",
    "<tbody>",
    rows,
    "</tbody>",
    "</table>",
    "</main>",
    "</body>",
    "</html>"
  )

  writeLines(page, output, useBytes = TRUE)
  if (isTRUE(open)) {
    utils::browseURL(normalizePath(output, winslash = "/", mustWork = FALSE))
  }

  invisible(output)
}

html_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}
