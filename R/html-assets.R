# Helpers for html(): copy the local images an HTML file references into a
# folder beside it (converting PDF figures to PNG), rewrite the paths, and
# write a short publishing checklist.

copy_html_assets <- function(companion_file, input_file, companion) {
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
  replacements <- stats::setNames(character(length(refs)), refs)
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
        warning("Could not convert PDF image asset to PNG for HTML: ",
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
    # Replace the reference only where it stands whole -- inside an attribute's
    # quotes or a Markdown link's parentheses. A bare substring replace turned
    # "data.png" into "datpage-assets/a.png" whenever "a.png" was also
    # referenced.
    for (ref in names(replacements)) {
      new <- replacements[[ref]]
      for (q in list(c("\"", "\""), c("'", "'"), c("(", ")"))) {
        text <- gsub(paste0(q[1], ref, q[2]), paste0(q[1], new, q[2]), text, fixed = TRUE)
      }
    }
    text <- normalize_html_image_tags(text)
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

normalize_html_image_tags <- function(text) {
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

write_publishing_checklist <- function(output_file,
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
    paste0("Publishing checklist: ", title),
    "",
    "1. Open the HTML file in a browser or text editor.",
    "2. Upload any files in the assets folder to the CMS media library.",
    "3. Paste the HTML into the CMS editor.",
    "4. Replace local image paths with Media Library image URLs if needed.",
    "5. Set the post title, excerpt, categories, tags, and featured image.",
    "6. Preview the post on desktop and mobile before publishing.",
    "7. Confirm the post images are PNG or JPG files.",
    "",
    paste0("HTML: ", normalizePath(companion_file, winslash = "/",
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
