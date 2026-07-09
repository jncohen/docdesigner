# docdesigner engine (Phase A)
# Token-driven rendering: reads engine defaults + a style's format.yml,
# resolves inheritance, maps fonts, builds a LaTeX preamble, and returns an
# R Markdown PDF output format. Port of tools/render_style.py (the dev harness),
# which is the executable spec verified by rendering all shipped styles.
#
# `%||%` and dd_hex() live in R/utils.R.

# The style-set bundle format this engine understands. A set that declares a
# higher `format_version` was authored against a newer engine; we refuse to
# load it rather than silently mis-render it.
DD_FORMAT_VERSION <- 1L

# ---- asset locations -------------------------------------------------------
dd_pkg_file <- function(...) {
  p <- system.file(..., package = "docdesigner")
  if (nzchar(p)) return(p)
  file.path(getwd(), "inst", ...)   # dev fallback (devtools::load_all)
}
dd_fontpath <- function() paste0(normalizePath(dd_pkg_file("fonts"), winslash = "/", mustWork = FALSE), "/")

# ---- font registry ---------------------------------------------------------
# Families bundled with the core package. A style set may declare additional
# families in its own format.yml / set.yml under `fonts:`, shipping the files
# in <style>/assets/fonts/ or <set>/assets/fonts/. This is what lets fonts
# travel with a set instead of living in the core package.
dd_builtin_fonts <- function() list(
  "Source Serif 4" = list(regular = "SourceSerif4-Regular.otf", bold = "SourceSerif4-Bold.otf",
                          italic = "SourceSerif4-It.otf", bolditalic = "SourceSerif4-BoldIt.otf"),
  "EB Garamond"    = list(regular = "EBGaramond-Regular.otf", bold = "EBGaramond-Bold.otf",
                          italic = "EBGaramond-Italic.otf", bolditalic = "EBGaramond-BoldItalic.otf"),
  "XITS"           = list(regular = "XITS-Regular.otf", bold = "XITS-Bold.otf",
                          italic = "XITS-Italic.otf", bolditalic = "XITS-BoldItalic.otf"),
  "Fira Code"      = list(regular = "FiraCode-Regular.ttf", bold = "FiraCode-Bold.ttf")
)

# Built-in families, overlaid with any families the resolved spec declares.
dd_font_registry <- function(spec = NULL) {
  reg <- dd_builtin_fonts()
  extra <- spec$fonts
  for (fam in names(extra)) {
    reg[[fam]] <- dd_deep_merge(reg[[fam]] %||% list(), extra[[fam]])
  }
  reg
}

# Where to look for a font file, nearest first: the style's own assets, then
# the set's shared assets, then the core package.
dd_font_dirs <- function(spec = NULL) {
  dir <- attr(spec, "dir")
  dirs <- character()
  if (!is.null(dir)) {
    dirs <- c(dirs,
              file.path(dir, "assets", "fonts"),                    # style-local
              file.path(dirname(dirname(dir)), "assets", "fonts"))  # set-wide
  }
  c(dirs, dd_pkg_file("fonts"))
}

# fontspec's Path= applies to a whole family, so every file in a family must
# sit in one directory. Resolve on the regular face and require the rest there.
dd_font_family_dir <- function(family, reg, dirs) {
  files <- reg[[family]]
  if (is.null(files) || is.null(files$regular)) {
    stop("Unknown font family: ", family,
         "\nDeclare it under `fonts:` in the style, or use one of: ",
         paste(names(dd_builtin_fonts()), collapse = ", "), call. = FALSE)
  }
  hit <- dirs[file.exists(file.path(dirs, files$regular))]
  if (!length(hit)) {
    stop("Font file not found for family '", family, "': ", files$regular,
         "\nSearched: ", paste(dirs, collapse = ", "), call. = FALSE)
  }
  dir <- hit[[1]]
  missing <- vapply(files, function(f) !file.exists(file.path(dir, f)), logical(1))
  if (any(missing)) {
    stop("Font family '", family, "' is split across directories; ",
         "these faces are missing from ", dir, ": ",
         paste(unlist(files)[missing], collapse = ", "), call. = FALSE)
  }
  paste0(normalizePath(dir, winslash = "/", mustWork = FALSE), "/")
}

# ---- yaml loading + inheritance --------------------------------------------
dd_deep_merge <- function(base, over) {
  if (is.null(over)) return(base)
  for (k in names(over)) {
    if (is.list(over[[k]]) && is.list(base[[k]])) base[[k]] <- dd_deep_merge(base[[k]], over[[k]])
    else base[[k]] <- over[[k]]
  }
  base
}

dd_defaults <- function() yaml::read_yaml(dd_pkg_file("engine", "defaults.yml"))

# The declared id of the set a style directory belongs to. Not the folder name:
# a set may be checked out or installed under any directory name, and the index
# keys on the id from set.yml.
dd_owning_set <- function(dir) {
  set_dir <- dirname(dirname(dir))
  man <- file.path(set_dir, "set.yml")
  if (file.exists(man)) yaml::read_yaml(man)$id %||% basename(set_dir) else basename(set_dir)
}

# Walk the `inherits` chain from `dir` up to its root, newest last. A parent is
# looked up by id, preferring the same set before falling back to any set, so a
# set can extend a style it ships alongside without depending on load order.
dd_inherit_chain <- function(dir) {
  chain <- list(); seen <- character()
  repeat {
    y <- yaml::read_yaml(file.path(dir, "format.yml"))
    id <- y$id %||% basename(dir)
    if (id %in% seen) {
      stop("Circular `inherits` in style '", id, "': ",
           paste(c(seen, id), collapse = " -> "), call. = FALSE)
    }
    seen <- c(seen, id)
    chain[[length(chain) + 1]] <- y
    parent <- y$inherits
    if (is.null(parent)) break
    pdir <- dd_style_dir(parent, prefer_set = dd_owning_set(dir))
    if (is.null(pdir)) {
      stop("Style '", id, "' inherits from '", parent, "', which is not installed.",
           call. = FALSE)
    }
    dir <- pdir
  }
  rev(chain)   # root first, so later entries override earlier ones
}

dd_resolve_style <- function(style) {
  dir <- dd_style_dir(style)
  if (is.null(dir)) {
    stop("Unknown docdesigner style: ", style,
         "\nAvailable: ", paste(designer_styles()$style, collapse = ", "), call. = FALSE)
  }
  spec <- dd_defaults()
  for (layer in dd_inherit_chain(dir)) spec <- dd_deep_merge(spec, layer)
  # `inherits` is a resolution instruction, not a design token; drop it so it
  # cannot leak into scaffolds or be mistaken for part of the resolved output.
  spec$inherits <- NULL
  attr(spec, "dir") <- dir
  spec
}

# ---- style discovery across sets (core + user library) ---------------------
dd_set_roots <- function() {
  # Order matters: later roots shadow earlier ones on an id collision, so a
  # user set can deliberately override a core style of the same name.
  user <- file.path(tools::R_user_dir("docdesigner", "data"), "sets")
  c(core = dd_pkg_file("sets"), user = user)
}

# One scan of every set root, returning a data frame of styles keyed on the id
# declared in format.yml (which need not match the folder name).
dd_style_index <- function() {
  rows <- list()
  roots <- dd_set_roots()
  for (src in names(roots)) {
    root <- roots[[src]]
    if (!dir.exists(root)) next
    for (set in list.dirs(root, recursive = FALSE)) {
      sdir <- file.path(set, "styles")
      if (!dir.exists(sdir)) next
      man <- file.path(set, "set.yml")
      set_id <- basename(set)
      if (file.exists(man)) {
        sy <- yaml::read_yaml(man)
        set_id <- sy$id %||% set_id
        fv <- as.integer(sy$format_version %||% 1L)
        if (is.na(fv) || fv > DD_FORMAT_VERSION) {
          warning("Skipping set '", set_id, "': it declares format_version ", sy$format_version,
                  " but this engine supports ", DD_FORMAT_VERSION,
                  ". Upgrade docdesigner.", call. = FALSE)
          next
        }
      }
      for (d in list.dirs(sdir, recursive = FALSE)) {
        f <- file.path(d, "format.yml")
        if (!file.exists(f)) next
        y <- yaml::read_yaml(f)
        rows[[length(rows) + 1]] <- data.frame(
          style = y$id %||% basename(d),
          label = y$label %||% basename(d),
          description = y$description %||% "",
          set = set_id, source = src, dir = d,
          stringsAsFactors = FALSE)
      }
    }
  }
  if (!length(rows)) {
    return(data.frame(style = character(), label = character(), description = character(),
                      set = character(), source = character(), dir = character(),
                      stringsAsFactors = FALSE))
  }
  idx <- do.call(rbind, rows)

  dup <- unique(idx$style[duplicated(idx$style)])
  for (id in dup) {
    hits <- idx[idx$style == id, , drop = FALSE]
    winner <- hits[nrow(hits), ]
    warning("Style id '", id, "' is defined by more than one set (",
            paste(hits$set, collapse = ", "), "). Using the one from '",
            winner$set, "' (", winner$source, "). Rename one to disambiguate.",
            call. = FALSE)
  }
  idx
}

# Resolve a style id, a style directory path, or NULL. On an id collision the
# last match wins (user sets shadow core); `prefer_set` overrides that.
dd_style_dir <- function(style, prefer_set = NULL) {
  if (length(style) == 1L && dir.exists(style) &&
      file.exists(file.path(style, "format.yml"))) {
    return(style)
  }
  idx <- suppressWarnings(dd_style_index())
  hits <- idx[idx$style == style, , drop = FALSE]
  if (!nrow(hits)) return(NULL)
  if (!is.null(prefer_set) && any(hits$set == prefer_set)) {
    hits <- hits[hits$set == prefer_set, , drop = FALSE]
  }
  hits$dir[nrow(hits)]
}

#' List available docdesigner styles
#' @return A data frame of styles with the set they come from.
#' @export
designer_styles <- function() {
  idx <- dd_style_index()
  if (!nrow(idx)) return(data.frame())
  idx[!duplicated(idx$style, fromLast = TRUE),
      c("style", "label", "description", "set"), drop = FALSE]
}

#' Inspect one style's resolved tokens
#' @param style Style name or path to a style directory.
#' @export
designer_style <- function(style = "minimal") dd_resolve_style(style)

# ---- preamble generation (port of harness) ---------------------------------
dd_pt <- function(x) as.numeric(sub("pt", "", x))

dd_fontspec <- function(cmd, family, reg, dirs) {
  files <- reg[[family]]
  fontpath <- dd_font_family_dir(family, reg, dirs)
  tail <- paste0("[Path=", fontpath, ",BoldFont=", files$bold)
  if (!is.null(files$italic)) tail <- paste0(tail, ",ItalicFont=", files$italic,
                                             ",BoldItalicFont=", files$bolditalic)
  paste0(cmd, "{", files$regular, "}", tail, "]")
}

dd_preamble <- function(s) {
  ty <- s$typography; col <- s$color; hd <- s$headings; ti <- s$title
  reg <- dd_font_registry(s); dirs <- dd_font_dirs(s)
  base <- dd_pt(ty$base_size); L <- c()
  add <- function(...) L[[length(L) + 1]] <<- paste0(...)
  add("\\usepackage{fontspec}"); add("\\usepackage{anyfontsize}")
  add(dd_fontspec("\\setmainfont", ty$body, reg, dirs))
  mono <- reg[[ty$mono]]
  monopath <- dd_font_family_dir(ty$mono, reg, dirs)
  add("\\setmonofont{", mono$regular, "}[Path=", monopath, ",BoldFont=", mono$bold, ",Scale=0.82]")
  head_cmd <- ""
  if (!identical(ty$heading, ty$body)) {
    add(dd_fontspec("\\newfontfamily\\ddheadfont", ty$heading, reg, dirs))
    head_cmd <- "\\ddheadfont"
  }
  add("\\usepackage{xcolor}")
  for (role in c("accent","text","muted","rule"))
    add("\\definecolor{", role, "}{HTML}{", dd_hex(col[[role]]), "}")
  add("\\color{text}")
  add("\\usepackage[explicit]{titlesec}")
  hspec <- function(level, cmd) {
    h <- hd[[level]]; size <- round(base * as.numeric(h$scale), 1); lead <- round(size * 1.2, 1)
    wt <- if ((h$weight %||% "bold") == "bold") "\\bfseries" else "\\mdseries"
    txt <- if (identical(h$case, "upper")) "\\MakeUppercase{#1}" else "#1"
    label <- if (isTRUE(hd$number_sections) && cmd == "\\section") "\\thesection\\hspace{0.6em}" else ""
    fmt <- paste0(head_cmd, "\\fontsize{", size, "}{", lead, "}\\selectfont", wt, "\\color{accent}")
    line <- paste0("\\titleformat{", cmd, "}[block]{", fmt, "}{", label, "}{0pt}{", txt, "}")
    if (level == "h1" && isTRUE(h$rule)) line <- paste0(line, "[\\vspace{2pt}{\\color{rule}\\titlerule[1pt]}]")
    line
  }
  add(hspec("h1","\\section")); add(hspec("h2","\\subsection")); add(hspec("h3","\\subsubsection"))
  add("\\titlespacing*{\\section}{0pt}{1.7em}{0.5em}")
  add("\\titlespacing*{\\subsection}{0pt}{1.1em}{0.3em}")
  add("\\titlespacing*{\\subsubsection}{0pt}{0.9em}{0.2em}")
  add("\\usepackage{titling}")
  tsize <- round(base * 2.6, 1)
  add("\\pretitle{\\begin{flushleft}", head_cmd, "\\fontsize{", tsize, "}{", round(tsize*1.1,1),
      "}\\selectfont\\bfseries\\color{accent}}")
  post <- switch(ti$style %||% "plain",
    rule = "\\posttitle{\\par\\end{flushleft}\\vskip0.3em{\\color{rule}\\rule{\\linewidth}{2pt}}\\vskip0.4em}",
    bars = "\\posttitle{\\par\\end{flushleft}\\vskip0.3em{\\color{accent}\\rule{\\linewidth}{3pt}}\\vskip0.4em}",
    "\\posttitle{\\par\\end{flushleft}\\vskip0.4em}")
  add(post)
  add("\\preauthor{\\begin{flushleft}\\large\\color{muted}}"); add("\\postauthor{\\end{flushleft}}")
  add("\\predate{\\begin{flushleft}\\color{muted}}"); add("\\postdate{\\end{flushleft}}")
  add("\\usepackage{microtype}"); add("\\usepackage{booktabs}"); add("\\renewcommand{\\arraystretch}{1.2}")
  add("\\setlength{\\parindent}{0pt}"); add("\\setlength{\\parskip}{0.5em}")
  add("\\linespread{", ty$line_height, "}")
  add("\\usepackage{fancyhdr}\\pagestyle{fancy}\\fancyhf{}")
  add("\\renewcommand{\\headrulewidth}{0pt}\\renewcommand{\\footrulewidth}{0.4pt}")
  add("\\fancyfoot[R]{\\small\\color{muted}\\thepage}")
  paste(unlist(L), collapse = "\n")
}

#' Designed PDF output format
#'
#' @param ... Passed to [rmarkdown::pdf_document()].
#' @param style A style from [designer_styles()] or a style directory path.
#' @return An R Markdown output format.
#' @export
pdf <- function(..., style = "minimal") {
  if (!requireNamespace("rmarkdown", quietly = TRUE)) stop("rmarkdown is required.", call. = FALSE)
  if (!requireNamespace("yaml", quietly = TRUE)) stop("The 'yaml' package is required.", call. = FALSE)
  s <- dd_resolve_style(style)
  header <- tempfile(fileext = ".tex"); writeLines(dd_preamble(s), header)
  base <- dd_pt(s$typography$base_size)
  fontsize <- if (base >= 11.5) "12pt" else if (base >= 10.5) "11pt" else "10pt"
  pargs <- c("-V", paste0("geometry:margin=", s$page$margin),
             "-V", paste0("papersize=", s$page$papersize),
             "-V", paste0("fontsize=", fontsize),
             "-V", "colorlinks=true", "-V", "linkcolor=accent", "-V", "urlcolor=accent",
             "--highlight-style", s$highlight %||% "tango")
  if ((s$page$columns %||% 1) == 2) {
    pargs <- c(pargs, "-V", "classoption=twocolumn")
    # longtable (pandoc's default table) is illegal under twocolumn; convert
    # tables to spanning table* floats with a booktabs tabular instead.
    lua <- dd_pkg_file("engine", "twocolumn-tables.lua")
    pargs <- c(pargs, "--lua-filter", lua)
  }
  rmarkdown::pdf_document(...,
    latex_engine = "xelatex",
    number_sections = isTRUE(s$headings$number_sections),
    includes = rmarkdown::includes(in_header = header),
    pandoc_args = pargs)
}
