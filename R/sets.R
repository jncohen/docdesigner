# docdesigner style sets: list / install / scaffold (Phase B)

#' User set library location
#' @keywords internal
dd_user_sets <- function() file.path(tools::R_user_dir("docdesigner", "data"), "sets")

#' List installed style sets
#'
#' Built-in sets ship with the package; user sets install under the user data
#' directory and survive package updates.
#' @return A data frame of sets with the library they live in (`core` or
#'   `user`), the upstream repo they were installed from, and a style count.
#' @export
designer_sets <- function() {
  rows <- list()
  roots <- c(core = dd_pkg_file("sets"), user = dd_user_sets())
  for (lib in names(roots)) {
    root <- roots[[lib]]
    if (!dir.exists(root)) next
    for (set in list.dirs(root, recursive = FALSE)) {
      man <- file.path(set, "set.yml")
      if (!file.exists(man)) next
      y <- yaml::read_yaml(man)
      n <- length(list.dirs(file.path(set, "styles"), recursive = FALSE))
      rows[[length(rows) + 1]] <- data.frame(
        set = y$id %||% basename(set), title = y$title %||% basename(set),
        version = as.character(y$version %||% ""), library = lib,
        source = as.character(y$source %||% ""), styles = n,
        stringsAsFactors = FALSE)
    }
  }
  if (!length(rows)) return(data.frame())
  do.call(rbind, rows)
}

#' Install a style set from GitHub
#'
#' @param repo A GitHub `owner/name` slug or a full clone URL.
#' @param ref Branch or tag to install.
#' @param overwrite Replace an existing set of the same id.
#' @return The install path, invisibly.
#' @export
designer_install_set <- function(repo, ref = "main", overwrite = FALSE) {
  if (!requireNamespace("yaml", quietly = TRUE)) stop("The 'yaml' package is required.", call. = FALSE)
  url <- if (grepl("^https?://|\\.git$", repo)) repo else paste0("https://github.com/", repo, ".git")
  dest_root <- dd_user_sets()
  dir.create(dest_root, recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile("ddset")
  if (Sys.which("git") == "") stop("git is required to install sets.", call. = FALSE)
  status <- system2("git", c("clone", "--depth", "1", "--branch", ref, shQuote(url), shQuote(tmp)),
                    stdout = FALSE, stderr = FALSE)
  if (status != 0 || !file.exists(file.path(tmp, "set.yml")))
    stop("Could not install a valid style set from: ", url, call. = FALSE)
  manifest <- yaml::read_yaml(file.path(tmp, "set.yml"))
  id <- manifest$id %||% basename(tmp)

  fv <- as.integer(manifest$format_version %||% 1L)
  if (is.na(fv) || fv > DD_FORMAT_VERSION) {
    stop("Set '", id, "' declares format_version ", manifest$format_version,
         " but this engine supports ", DD_FORMAT_VERSION,
         ". Upgrade docdesigner before installing it.", call. = FALSE)
  }

  dest <- file.path(dest_root, id)
  if (dir.exists(dest) && !isTRUE(overwrite))
    stop("Set already installed: ", id, " (use overwrite = TRUE).", call. = FALSE)
  unlink(dest, recursive = TRUE)
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)
  file.copy(list.files(tmp, full.names = TRUE, all.files = TRUE, no.. = TRUE), dest, recursive = TRUE)
  unlink(file.path(dest, ".git"), recursive = TRUE)

  # Record where the set came from. Without this, designer_update_sets() has
  # nothing to pull from and silently skips every set it is asked to update.
  manifest$source <- repo
  manifest$ref <- ref
  manifest$installed <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
  yaml::write_yaml(manifest, file.path(dest, "set.yml"))

  message("Installed set '", id, "' to ", dest)
  invisible(dest)
}

#' Update installed style sets
#'
#' @param set Optional set id; defaults to all user sets that record a source.
#' @return Invisibly `NULL`.
#' @export
designer_update_sets <- function(set = NULL) {
  sets <- designer_sets()
  if (!nrow(sets)) { message("No user sets to update."); return(invisible()) }
  sets <- sets[sets$library == "user", , drop = FALSE]
  if (!is.null(set)) sets <- sets[sets$set %in% set, , drop = FALSE]
  if (!nrow(sets)) { message("No user sets to update."); return(invisible()) }
  for (id in sets$set) {
    man <- yaml::read_yaml(file.path(dd_user_sets(), id, "set.yml"))
    src <- man$source
    if (is.null(src) || !nzchar(src)) {
      message("No recorded source for '", id, "'; skipping. ",
              "Sets installed before docdesigner 1.0.2 did not record one; ",
              "reinstall it with designer_install_set().")
      next
    }
    designer_install_set(src, ref = man$ref %||% "main", overwrite = TRUE)
  }
  invisible()
}

#' Scaffold a new style
#'
#' Writes a commented `format.yml` starter, seeded from an existing style so you
#' change only what differs.
#' @param id New style id.
#' @param from Existing style to copy tokens from.
#' @param path Destination directory (a style bundle folder is created inside).
#' @param complete If `TRUE` (default), scaffold every token in the schema, one
#'   flat dotted key per line, as an editable reference. If `FALSE`, seed only
#'   the tokens the source style actually declares.
#' @return The new style directory, invisibly.
#' @export
designer_new_style <- function(id, from = "minimal", path = ".", complete = TRUE) {
  if (!requireNamespace("yaml", quietly = TRUE)) stop("The 'yaml' package is required.", call. = FALSE)
  src_dir <- dd_style_dir(from)
  if (is.null(src_dir)) {
    stop("Unknown docdesigner style: ", from,
         "\nAvailable: ", paste(designer_styles()$style, collapse = ", "), call. = FALSE)
  }
  declared <- yaml::read_yaml(file.path(src_dir, "format.yml"))
  dest <- file.path(normalizePath(path, mustWork = FALSE), id)
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)
  out <- file.path(dest, "format.yml")

  lines <- if (isTRUE(complete)) {
    dd_scaffold_complete(id, from, declared)
  } else {
    # Seed from the source style's *declared* tokens, never dd_resolve_style()'s
    # merged output: copying the resolved spec bakes today's engine defaults
    # into the new style and freezes it against future engine changes.
    declared$id <- id; declared$label <- id
    c(paste0("# docdesigner style '", id, "' (seeded from '", from, "')."),
      "# Flat keys only. Omitted tokens fall back to engine defaults.", "",
      vapply(names(declared), function(k) dd_yaml_line(k, declared[[k]]), character(1)))
  }

  writeLines(lines, out)
  message("Created new style at ", out)
  if (isTRUE(complete)) {
    message("Every token is written at its default. Edit values in place; do not add keys.")
  }
  invisible(dest)
}

# Render one `key: value` line, quoting where YAML would otherwise coerce.
dd_yaml_line <- function(key, value) {
  v <- if (is.logical(value)) {
    if (isTRUE(value)) "true" else "false"
  } else if (is.numeric(value)) {
    format(value, trim = TRUE)
  } else if (is.null(value)) {
    "null"
  } else if (length(value) > 1L) {
    paste0("[", paste(value, collapse = ", "), "]")
  } else if (value %in% c("true", "false")) {
    value                      # a schema default that is already a bool literal
  } else if (grepl("^[0-9]|[:#]| $|^ ", value) || grepl("^[0-9A-Fa-f]{6}$", value)) {
    paste0("\"", value, "\"")  # hex colours and pt sizes must stay strings
  } else {
    value
  }
  paste0(key, ": ", v)
}

# The complete scaffold: every token, at its default, with the legal values in
# a trailing comment. A model editing this file can only change a value -- it
# never has to invent a key, and it never touches indentation.
dd_scaffold_complete <- function(id, from, declared) {
  tok <- designer_tokens()
  seeded <- dd_resolve_style(from)
  flat <- dd_flatten_dotted(seeded)

  out <- c(
    paste0("# docdesigner style '", id, "' -- complete token scaffold."),
    paste0("# Seeded from '", from, "'. format_version 2."),
    "#",
    "# FLAT KEYS ONLY. Every line is `dotted.key: value` at column zero.",
    "# There is no nesting. Edit values in place; do not add or remove keys.",
    "# Delete a line to accept the engine default.",
    "#",
    "# Run designer_validate_style() before rendering.",
    "# Tokens marked NOT-YET-IMPLEMENTED validate but are currently ignored.",
    "")

  # Identity first, written explicitly. `inherits` is deliberately omitted:
  # a complete scaffold has nothing to inherit, and it is the one token that
  # forces a reader (human or model) to reason about tokens it cannot see.
  out <- c(out,
           paste0("# ---- identity ", strrep("-", 48)),
           dd_yaml_line("id", id),
           dd_yaml_line("label", id),
           dd_yaml_line("description", paste0("Derived from ", from, ".")),
           "")

  skip <- c("id", "label", "description", "inherits")
  tok <- tok[!tok$key %in% skip, , drop = FALSE]

  group_of <- function(k) sub("\\..*$", "", k)
  for (g in unique(group_of(tok$key))) {
    rows <- tok[group_of(tok$key) == g, , drop = FALSE]
    body <- character()
    for (i in seq_len(nrow(rows))) {
      k <- rows$key[i]
      value <- flat[[k]]
      if (is.null(value)) {
        if (is.na(rows$default[i])) next   # no default, unset: omit, don't guess
        value <- rows$default[i]
      }
      note <- rows$allowed[i]
      if (rows$status[i] %in% c("new", "port")) {
        note <- paste0(note, "   <- NOT YET IMPLEMENTED, IGNORED")
      } else if (identical(rows$status[i], "risk")) {
        note <- paste0(note, "   <- FRAGILE")
      }
      line <- dd_yaml_line(k, value)
      body <- c(body, if (nzchar(note)) paste0(line, "  # ", note) else line)
    }
    if (!length(body)) next
    out <- c(out, paste0("# ---- ", g, " ", strrep("-", max(1, 58 - nchar(g)))),
             body, "")
  }
  out
}
