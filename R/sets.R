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
#' @return The new style directory, invisibly.
#' @export
designer_new_style <- function(id, from = "minimal", path = ".") {
  if (!requireNamespace("yaml", quietly = TRUE)) stop("The 'yaml' package is required.", call. = FALSE)
  src_dir <- dd_style_dir(from)
  if (is.null(src_dir)) {
    stop("Unknown docdesigner style: ", from,
         "\nAvailable: ", paste(designer_styles()$style, collapse = ", "), call. = FALSE)
  }
  # Seed from the source style's *declared* tokens, not dd_resolve_style()'s
  # fully merged output. Copying the resolved spec would bake today's engine
  # defaults into the new style, freezing it against future engine changes --
  # the opposite of what the docstring below promises.
  spec <- yaml::read_yaml(file.path(src_dir, "format.yml"))
  spec$id <- id; spec$label <- id
  dest <- file.path(normalizePath(path, mustWork = FALSE), id)
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)
  out <- file.path(dest, "format.yml")
  header <- c(paste0("# docdesigner style '", id, "' (seeded from '", from, "')."),
              "# Edit tokens below; anything omitted falls back to engine defaults.",
              "# Run designer_style(\"<id>\") to see the fully resolved token set.", "")
  writeLines(c(header, yaml::as.yaml(spec)), out)
  message("Created new style at ", out)
  invisible(dest)
}
