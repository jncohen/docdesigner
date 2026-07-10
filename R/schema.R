# Schema loading, dotted-key expansion, and style validation.
#
# inst/engine/schema.yml is the single source of truth for the token
# vocabulary. The validator reads it; designer_new_style() scaffolds from it;
# designer_ai_brief() generates its reference from it. Nothing about the token
# vocabulary is written down anywhere else.
#
# Style files are FLAT: every line is `dotted.key: value`, at column zero.
# There is no nesting, so there is no indentation to get wrong. The engine
# expands dotted keys into the nested list that dd_preamble() consumes.

dd_schema <- function() {
  if (is.null(dd_cache$schema)) {
    dd_cache$schema <- yaml::read_yaml(dd_pkg_file("engine", "schema.yml"))
  }
  dd_cache$schema
}
dd_cache <- new.env(parent = emptyenv())

# Expand `headings.<h>.scale` across the declared heading levels.
dd_token_table <- function() {
  s <- dd_schema()
  out <- list()
  for (key in names(s$tokens)) {
    spec <- s$tokens[[key]]
    if (grepl("<h>", key, fixed = TRUE)) {
      for (lvl in s$heading_levels) {
        out[[sub("<h>", lvl, key, fixed = TRUE)]] <- spec
      }
    } else {
      out[[key]] <- spec
    }
  }
  out
}

# Resolve a named step on a scale, e.g. dd_len("space", "lg") -> "1.75em".
dd_len <- function(scale, key, default = NULL) {
  if (is.null(key)) key <- default
  if (is.null(key)) return(NULL)
  tbl <- dd_schema()$scales[[scale]]
  if (is.null(tbl[[as.character(key)]])) {
    stop("'", key, "' is not a step on the '", scale, "' scale. Valid: ",
         paste(names(tbl), collapse = ", "), call. = FALSE)
  }
  tbl[[as.character(key)]]
}

# ---- dotted-key expansion --------------------------------------------------
dd_assign_path <- function(l, path, value) {
  if (length(path) == 1L) {
    l[path] <- list(value)   # `l[[k]] <- NULL` would delete; this assigns
    return(l)
  }
  head <- path[[1]]
  if (!is.list(l[[head]])) l[[head]] <- list()
  l[[head]] <- dd_assign_path(l[[head]], path[-1], value)
  l
}

#' Expand a flat dotted-key style file into a nested token list
#' @keywords internal
dd_expand_dotted <- function(x) {
  out <- list()
  for (k in names(x)) {
    v <- x[[k]]
    if (is.null(v)) next            # an explicit null means "unset"
    out <- dd_assign_path(out, strsplit(k, ".", fixed = TRUE)[[1]], v)
  }
  out
}

# Collapse a nested list back to dotted keys. Used by the scaffolder and brief.
dd_flatten_dotted <- function(x, prefix = "") {
  out <- list()
  for (k in names(x)) {
    key <- if (nzchar(prefix)) paste0(prefix, ".", k) else k
    v <- x[[k]]
    if (is.list(v) && !is.null(names(v))) {
      out <- c(out, dd_flatten_dotted(v, key))
    } else {
      out[[key]] <- v
    }
  }
  out
}

# ---- validation ------------------------------------------------------------
dd_is_hex <- function(x) is.character(x) && grepl("^#?[0-9A-Fa-f]{6}$", x)

dd_check_value <- function(key, value, spec, schema, known_fonts) {
  bad <- function(msg) list(key = key, severity = "error", message = msg)
  type <- spec$type

  if (is.null(value)) {
    if (isTRUE(spec$nullable)) return(NULL)
    return(bad("is null, but this token is not nullable"))
  }

  if (grepl("^scale:", type)) {
    sc <- sub("^scale:", "", type)
    steps <- names(schema$scales[[sc]])
    if (!as.character(value) %in% steps) {
      return(bad(paste0("must be one of: ", paste(steps, collapse = ", "),
                        " (got '", value, "')")))
    }
    return(NULL)
  }

  switch(type,
    enum = if (!as.character(value) %in% as.character(spec$values))
      bad(paste0("must be one of: ", paste(spec$values, collapse = ", "),
                 " (got '", value, "')")),
    role = if (!as.character(value) %in% schema$roles)
      bad(paste0("must name a colour role: ", paste(schema$roles, collapse = ", "),
                 " (got '", value, "'). Hex values belong under color.*")),
    hex = if (!dd_is_hex(value))
      bad(paste0("must be a 6-digit hex colour (got '", value, "')")),
    bool = if (!is.logical(value) || length(value) != 1L)
      bad("must be true or false"),
    int = {
      if (!is.numeric(value) || value != round(value)) bad("must be a whole number")
      else if (!is.null(spec$values) && !value %in% spec$values)
        bad(paste0("must be one of: ", paste(spec$values, collapse = ", ")))
      else if (!is.null(spec$min) && (value < spec$min || value > spec$max))
        bad(paste0("must be between ", spec$min, " and ", spec$max))
      else NULL
    },
    num = if (!is.numeric(value)) bad("must be a number")
      else if (!is.null(spec$min) && (value < spec$min || value > spec$max))
        bad(paste0("must be between ", spec$min, " and ", spec$max))
      else NULL,
    inches = if (!is.numeric(value)) bad("must be a number of inches")
      else if (value < spec$min || value > spec$max)
        bad(paste0("must be between ", spec$min, " and ", spec$max, " inches"))
      else NULL,
    font = if (!as.character(value) %in% known_fonts)
      bad(paste0("names an unknown font family '", value,
                 "'. Bundled: ", paste(schema$bundled_fonts, collapse = ", "),
                 ". Declare others under fonts.<Family>.regular"))
      else NULL,
    list = {
      extra <- setdiff(as.character(value), as.character(spec$values))
      if (length(extra)) bad(paste0("contains unknown entries: ",
                                    paste(extra, collapse = ", ")))
      else NULL
    },
    id = if (!is.character(value) || !grepl("^[a-z0-9][a-z0-9-]*$", value))
      bad("must be lowercase letters, digits, and hyphens")
      else NULL,
    string = if (!is.character(value)) bad("must be text") else NULL,
    NULL)
}

#' Validate a style file against the schema
#'
#' Reads a flat dotted-key `format.yml` and reports unknown keys, bad values,
#' and tokens the current engine does not yet implement. Cross-token rules
#' (declared in `schema.yml` under `rules:`) are reported as warnings.
#'
#' @param style A style id, a style directory, or a path to a `format.yml`.
#' @return A data frame of issues, invisibly. Printed as a report.
#' @export
designer_validate_style <- function(style) {
  schema <- dd_schema()
  path <- if (file.exists(style) && !dir.exists(style)) style else {
    d <- dd_style_dir(style)
    if (is.null(d)) stop("Unknown style or path: ", style, call. = FALSE)
    file.path(d, "format.yml")
  }
  raw <- yaml::read_yaml(path)
  tokens <- dd_token_table()

  # Font families this style may reference: bundled + any it declares.
  declared <- unique(vapply(
    grep("^fonts\\.", names(raw), value = TRUE),
    function(k) strsplit(k, ".", fixed = TRUE)[[1]][[2]], character(1)))
  known_fonts <- c(schema$bundled_fonts, declared)

  issues <- list()
  add <- function(...) issues[[length(issues) + 1]] <<- list(...)

  for (k in names(raw)) {
    if (grepl("^fonts\\.", k)) next            # validated by the engine on load
    if (grepl("\\.", k) == FALSE && k %in% c("id", "label", "description", "inherits")) {
      # identity keys fall through to the token table below
    }
    spec <- tokens[[k]]
    if (is.null(spec)) {
      add(key = k, severity = "error",
          message = "unknown token. Every key must appear in schema.yml")
      next
    }
    issue <- dd_check_value(k, raw[[k]], spec, schema, known_fonts)
    if (!is.null(issue)) add(key = issue$key, severity = issue$severity,
                             message = issue$message)
    if (spec$status %in% c("new", "port")) {
      add(key = k, severity = "info",
          message = paste0("declared but not yet implemented (status: ",
                           spec$status, "); it will be ignored"))
    }
    if (identical(spec$status, "risk")) {
      add(key = k, severity = "warning",
          message = "fragile token; verify the rendered output")
    }
  }

  for (req in c("id", "label")) {
    if (is.null(raw[[req]])) {
      add(key = req, severity = "error", message = "is required")
    }
  }

  # Cross-token rules. Declared in schema.yml for documentation; enforced here.
  g <- function(k, default = NULL) raw[[k]] %||% default
  none <- function(x) is.null(x) || identical(as.character(x), "none")

  if (!none(g("paragraph.indent")) && !none(g("paragraph.spacing"))) {
    add(key = "paragraph.indent", severity = "warning",
        message = "set together with paragraph.spacing; separate paragraphs by indent OR by space, not both")
  }
  if (!is.null(g("paragraph.drop_cap.lines")) && identical(g("page.columns"), 2L)) {
    add(key = "paragraph.drop_cap.lines", severity = "warning",
        message = "drop caps are unreliable in a two-column body")
  }
  if (isTRUE(g("figure.span_columns")) && !identical(g("page.columns"), 2L)) {
    add(key = "figure.span_columns", severity = "warning",
        message = "has no effect in a single-column body")
  }
  if (any(grepl("^page\\.margins\\.", names(raw))) && !is.null(g("page.margin"))) {
    add(key = "page.margin", severity = "warning",
        message = "is overridden by page.margins.*; setting both is redundant")
  }
  for (lvl in schema$heading_levels) {
    if (!is.null(g(paste0("headings.", lvl, ".bar.fill"))) &&
        !none(g(paste0("headings.", lvl, ".rule.position")))) {
      add(key = paste0("headings.", lvl, ".bar.fill"), severity = "warning",
          message = "a filled bar plus a rule on the same level reads as an error")
    }
  }

  res <- if (length(issues)) {
    do.call(rbind, lapply(issues, function(i)
      data.frame(key = i$key, severity = i$severity, message = i$message,
                 stringsAsFactors = FALSE)))
  } else {
    data.frame(key = character(), severity = character(), message = character(),
               stringsAsFactors = FALSE)
  }
  attr(res, "path") <- path
  class(res) <- c("docdesigner_validation", class(res))
  print(res)
  invisible(res)
}

#' @param x A `docdesigner_validation` object from `designer_validate_style()`.
#' @param verbose List every not-yet-implemented token instead of summarising.
#' @param ... Unused; present for S3 `print` compatibility.
#' @rdname designer_validate_style
#' @export
print.docdesigner_validation <- function(x, verbose = FALSE, ...) {
  cat("docdesigner style validation\n", attr(x, "path"), "\n\n", sep = "")
  if (!nrow(x)) {
    cat("No issues.\n")
    return(invisible(x))
  }
  # Errors and warnings are per-token and actionable. `info` is a bulk
  # statement about the engine's maturity, not about this style -- a complete
  # scaffold generates ~90 of them. Summarise unless asked.
  for (sev in c("error", "warning")) {
    rows <- x[x$severity == sev, , drop = FALSE]
    if (!nrow(rows)) next
    for (i in seq_len(nrow(rows))) {
      cat(sprintf("%-8s %-34s %s\n", toupper(sev), rows$key[i], rows$message[i]))
    }
  }
  info <- x[x$severity == "info", , drop = FALSE]
  if (nrow(info)) {
    if (isTRUE(verbose)) {
      for (i in seq_len(nrow(info))) {
        cat(sprintf("%-8s %-34s %s\n", "INFO", info$key[i], info$message[i]))
      }
    } else {
      cat("\nNot yet implemented (declared, validated, currently ignored):\n")
      keys <- info$key
      cat(strwrap(paste(keys, collapse = ", "), width = 78, prefix = "  "), sep = "\n")
      cat("  (print(x, verbose = TRUE) for detail)\n")
    }
  }
  n <- table(factor(x$severity, levels = c("error", "warning", "info")))
  cat(sprintf("\n%d errors, %d warnings, %d not-yet-implemented\n",
              n[["error"]], n[["warning"]], n[["info"]]))
  invisible(x)
}

#' The token vocabulary as a data frame
#'
#' @return One row per token: key, type, allowed values, default, status.
#' @export
designer_tokens <- function() {
  schema <- dd_schema()
  tokens <- dd_token_table()
  rows <- lapply(names(tokens), function(k) {
    s <- tokens[[k]]
    allowed <- if (grepl("^scale:", s$type)) {
      paste(names(schema$scales[[sub("^scale:", "", s$type)]]), collapse = " | ")
    } else if (!is.null(s$values)) {
      paste(s$values, collapse = " | ")
    } else if (identical(s$type, "role")) {
      paste(schema$roles, collapse = " | ")
    } else if (!is.null(s$min)) {
      paste0(s$min, " to ", s$max)
    } else if (identical(s$type, "hex")) {
      "6-digit hex"
    } else if (identical(s$type, "bool")) {
      "true | false"
    } else ""
    data.frame(key = k, type = s$type, allowed = allowed,
               default = if (is.null(s$default)) NA_character_ else as.character(s$default),
               status = s$status,
               doc = if (is.null(s$doc)) "" else s$doc,
               stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}
