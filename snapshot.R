#' Render a Snapshot PDF and WordPress companion file
#'
#' Use this as an R Markdown output format for public-facing Lab Snapshots.
#' It renders the PDF with the bundled LaTeX template and, after knitting,
#' converts the knitted markdown to a WordPress-ready companion file.
#'
#' Add to YAML:
#' ```yaml
#' snapshot: true
#' output:
#'   docdesigner::snapshot_pdf:
#'     wordpress: html
#' ```
#'
#' @param ... Arguments passed to [rmarkdown::pdf_document()].
#' @param template LaTeX template path. Defaults to `docdesignertemplate.tex`.
#' @param latex_engine LaTeX engine for the PDF. Defaults to `xelatex`.
#' @param wordpress Companion output type: `"html"`, `"markdown"`, or `"none"`.
#' @param wordpress_file Optional companion output filename. When `NULL`,
#'   uses the PDF filename with `-wordpress.html` or `-wordpress.md`.
#' @param wordpress_assets If `TRUE`, copy local images referenced by the
#'   companion file into a sibling `-wordpress-assets/` directory and rewrite
#'   image paths to point there.
#' @param wordpress_checklist If `TRUE`, write a short manual publishing
#'   checklist for RStudio-to-WordPress handoff.
#' @return An R Markdown output format.
#' @export
snapshot_pdf <- function(...,
                         style = "policy",
                         template = "docdesignertemplate.tex",
                         latex_engine = "xelatex",
                         wordpress = c("html", "markdown", "none"),
                         wordpress_file = NULL,
                         wordpress_assets = TRUE,
                         wordpress_checklist = TRUE) {
  wordpress <- match.arg(wordpress)
  spec <- dd_style(style)

  companion_pdf_document(
    ...,
    template = template,
    latex_engine = latex_engine,
    style = style,
    document_type = "snapshot",
    style_spec = spec,
    companion = wordpress,
    companion_file = wordpress_file,
    companion_assets = wordpress_assets,
    companion_checklist = wordpress_checklist
  )
}

#' Render a Blogpost PDF and WordPress companion file
#'
#' Use this output format for public-facing Lab posts that should use the
#' compact blog PDF styling while also producing a WordPress-ready
#' companion file.
#'
#' Add to YAML:
#' ```yaml
#' output:
#'   docdesigner::blogpost_pdf:
#'     wordpress: html
#' ```
#'
#' @param ... Arguments passed to [rmarkdown::pdf_document()].
#' @param template LaTeX template path. Defaults to `docdesignertemplate.tex`.
#' @param latex_engine LaTeX engine for the PDF. Defaults to `xelatex`.
#' @param wordpress Companion output type: `"html"`, `"markdown"`, or `"none"`.
#' @param wordpress_file Optional companion output filename. When `NULL`,
#'   uses the PDF filename with `-wordpress.html` or `-wordpress.md`.
#' @param wordpress_assets If `TRUE`, copy local images referenced by the
#'   companion file into a sibling `-wordpress-assets/` directory and rewrite
#'   image paths to point there.
#' @param wordpress_checklist If `TRUE`, write a short manual publishing
#'   checklist for RStudio-to-WordPress handoff.
#' @return An R Markdown output format.
#' @export
blogpost_pdf <- function(...,
                         style = "policy",
                         template = "docdesignertemplate.tex",
                         latex_engine = "xelatex",
                         wordpress = c("html", "markdown", "none"),
                         wordpress_file = NULL,
                         wordpress_assets = TRUE,
                         wordpress_checklist = TRUE) {
  wordpress <- match.arg(wordpress)
  spec <- dd_style(style)

  companion_pdf_document(
    ...,
    template = template,
    latex_engine = latex_engine,
    style = style,
    document_type = "blogpost",
    style_spec = spec,
    companion = wordpress,
    companion_file = wordpress_file,
    companion_assets = wordpress_assets,
    companion_checklist = wordpress_checklist
  )
}

companion_pdf_document <- function(...,
                                   template,
                                   latex_engine,
                                   style = NULL,
                                   document_type = NULL,
                                   style_spec = NULL,
                                   companion,
                                   companion_file = NULL,
                                   companion_assets = TRUE,
                                   companion_checklist = TRUE) {
  if (!requireNamespace("rmarkdown", quietly = TRUE)) {
    stop("The rmarkdown package is required for this output format.",
         call. = FALSE)
  }

  dots <- list(...)
  dots$template <- template
  dots$latex_engine <- latex_engine
  if (!is.null(document_type)) {
    dots$pandoc_args <- c(dots$pandoc_args %||% character(),
                          "--metadata",
                          paste0(document_type, "=true"))
  }
  if (!is.null(style) && !is.null(style_spec)) {
    dots$pandoc_args <- c(dots$pandoc_args %||% character(),
                          "--metadata", paste0("style=", style),
                          "--metadata", paste0("fontset=", style_spec$fontset),
                          "--metadata", paste0("accent=", style_spec$accent),
                          "--metadata",
                          paste0("maincolumns=", style_spec$maincolumns),
                          "--metadata",
                          paste0("numbersections=", style_spec$numbersections))
  }

  format <- do.call(rmarkdown::pdf_document, dots)

  previous_post_processor <- format$post_processor

  format$post_processor <- function(metadata, input_file, output_file, clean, verbose) {
    final_output <- output_file
    if (is.function(previous_post_processor)) {
      final_output <- previous_post_processor(
        metadata = metadata,
        input_file = input_file,
        output_file = output_file,
        clean = clean,
        verbose = verbose
      )
    }

    if (!identical(companion, "none")) {
      make_wordpress_companion_file(
        input_file = input_file,
        output_file = final_output,
        companion = companion,
        companion_file = companion_file,
        copy_assets = companion_assets,
        write_checklist = companion_checklist,
        metadata = metadata,
        verbose = verbose
      )
    }

    final_output
  }

  format
}

make_wordpress_companion_file <- function(input_file,
                                          output_file,
                                          companion,
                                          companion_file = NULL,
                                          copy_assets = TRUE,
                                          write_checklist = TRUE,
                                          metadata = list(),
                                          verbose = FALSE) {
  ext <- if (identical(companion, "html")) "html" else "md"
  if (is.null(companion_file)) {
    companion_file <- paste0(tools::file_path_sans_ext(output_file),
                             "-wordpress.", ext)
  }

  to <- if (identical(companion, "html")) "html5" else "gfm"
  options <- if (identical(companion, "html")) {
    c("--section-divs", "--wrap=none")
  } else {
    c("--wrap=none")
  }

  rmarkdown::pandoc_convert(
    input = input_file,
    to = to,
    output = companion_file,
    options = options,
    verbose = verbose
  )

  assets_dir <- NULL
  if (isTRUE(copy_assets)) {
    assets_dir <- copy_wordpress_assets(
      companion_file = companion_file,
      input_file = input_file,
      companion = companion
    )
  }

  if (isTRUE(write_checklist)) {
    write_wordpress_checklist(
      output_file = output_file,
      companion_file = companion_file,
      assets_dir = assets_dir,
      metadata = metadata
    )
  }

  if (verbose) {
    message("WordPress companion written to: ", companion_file)
    if (!is.null(assets_dir)) {
      message("WordPress assets written to: ", assets_dir)
    }
  }

  invisible(companion_file)
}

copy_wordpress_assets <- function(companion_file, input_file, companion) {
  if (!file.exists(companion_file)) {
    return(NULL)
  }

  text <- readLines(companion_file, warn = FALSE, encoding = "UTF-8")
  refs <- image_references(text, companion)
  refs <- refs[is_local_asset_ref(refs)]
  if (!length(refs)) {
    return(NULL)
  }

  companion_dir <- dirname(normalizePath(companion_file, winslash = "/",
                                         mustWork = FALSE))
  input_dir <- dirname(normalizePath(input_file, winslash = "/",
                                     mustWork = FALSE))
  assets_dir <- paste0(tools::file_path_sans_ext(companion_file),
                       "-assets")
  dir.create(assets_dir, recursive = TRUE, showWarnings = FALSE)

  copied <- character()
  replacements <- setNames(character(length(refs)), refs)
  for (ref in unique(refs)) {
    src <- resolve_asset_path(ref, c(companion_dir, input_dir, getwd()))
    if (is.na(src)) {
      next
    }

    src_ext <- tolower(tools::file_ext(src))
    if (identical(src_ext, "pdf")) {
      png_name <- paste0(tools::file_path_sans_ext(basename(src)), ".png")
      dest_name <- unique_asset_name(png_name, copied)
      dest <- file.path(assets_dir, dest_name)
      if (convert_pdf_asset_to_png(src, dest)) {
        copied <- c(copied, dest_name)
        replacements[[ref]] <- file.path(basename(assets_dir), dest_name)
      } else {
        warning("Could not convert PDF image asset to PNG for WordPress: ",
                src, call. = FALSE)
      }
      next
    }

    dest_name <- unique_asset_name(basename(src), copied)
    copied <- c(copied, dest_name)
    dest <- file.path(assets_dir, dest_name)
    src_norm <- normalizePath(src, winslash = "/", mustWork = FALSE)
    dest_norm <- normalizePath(dest, winslash = "/", mustWork = FALSE)
    replacements[[ref]] <- file.path(basename(assets_dir), dest_name)
    if (!identical(src_norm, dest_norm)) {
      file.copy(src, dest, overwrite = TRUE)
    }
  }

  replacements <- replacements[nzchar(replacements)]
  if (length(replacements)) {
    for (ref in names(replacements)) {
      text <- gsub(ref, replacements[[ref]], text, fixed = TRUE)
    }
    text <- normalize_wordpress_image_tags(text)
    writeLines(text, companion_file, useBytes = TRUE)
  }

  normalizePath(assets_dir, winslash = "/", mustWork = FALSE)
}

image_references <- function(text, companion) {
  html <- gregexpr("<img[^>]+src=[\"'][^\"']+[\"']", text,
                  ignore.case = TRUE, perl = TRUE)
  html_refs <- regmatches(text, html)
  html_refs <- unlist(html_refs, use.names = FALSE)
  html_refs <- sub("^.*src=[\"']([^\"']+)[\"'].*$", "\\1", html_refs,
                   perl = TRUE)

  embed <- gregexpr("<embed[^>]+src=[\"'][^\"']+[\"']", text,
                    ignore.case = TRUE, perl = TRUE)
  embed_refs <- regmatches(text, embed)
  embed_refs <- unlist(embed_refs, use.names = FALSE)
  embed_refs <- sub("^.*src=[\"']([^\"']+)[\"'].*$", "\\1", embed_refs,
                    perl = TRUE)

  object <- gregexpr("<object[^>]+data=[\"'][^\"']+[\"']", text,
                     ignore.case = TRUE, perl = TRUE)
  object_refs <- regmatches(text, object)
  object_refs <- unlist(object_refs, use.names = FALSE)
  object_refs <- sub("^.*data=[\"']([^\"']+)[\"'].*$", "\\1", object_refs,
                     perl = TRUE)

  md_refs <- character()
  if (identical(companion, "markdown")) {
    md <- gregexpr("!\\[[^]]*\\]\\([^)]+\\)", text, perl = TRUE)
    md_refs <- regmatches(text, md)
    md_refs <- unlist(md_refs, use.names = FALSE)
    md_refs <- sub("^!\\[[^]]*\\]\\(([^)]+)\\)$", "\\1", md_refs,
                   perl = TRUE)
  }

  unique(c(html_refs, embed_refs, object_refs, md_refs))
}

normalize_wordpress_image_tags <- function(text) {
  text <- gsub("<embed([^>]+src=[\"'][^\"']+\\.(png|jpe?g|gif|webp)[\"'][^>]*)/?>",
               "<img\\1 />", text, ignore.case = TRUE, perl = TRUE)
  gsub("<img([^>]*)/[[:space:]]*/>", "<img\\1 />", text,
       ignore.case = TRUE, perl = TRUE)
}

is_local_asset_ref <- function(refs) {
  nzchar(refs) &
    !grepl("^(https?:)?//", refs, ignore.case = TRUE) &
    !grepl("^data:", refs, ignore.case = TRUE) &
    !grepl("^mailto:", refs, ignore.case = TRUE) &
    !grepl("^#", refs)
}

resolve_asset_path <- function(ref, roots) {
  ref <- sub("[?#].*$", "", ref)
  ref <- utils::URLdecode(ref)

  candidates <- if (grepl("^([A-Za-z]:|/)", ref)) {
    ref
  } else {
    file.path(roots, ref)
  }

  candidates <- normalizePath(candidates, winslash = "/", mustWork = FALSE)
  found <- candidates[file.exists(candidates)]
  if (length(found)) found[[1]] else NA_character_
}

unique_asset_name <- function(name, existing) {
  if (!name %in% existing) {
    return(name)
  }

  stem <- tools::file_path_sans_ext(name)
  ext <- tools::file_ext(name)
  ext <- if (nzchar(ext)) paste0(".", ext) else ""

  i <- 2L
  repeat {
    candidate <- paste0(stem, "-", i, ext)
    if (!candidate %in% existing) {
      return(candidate)
    }
    i <- i + 1L
  }
}

convert_pdf_asset_to_png <- function(src, dest) {
  if (requireNamespace("pdftools", quietly = TRUE)) {
    out <- pdftools::pdf_convert(src, format = "png", pages = 1,
                                 filenames = dest, dpi = 160, verbose = FALSE)
    return(length(out) && file.exists(dest))
  }

  pdftoppm <- Sys.which("pdftoppm")
  if (nzchar(pdftoppm)) {
    prefix <- tempfile("document-designer-pdf-image-")
    status <- system2(pdftoppm,
                      c("-png", "-singlefile", "-r", "160", src, prefix),
                      stdout = FALSE, stderr = FALSE)
    candidate <- paste0(prefix, ".png")
    if (identical(status, 0L) && file.exists(candidate)) {
      file.copy(candidate, dest, overwrite = TRUE)
      unlink(candidate)
      return(file.exists(dest))
    }
  }

  magick <- Sys.which("magick")
  if (nzchar(magick)) {
    status <- system2(magick,
                      c("-density", "160", paste0(src, "[0]"), dest),
                      stdout = FALSE, stderr = FALSE)
    return(identical(status, 0L) && file.exists(dest))
  }

  FALSE
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

write_wordpress_checklist <- function(output_file,
                                      companion_file,
                                      assets_dir = NULL,
                                      metadata = list()) {
  checklist_file <- paste0(tools::file_path_sans_ext(companion_file),
                           "-checklist.txt")
  title <- metadata$title
  if (is.null(title) || !nzchar(title)) {
    title <- tools::file_path_sans_ext(basename(output_file))
  }

  lines <- c(
    paste0("WordPress publishing checklist: ", title),
    "",
    "1. Open the WordPress companion file in a browser or text editor.",
    "2. Upload any files in the assets folder to the WordPress Media Library.",
    "3. Paste the companion HTML into the WordPress editor.",
    "4. Replace local image paths with Media Library image URLs if needed.",
    "5. Set the post title, excerpt, categories, tags, and featured image.",
    "6. Preview the post on desktop and mobile before publishing.",
    "7. Confirm the post images are PNG/JPG assets; link the PDF separately only if needed.",
    "",
    paste0("PDF: ", normalizePath(output_file, winslash = "/",
                                  mustWork = FALSE)),
    paste0("Companion: ", normalizePath(companion_file, winslash = "/",
                                        mustWork = FALSE)),
    if (!is.null(assets_dir)) {
      paste0("Assets: ", normalizePath(assets_dir, winslash = "/",
                                       mustWork = FALSE))
    } else {
      "Assets: none detected"
    }
  )

  writeLines(lines, checklist_file, useBytes = TRUE)
  invisible(checklist_file)
}
