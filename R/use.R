#' Start a docdesigner document
#'
#' Creates a small starter R Markdown file. Package defaults already know where
#' the bundled template, fonts, and CSL live, so project-local copies are only
#' needed for users who want to edit those assets.
#'
#' @param path Destination directory. Defaults to current working directory.
#' @param template One of `"pdf"`, `"html"`, or `"snapshot"`.
#' @param file Optional output filename. Defaults to `<template>.Rmd`.
#' @param overwrite If `TRUE`, replace an existing starter file.
#' @param local_assets If `TRUE`, also copy the template, fonts, and CSL file
#'   into the destination directory for local editing.
#' @return Invisibly returns the starter path.
#' @export
designer_use <- function(path = ".",
                         template = c("pdf", "html", "snapshot"),
                         file = NULL,
                         overwrite = FALSE,
                         local_assets = FALSE) {
  template <- match.arg(template)
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  dir.create(path, recursive = TRUE, showWarnings = FALSE)

  starter_src <- system.file("rmarkdown", "templates", template,
                             "skeleton", "skeleton.Rmd",
                             package = "docdesigner")
  if (!nzchar(starter_src)) {
    starter_src <- file.path("inst", "rmarkdown", "templates", template,
                             "skeleton", "skeleton.Rmd")
  }
  if (!file.exists(starter_src)) {
    stop("Could not find the docdesigner starter template: ", template,
         call. = FALSE)
  }

  file <- file %||% paste0(template, ".Rmd")
  starter_dst <- file.path(path, file)
  if (file.exists(starter_dst) && !isTRUE(overwrite)) {
    stop("Starter already exists: ", starter_dst,
         "\nUse overwrite = TRUE to replace it.", call. = FALSE)
  }
  file.copy(starter_src, starter_dst, overwrite = TRUE)

  message("Created: ", starter_dst)

  if (isTRUE(local_assets)) {
    copy_local_assets(path, overwrite = overwrite)
  }

  message("")
  message("Next step:")
  message("  Open ", starter_dst, " and knit it.")
  message("")
  message("Minimal output choices:")
  message("  docdesigner::pdf       # designed PDF")
  message("  docdesigner::html      # plain web HTML")
  message("  docdesigner::snapshot  # official Snapshot PDF + optional HTML")
  message("")
  message("Styles are optional for PDFs. See docdesigner::designer_styles().")

  invisible(starter_dst)
}

#' Update local docdesigner assets
#'
#' Refreshes editable local copies of the LaTeX template, fonts, CSL file, and
#' style manifests. Most projects do not need local assets; use this only when a
#' project deliberately keeps editable or frozen copies.
#'
#' @param path Destination directory.
#' @param source `"installed"` copies assets from the installed package;
#'   `"github"` downloads assets from the repository.
#' @param branch GitHub branch or tag when `source = "github"`.
#' @param overwrite Whether to replace existing local files.
#' @return Invisibly returns `path`.
#' @export
designer_update_templates <- function(path = ".",
                                      source = c("installed", "github"),
                                      branch = "main",
                                      overwrite = TRUE) {
  source <- match.arg(source)
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  dir.create(path, recursive = TRUE, showWarnings = FALSE)

  if (identical(source, "installed")) {
    copy_local_assets(path, overwrite = overwrite)
  } else {
    download_github_assets(path, branch = branch, overwrite = overwrite)
  }

  message("")
  message("Updated local docdesigner assets in: ", path)
  message("")
  message("Most documents can keep short YAML and use bundled package assets.")
  message("If this project deliberately uses local assets, add or keep:")
  message("  template: docdesignertemplate.tex")
  message("  csl: default.csl")
  message("  fontpath: fonts/")

  invisible(path)
}

copy_local_assets <- function(path, overwrite = FALSE) {
  template_src <- dd_template()
  fonts_src <- dd_fonts_dir()
  csl_src <- dd_csl()
  sets_src <- dd_pkg_file("sets")

  copy_one <- function(src, dst) {
    if (!nzchar(src) || !file.exists(src)) {
      warning("Missing source asset: ", src, call. = FALSE)
      return(invisible(FALSE))
    }
    if (dir.exists(src)) {
      dir.create(dst, recursive = TRUE, showWarnings = FALSE)
      entries <- list.files(src, all.files = TRUE, no.. = TRUE,
                            full.names = TRUE)
      ok <- all(file.copy(entries, dst, overwrite = overwrite,
                          recursive = TRUE))
      if (isTRUE(ok)) {
        message("Copied:  ", dst)
      } else {
        warning("Could not copy all assets to: ", dst, call. = FALSE)
      }
      return(invisible(ok))
    }
    if (!file.exists(dst) || overwrite) {
      ok <- file.copy(src, dst, overwrite = overwrite, recursive = dir.exists(src))
      if (isTRUE(ok)) {
        message("Copied:  ", dst)
      } else {
        warning("Could not copy asset to: ", dst, call. = FALSE)
      }
    } else {
      message("Skipped: ", dst, "  (use overwrite = TRUE to replace)")
    }
  }

  copy_one(template_src, file.path(path, "docdesignertemplate.tex"))
  copy_one(fonts_src, file.path(path, "fonts"))
  copy_one(csl_src, file.path(path, "default.csl"))
  copy_one(sets_src, file.path(path, "sets"))

  invisible(path)
}

download_github_assets <- function(path, branch = "main", overwrite = TRUE) {
  base <- paste0("https://raw.githubusercontent.com/jncohen/docdesigner/",
                 branch, "/")
  download_one <- function(remote, local) {
    if (file.exists(local) && !isTRUE(overwrite)) {
      message("Skipped: ", local, "  (use overwrite = TRUE to replace)")
      return(invisible(FALSE))
    }
    dir.create(dirname(local), recursive = TRUE, showWarnings = FALSE)
    url <- paste0(base, remote)
    message("Fetching: ", remote)
    utils::download.file(url, local, quiet = TRUE, mode = "wb")
    invisible(TRUE)
  }

  download_one("inst/templates/docdesignertemplate.tex",
               file.path(path, "docdesignertemplate.tex"))
  download_one("inst/csl/default.csl", file.path(path, "default.csl"))
  download_one("inst/engine/defaults.yml",
               file.path(path, "engine", "defaults.yml"))

  for (font in dd_asset_files("inst/fonts")) {
    download_one(file.path("inst/fonts", font), file.path(path, "fonts", font))
  }

  styles <- designer_styles()
  for (set in unique(styles$set)) {
    download_one(file.path("inst/sets", set, "set.yml"),
                 file.path(path, "sets", set, "set.yml"))
  }
  for (i in seq_len(nrow(styles))) {
    rel <- file.path("inst/sets", styles$set[i], "styles",
                     styles$style[i], "format.yml")
    download_one(rel, file.path(path, sub("^inst/", "", rel)))
  }

  invisible(path)
}

dd_asset_files <- function(dir) {
  path <- file.path(getwd(), dir)
  if (dir.exists(path)) {
    return(basename(list.files(path, full.names = TRUE)))
  }

  installed <- system.file(sub("^inst/", "", dir), package = "docdesigner")
  if (dir.exists(installed)) {
    return(basename(list.files(installed, full.names = TRUE)))
  }

  character()
}
