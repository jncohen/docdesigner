# Claude Design -> docdesigner tokens: the mechanical half of the pipeline.
#
# Full writeup of what this is, what it deliberately does NOT attempt, and
# why: dev/CLAUDE-DESIGN-IMPORT.md.
#
# Scope, in one line: colour, font-family, type scale, weight, and case are
# legible in CSS and are extracted here. Print-page architecture --
# title.layout, page.columns, page.margin, header_footer.* placement -- has
# no analogue in a screen canvas and is never guessed. That split follows
# CLAUDE.md's own warning about the title-page port: "This is where the
# design vocabulary actually gets decided. It is not a mechanical edit."
#
# Input: a Claude Design "Export as standalone HTML" file (Help Center,
# "Get started with Claude Design" -> Export and share). This is a
# self-contained page with CSS in a <style> block and/or inlined on elements.
# This is NOT a general CSS engine: it does not resolve specificity, media
# queries, or cascade order beyond "the first back-to-back rule for this
# selector, then any inline style override on the first matching element."
# That is what Claude Design's flat, mostly-inlined export needs; it is not
# a substitute for a real browser stylesheet cascade.

#' Draft a style scaffold from a Claude Design HTML export
#'
#' Parses colour, font, and type-scale values out of a Claude Design
#' "Export as standalone HTML" file and writes a draft `format.yml`, seeded
#' from an existing style for every token the export cannot answer.
#'
#' This produces a starting point, not a finished style. Tokens with no CSS
#' analogue -- above all `title.layout`, the print-page architecture; also
#' `page.columns`, `page.margin`, `page.twoside`, `header_footer.*`,
#' `title.page_break_after`, and heading/table rule and role choices -- are
#' left at the seed style's value and named in the printed report. Set those
#' by hand, informed by looking at the design on the Claude Design canvas:
#' see `dev/CLAUDE-DESIGN-IMPORT.md` for why this split exists and is not
#' automatable, and STYLE-SPEC.md / `title.layout`'s five archetypes for the
#' vocabulary to choose from.
#'
#' Run [designer_validate_style()] on the result before rendering with it --
#' an extracted colour, font, or scale can still be malformed or reference a
#' font family that is not bundled and needs to be declared and shipped
#' under `assets/fonts/`.
#'
#' @param html Path to the exported HTML file.
#' @param id New style id.
#' @param from Existing style to seed unresolved tokens from. Default `"minimal"`.
#' @param path Destination directory (a style bundle folder is created inside,
#'   as in [designer_new_style()]).
#' @param label Human-readable style label. Defaults to `id`.
#' @return The new style directory, invisibly. Prints an extraction report.
#' @export
designer_import_claude_design <- function(html, id, from = "minimal", path = ".", label = id) {
  if (!requireNamespace("xml2", quietly = TRUE)) {
    stop("The 'xml2' package is required: install.packages(\"xml2\").", call. = FALSE)
  }
  if (!requireNamespace("yaml", quietly = TRUE)) stop("The 'yaml' package is required.", call. = FALSE)
  if (!file.exists(html)) stop("HTML export not found: ", html, call. = FALSE)

  src_dir <- dd_style_dir(from)
  if (is.null(src_dir)) {
    stop("Unknown seed style: ", from, "\nAvailable: ",
         paste(designer_styles()$style, collapse = ", "), call. = FALSE)
  }
  seed <- yaml::read_yaml(file.path(src_dir, "format.yml"))

  doc <- xml2::read_html(html)
  css <- dd_cd_css_text(doc)
  vars <- dd_cd_css_vars(css)

  body_style <- dd_cd_effective_style(doc, css, "body")
  h1_style   <- dd_cd_effective_style(doc, css, "h1")
  h2_style   <- dd_cd_effective_style(doc, css, "h2")
  h3_style   <- dd_cd_effective_style(doc, css, "h3")
  a_style    <- dd_cd_effective_style(doc, css, "a")
  code_style <- dd_cd_effective_style(doc, css, "code, pre")

  extracted <- list()
  note <- function(key, value, source) extracted[[key]] <<- list(value = value, source = source)

  # ---- colour ---------------------------------------------------------------
  accent <- dd_cd_hex(h1_style$color %||% vars[["--color-primary"]] %||% vars[["--accent"]])
  if (!is.null(accent)) note("color.accent", accent, "h1 { color } (or --color-primary / --accent)")

  text_col <- dd_cd_hex(body_style$color %||% vars[["--color-text"]])
  if (!is.null(text_col)) note("color.text", text_col, "body { color }")

  muted <- dd_cd_hex(vars[["--color-muted"]] %||% vars[["--color-secondary"]] %||% vars[["--muted"]])
  if (!is.null(muted)) note("color.muted", muted, "--color-muted / --color-secondary custom property")

  bg <- dd_cd_hex(body_style$`background-color` %||% vars[["--color-background"]])
  if (!is.null(bg) && !identical(bg, "FFFFFF")) note("color.background", bg, "body { background-color }")

  code_bg <- dd_cd_hex(code_style$`background-color`)
  if (!is.null(code_bg)) note("color.code_bg", code_bg, "code/pre { background-color }")

  link_hex <- dd_cd_hex(a_style$color)

  # ---- typography ------------------------------------------------------------
  body_font <- dd_cd_font_family(body_style$`font-family`)
  if (!is.null(body_font)) note("typography.body", body_font, "body { font-family }")

  head_font <- dd_cd_font_family(h1_style$`font-family`)
  if (!is.null(head_font) && !identical(head_font, body_font)) {
    note("typography.heading", head_font, "h1 { font-family }")
  }

  mono_font <- dd_cd_font_family(code_style$`font-family`)
  if (!is.null(mono_font)) note("typography.mono", mono_font, "code/pre { font-family }")

  base_px <- dd_cd_px(body_style$`font-size`)
  if (!is.null(base_px)) note("typography.base_size", dd_cd_pt_step(base_px * 0.75), "body { font-size }")

  lh <- suppressWarnings(as.numeric(body_style$`line-height`))
  if (length(lh) && !is.na(lh) && lh > 0.9 && lh < 2.5) {
    note("typography.line_height", round(lh, 2), "body { line-height }")
  }

  # ---- heading scale, weight, case -------------------------------------------
  heading_styles <- list(h1 = h1_style, h2 = h2_style, h3 = h3_style)
  for (lvl in names(heading_styles)) {
    hs <- heading_styles[[lvl]]
    px <- dd_cd_px(hs$`font-size`)
    if (!is.null(px) && !is.null(base_px) && base_px > 0) {
      note(paste0("headings.", lvl, ".scale"), round(px / base_px, 2),
           paste0(lvl, " { font-size } / body { font-size }"))
    }
    fw <- suppressWarnings(as.numeric(hs$`font-weight`))
    if (length(fw) && !is.na(fw)) {
      note(paste0("headings.", lvl, ".weight"),
           if (fw >= 600) "bold" else if (fw <= 300) "light" else "regular",
           paste0(lvl, " { font-weight }"))
    }
    tt <- hs$`text-transform`
    if (!is.null(tt) && tt %in% c("uppercase", "lowercase")) {
      note(paste0("headings.", lvl, ".case"), if (identical(tt, "uppercase")) "upper" else "lower",
           paste0(lvl, " { text-transform }"))
    }
  }

  # ---- assemble the scaffold --------------------------------------------------
  seed$id <- id
  seed$label <- label
  seed$description <- paste0("Drafted from a Claude Design export (", basename(html),
                             "); seeded from '", from, "' for everything the CSS did not answer.")
  for (k in names(extracted)) {
    if (grepl("\\.color$", k) && !grepl("^color\\.", k)) next  # role tokens, resolved below
    seed[[k]] <- extracted[[k]]$value
  }
  if (!is.null(link_hex)) {
    role <- dd_cd_nearest_role(link_hex, seed)
    seed[["links.color"]] <- role
    note("links.color", role, paste0("a { color } (", link_hex, ", nearest role)"))
  }

  dest <- file.path(normalizePath(path, mustWork = FALSE), id)
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)
  out <- file.path(dest, "format.yml")
  lines <- c(
    paste0("# docdesigner style '", id, "' -- drafted from a Claude Design export."),
    paste0("# Source: ", html),
    paste0("# Seeded from '", from, "' for every token the export did not answer."),
    "# Flat keys only. Run designer_validate_style() before rendering.",
    "#",
    "# NOT extracted -- print-page architecture has no analogue in a screen",
    "# canvas and is never guessed. Set these by hand after reviewing the",
    "# Claude Design canvas (see dev/CLAUDE-DESIGN-IMPORT.md):",
    "#   title.layout, page.columns, page.margin, page.twoside,",
    "#   header_footer.*, title.page_break_after, headings.<h>.color,",
    "#   headings.<h>.rule.*, title.rule.*, table.style, paragraph.indent",
    "#   vs paragraph.spacing",
    "",
    vapply(names(seed), function(k) dd_yaml_line(k, seed[[k]]), character(1))
  )
  writeLines(lines, out)

  report <- if (length(extracted)) {
    do.call(rbind, lapply(names(extracted), function(k) {
      data.frame(key = k, value = as.character(extracted[[k]]$value),
                 source = extracted[[k]]$source, stringsAsFactors = FALSE)
    }))
  } else {
    data.frame(key = character(), value = character(), source = character())
  }

  cat("docdesigner: drafted style '", id, "' at ", out, "\n\n", sep = "")
  cat("Extracted ", nrow(report), " token(s) from the CSS:\n", sep = "")
  if (nrow(report)) print(report, row.names = FALSE)
  cat("\nNot extracted -- structural tokens with no CSS analogue, left at '",
      from, "'s value:\n", sep = "")
  cat("  title.layout, page.columns, page.margin, page.twoside, header_footer.*,\n",
      "  title.page_break_after, headings.<h>.color, headings.<h>.rule.*,\n",
      "  title.rule.*, table.style, paragraph.indent vs paragraph.spacing\n", sep = "")
  cat("\nRun designer_validate_style('", id, "') next.\n", sep = "")

  invisible(dest)
}

# ---- CSS helpers for designer_import_claude_design() -----------------------
# Deliberately simple, not a CSS engine: no specificity, no media queries, no
# cascade beyond "the first back-to-back rule for this exact selector text,
# then the first matching element's inline style override." Sufficient for
# Claude Design's flat, mostly-inlined "standalone HTML" export.

dd_cd_css_text <- function(doc) {
  nodes <- xml2::xml_find_all(doc, "//style")
  if (!length(nodes)) return("")
  paste(vapply(nodes, xml2::xml_text, character(1)), collapse = "\n")
}

# `:root { --name: value; }` and similar custom-property declarations,
# wherever in the stylesheet they appear.
dd_cd_css_vars <- function(css) {
  hits <- regmatches(css, gregexpr("--[a-zA-Z0-9_-]+\\s*:\\s*[^;]+;", css))[[1]]
  if (!length(hits)) return(list())
  out <- list()
  for (h in hits) {
    parts <- strsplit(sub(";\\s*$", "", h), ":", fixed = TRUE)[[1]]
    if (length(parts) < 2) next
    out[[trimws(parts[1])]] <- trimws(paste(parts[-1], collapse = ":"))
  }
  out
}

dd_cd_parse_decls <- function(body) {
  out <- list()
  for (p in strsplit(body, ";")[[1]]) {
    kv <- strsplit(p, ":", fixed = TRUE)[[1]]
    if (length(kv) < 2) next
    out[[trimws(kv[1])]] <- trimws(paste(kv[-1], collapse = ":"))
  }
  out
}

# Declarations for the first back-to-back rule matching `selector` verbatim
# (e.g. "h1", "code, pre"), overridden by the first matching element's
# inline `style=` attribute, since that is what Claude Design's export
# actually varies between elements sharing one tag.
dd_cd_effective_style <- function(doc, css, selector) {
  decls <- list()
  escaped <- gsub("([.*+?^${}()|\\[\\]\\\\])", "\\\\\\1", selector, perl = TRUE)
  pat <- paste0("(^|\\})\\s*", escaped, "\\s*\\{([^}]*)\\}")
  hit <- regmatches(css, regexpr(pat, css, perl = TRUE))
  if (length(hit) && nzchar(hit)) {
    body <- sub("^[^{]*\\{", "", hit)
    body <- sub("\\}\\s*$", "", body)
    decls <- dd_cd_parse_decls(body)
  }
  tag <- trimws(strsplit(selector, ",", fixed = TRUE)[[1]][1])
  node <- tryCatch(xml2::xml_find_first(doc, paste0("//", tag)), error = function(e) NULL)
  if (!is.null(node) && !inherits(node, "xml_missing")) {
    inline <- xml2::xml_attr(node, "style")
    if (!is.na(inline)) decls <- utils::modifyList(decls, dd_cd_parse_decls(inline))
  }
  decls
}

# Accepts `#RRGGBB` / `RRGGBB` or `rgb(r, g, b)`; returns bare uppercase hex
# or NULL (e.g. for `currentColor`, gradients, or anything else unreadable
# as a flat colour).
dd_cd_hex <- function(x) {
  if (is.null(x)) return(NULL)
  x <- trimws(x)
  if (grepl("^#?[0-9A-Fa-f]{6}$", x)) return(toupper(sub("^#", "", x)))
  if (grepl("^rgba?\\(", x)) {
    nums <- suppressWarnings(as.numeric(regmatches(x, gregexpr("[0-9.]+", x))[[1]]))
    if (length(nums) >= 3 && !anyNA(nums[1:3])) {
      return(toupper(paste(sprintf("%02X", round(nums[1:3])), collapse = "")))
    }
  }
  NULL
}

# First family in the stack, mapped onto a bundled font if it matches one
# case-insensitively, else returned as-is (designer_validate_style() will
# then flag it as an unknown font, which is the correct outcome: it tells
# you to declare it under fonts.<Family>.regular and ship the files).
dd_cd_font_family <- function(x) {
  if (is.null(x)) return(NULL)
  first <- trimws(strsplit(x, ",", fixed = TRUE)[[1]][1])
  first <- gsub('["\']', "", first)
  if (!nzchar(first)) return(NULL)
  bundled <- dd_schema()$bundled_fonts
  hit <- bundled[tolower(bundled) == tolower(first)]
  if (length(hit)) hit[1] else first
}

dd_cd_px <- function(x) {
  if (is.null(x)) return(NULL)
  x <- trimws(x)
  if (grepl("px$", x)) return(suppressWarnings(as.numeric(sub("px$", "", x))))
  if (grepl("rem$", x)) return(suppressWarnings(as.numeric(sub("rem$", "", x))) * 16)
  if (grepl("pt$", x)) return(suppressWarnings(as.numeric(sub("pt$", "", x))) / 0.75)
  NULL
}

# Snap to the nearest step typography.base_size's enum accepts (schema.yml:
# 8pt..12pt in half-point steps).
dd_cd_pt_step <- function(pt) {
  steps <- c(8, 8.5, 9, 9.5, 10, 10.5, 11, 11.5, 12)
  paste0(steps[which.min(abs(steps - pt))], "pt")
}

# Nearest of the *style's own* extracted accent/text/muted colours by RGB
# distance, so a role token (what links.color requires) is set to a role
# name, never a raw hex the validator would reject.
dd_cd_nearest_role <- function(hex, seed) {
  roles <- list(accent = seed[["color.accent"]], text = seed[["color.text"]],
                muted = seed[["color.muted"]])
  roles <- roles[!vapply(roles, is.null, logical(1))]
  if (!length(roles)) return("accent")
  dist <- function(a, b) {
    av <- strtoi(substring(a, c(1, 3, 5), c(2, 4, 6)), 16L)
    bv <- strtoi(substring(b, c(1, 3, 5), c(2, 4, 6)), 16L)
    sqrt(sum((av - bv)^2))
  }
  d <- vapply(roles, function(r) dist(hex, dd_hex(as.character(r))), numeric(1))
  names(roles)[which.min(d)]
}
