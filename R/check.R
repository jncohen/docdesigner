#' Check a docdesigner setup
#'
#' Reports whether the package can find its bundled assets and common rendering
#' tools.
#'
#' @param path Project directory to inspect.
#' @param engine LaTeX engines to check.
#' @return A data frame with check results, invisibly printed as a compact report.
#' @export
designer_check <- function(path = ".",
                           engine = c("xelatex", "pdflatex", "lualatex")) {
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)

  style_names <- tryCatch(designer_styles()$style, error = function(e) character())

  schema <- dd_pkg_file("engine", "schema.yml")

  checks <- list(
    check_item("template", file.exists(dd_template()), dd_template()),
    check_item("fonts", dir.exists(dd_fonts_dir()), dd_fonts_dir()),
    check_item("csl", file.exists(dd_csl()), dd_csl()),
    # The schema is the source of truth for the token vocabulary AND supplies
    # every engine default. Without it nothing resolves.
    check_item("schema", file.exists(schema), schema),
    check_item("lua filter", file.exists(dd_pkg_file("engine", "twocolumn-tables.lua")),
               dd_pkg_file("engine", "twocolumn-tables.lua")),
    check_item("styles", length(style_names) > 0,
               paste(style_names, collapse = ", ")),
    check_item("rmarkdown", requireNamespace("rmarkdown", quietly = TRUE),
               "R package required for rendering"),
    check_item("project", dir.exists(path), path)
  )

  if (requireNamespace("rmarkdown", quietly = TRUE)) {
    checks <- c(checks, list(
      check_item("pandoc", rmarkdown::pandoc_available(),
                 as.character(rmarkdown::pandoc_version()))
    ))
  } else {
    checks <- c(checks, list(
      check_item("pandoc", FALSE, "cannot check until rmarkdown is installed")
    ))
  }

  for (eng in engine) {
    found <- Sys.which(eng)
    checks <- c(checks, list(
      check_item(paste0("engine:", eng), nzchar(found),
                 if (nzchar(found)) unname(found) else "not found on PATH")
    ))
  }

  out <- do.call(rbind, checks)
  rownames(out) <- NULL
  class(out) <- c("docdesigner_check", class(out))
  print(out)
  invisible(out)
}

check_item <- function(name, ok, detail = "") {
  data.frame(
    check = name,
    status = if (isTRUE(ok)) "OK" else "WARN",
    detail = detail,
    stringsAsFactors = FALSE
  )
}

#' @export
print.docdesigner_check <- function(x, ...) {
  cat("docdesigner check\n")
  cat("=================\n")
  for (i in seq_len(nrow(x))) {
    cat(sprintf("%-5s %-16s %s\n", x$status[i], x$check[i], x$detail[i]))
  }
  invisible(x)
}

dd_fonts_dir <- function() {
  fonts <- system.file("fonts", package = "docdesigner")
  if (!nzchar(fonts)) {
    file.path(getwd(), "inst", "fonts")
  } else {
    fonts
  }
}

dd_csl <- function() {
  csl <- system.file("csl/default.csl", package = "docdesigner")
  if (!nzchar(csl)) {
    file.path(getwd(), "inst", "csl", "default.csl")
  } else {
    csl
  }
}
