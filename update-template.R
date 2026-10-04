# =============================================================================
# update-template.R
#
# NOTE: If you installed docdesigner as a package, the preferred update path is:
#   docdesigner::designer_update_templates()
#
# The docdesigner_update() function below is for non-package/manual installs only.
#
# R equivalent of fetch-template.sh. Downloads the latest docdesignertemplate.tex,
# default.csl, style manifests, and all font files from GitHub.
#
# Usage (from R or RStudio):
#   source("update-template.R")
#   docdesigner_update()                          # update ~/Templates/docdesigner/
#   docdesigner_update(dest = "path/to/dir")      # custom destination
#   docdesigner_update(branch = "v1.0.0")         # pin to a specific tag/release
#
# Add docdesigner_update() to .Rprofile for automatic updates:
#   cat('source("~/Templates/docdesigner/update-template.R")\n',
#       file = "~/.Rprofile", append = TRUE)
# =============================================================================

docdesigner_update <- function(
  dest   = file.path(Sys.getenv("docdesigner_template_DIR",
                                unset = file.path("~", "Templates", "docdesigner"))),
  branch = Sys.getenv("docdesigner_BRANCH", unset = "main")
) {
  dest   <- normalizePath(dest, mustWork = FALSE)
  base   <- paste0("https://raw.githubusercontent.com/jncohen/docdesigner/",
                   branch)

  dir.create(file.path(dest, "fonts"), recursive = TRUE, showWarnings = FALSE)

  fetch <- function(path, local_name = basename(path)) {
    url   <- paste0(base, "/", path)
    local <- file.path(dest, local_name)
    message("  ", basename(url), " -> ", local)
    tryCatch(
      download.file(url, local, quiet = TRUE, mode = "wb"),
      error = function(e) warning("Failed to download ", url, ": ", conditionMessage(e))
    )
  }

  message("Fetching docdesigner (", branch, ") to: ", dest)

  # Core files
  fetch("inst/templates/docdesignertemplate.tex", "docdesignertemplate.tex")
  fetch("inst/csl/default.csl",           "default.csl")

  # Style manifests
  message("Fetching styles...")
  for (s in c("atlantic", "demography", "economist", "government", "humanities",
              "methods", "minimal", "nature", "policy", "ssrn")) {
    fetch(paste0("inst/styles/", s, "/style.yml"),
          file.path("styles", s, "style.yml"))
  }

  # EB Garamond (humanities preset)
  message("Fetching EB Garamond fonts...")
  for (f in c("EBGaramond-Regular.otf", "EBGaramond-Bold.otf",
               "EBGaramond-Italic.otf", "EBGaramond-BoldItalic.otf")) {
    fetch(paste0("inst/fonts/", f), file.path("fonts", f))
  }

  # XITS (demography preset)
  message("Fetching XITS fonts...")
  for (f in c("XITS-Regular.otf", "XITS-Bold.otf",
               "XITS-Italic.otf", "XITS-BoldItalic.otf")) {
    fetch(paste0("inst/fonts/", f), file.path("fonts", f))
  }

  # Source Serif 4 (methods preset, body)
  message("Fetching Source Serif 4 fonts...")
  for (f in c("SourceSerif4-Regular.otf", "SourceSerif4-Bold.otf",
               "SourceSerif4-It.otf", "SourceSerif4-BoldIt.otf")) {
    fetch(paste0("inst/fonts/", f), file.path("fonts", f))
  }

  # Fira Code (methods preset, monospace)
  message("Fetching Fira Code fonts...")
  for (f in c("FiraCode-Regular.ttf", "FiraCode-Bold.ttf")) {
    fetch(paste0("inst/fonts/", f), file.path("fonts", f))
  }

  message("\nUpdate complete. Add to your document YAML:")
  message("  template: ", file.path(dest, "docdesignertemplate.tex"))
  message("  csl: ",      file.path(dest, "default.csl"))
  message("  fontpath: ", file.path(dest, "fonts"), "/")
  invisible(dest)
}
