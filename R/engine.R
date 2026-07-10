# docdesigner engine.
#
# Style files are flat: `dotted.key: value`, one per line, column zero. The
# engine expands them (R/schema.R) into the nested list this file consumes.
# Engine defaults are DERIVED FROM inst/engine/schema.yml -- there is no
# separate defaults file to drift out of sync.
#
# `%||%` and dd_hex() live in R/utils.R. Schema helpers live in R/schema.R.

DD_FORMAT_VERSION <- 2L

# ---- asset locations -------------------------------------------------------
dd_pkg_file <- function(...) {
  p <- system.file(..., package = "docdesigner")
  if (nzchar(p)) return(p)
  file.path(getwd(), "inst", ...)   # dev fallback (devtools::load_all)
}

# ---- font registry ---------------------------------------------------------
# Families bundled with the core package. A style may declare more under
# `fonts.<Family>.<face>` and ship the files in <style>/assets/fonts/ or
# <set>/assets/fonts/. This is what lets fonts travel with a set.
dd_builtin_fonts <- function() list(
  "Source Serif 4" = list(regular = "SourceSerif4-Regular.otf", bold = "SourceSerif4-Bold.otf",
                          italic = "SourceSerif4-It.otf", bolditalic = "SourceSerif4-BoldIt.otf"),
  "EB Garamond"    = list(regular = "EBGaramond-Regular.otf", bold = "EBGaramond-Bold.otf",
                          italic = "EBGaramond-Italic.otf", bolditalic = "EBGaramond-BoldItalic.otf"),
  "XITS"           = list(regular = "XITS-Regular.otf", bold = "XITS-Bold.otf",
                          italic = "XITS-Italic.otf", bolditalic = "XITS-BoldItalic.otf"),
  "Fira Code"      = list(regular = "FiraCode-Regular.ttf", bold = "FiraCode-Bold.ttf")
)

dd_font_registry <- function(spec = NULL) {
  reg <- dd_builtin_fonts()
  for (fam in names(spec$fonts)) {
    reg[[fam]] <- dd_deep_merge(reg[[fam]] %||% list(), spec$fonts[[fam]])
  }
  reg
}

dd_font_dirs <- function(spec = NULL) {
  dir <- attr(spec, "dir")
  dirs <- character()
  if (!is.null(dir)) {
    dirs <- c(dirs,
              file.path(dir, "assets", "fonts"),
              file.path(dirname(dirname(dir)), "assets", "fonts"))
  }
  c(dirs, dd_pkg_file("fonts"))
}

# fontspec's Path= applies to a whole family, so all its faces must share a
# directory. Resolve on the regular face and require the rest beside it.
dd_font_family_dir <- function(family, reg, dirs) {
  files <- reg[[family]]
  if (is.null(files) || is.null(files$regular)) {
    stop("Unknown font family: ", family,
         "\nDeclare it as fonts.", family, ".regular, or use one of: ",
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

# ---- defaults, merging, inheritance ----------------------------------------
dd_deep_merge <- function(base, over) {
  if (is.null(over)) return(base)
  for (k in names(over)) {
    if (is.list(over[[k]]) && is.list(base[[k]])) base[[k]] <- dd_deep_merge(base[[k]], over[[k]])
    else base[[k]] <- over[[k]]
  }
  base
}

# Engine defaults are every token in schema.yml that declares one.
dd_defaults <- function() {
  tokens <- dd_token_table()
  flat <- list()
  for (k in names(tokens)) {
    d <- tokens[[k]]$default
    if (!is.null(d)) flat[[k]] <- d
  }
  dd_expand_dotted(flat)
}

dd_read_style <- function(dir) dd_expand_dotted(yaml::read_yaml(file.path(dir, "format.yml")))

dd_owning_set <- function(dir) {
  set_dir <- dirname(dirname(dir))
  man <- file.path(set_dir, "set.yml")
  if (file.exists(man)) yaml::read_yaml(man)$id %||% basename(set_dir) else basename(set_dir)
}

dd_inherit_chain <- function(dir) {
  chain <- list(); seen <- character()
  repeat {
    y <- dd_read_style(dir)
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
  rev(chain)   # root first
}

dd_resolve_style <- function(style) {
  dir <- dd_style_dir(style)
  if (is.null(dir)) {
    stop("Unknown docdesigner style: ", style,
         "\nAvailable: ", paste(designer_styles()$style, collapse = ", "), call. = FALSE)
  }
  spec <- dd_defaults()
  for (layer in dd_inherit_chain(dir)) spec <- dd_deep_merge(spec, layer)
  spec$inherits <- NULL   # a resolution instruction, not a token
  attr(spec, "dir") <- dir
  spec
}

# ---- style discovery -------------------------------------------------------
dd_set_roots <- function() {
  # Later roots shadow earlier ones on an id collision, so a user set can
  # deliberately override a core style of the same name.
  c(core = dd_pkg_file("sets"),
    user = file.path(tools::R_user_dir("docdesigner", "data"), "sets"))
}

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
        fv <- suppressWarnings(as.integer(sy$format_version %||% 1L))
        if (is.na(fv) || fv > DD_FORMAT_VERSION) {
          warning("Skipping set '", set_id, "': it declares format_version ",
                  sy$format_version, " but this engine supports ", DD_FORMAT_VERSION,
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
  for (id in unique(idx$style[duplicated(idx$style)])) {
    hits <- idx[idx$style == id, , drop = FALSE]
    winner <- hits[nrow(hits), ]
    warning("Style id '", id, "' is defined by more than one set (",
            paste(hits$set, collapse = ", "), "). Using the one from '",
            winner$set, "' (", winner$source, "). Rename one to disambiguate.",
            call. = FALSE)
  }
  idx
}

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

# ---- preamble generation ---------------------------------------------------
dd_pt <- function(x) as.numeric(sub("pt", "", x))

dd_fontspec <- function(cmd, family, reg, dirs) {
  files <- reg[[family]]
  fontpath <- dd_font_family_dir(family, reg, dirs)
  tail <- paste0("[Path=", fontpath, ",BoldFont=", files$bold)
  if (!is.null(files$italic)) tail <- paste0(tail, ",ItalicFont=", files$italic,
                                             ",BoldItalicFont=", files$bolditalic)
  paste0(cmd, "{", files$regular, "}", tail, "]")
}

# A rule spec -> LaTeX, or "" when absent. `after` is the titlesec after-code.
dd_rule_tex <- function(r, default_weight, cmd = "\\titlerule") {
  if (is.null(r) || identical(r$position %||% "none", "none")) return("")
  w <- dd_len("rule_weight", r$weight, default_weight)
  paste0("{\\color{", r$color %||% "rule", "}", cmd, "[", w, "]}")
}

dd_preamble <- function(s) {
  ty <- s$typography; col <- s$color; hd <- s$headings; ti <- s$title
  reg <- dd_font_registry(s); dirs <- dd_font_dirs(s)
  base <- dd_pt(ty$base_size); L <- c()
  add <- function(...) L[[length(L) + 1]] <<- paste0(...)

  add("\\usepackage{fontspec}"); add("\\usepackage{anyfontsize}")
  add(dd_fontspec("\\setmainfont", ty$body, reg, dirs))
  mono <- reg[[ty$mono]]
  add("\\setmonofont{", mono$regular, "}[Path=", dd_font_family_dir(ty$mono, reg, dirs),
      ",BoldFont=", mono$bold, ",Scale=", ty$mono_scale, "]")
  head_cmd <- ""
  if (!identical(ty$heading, ty$body)) {
    add(dd_fontspec("\\newfontfamily\\ddheadfont", ty$heading, reg, dirs))
    head_cmd <- "\\ddheadfont"
  }

  add("\\usepackage{xcolor}")
  for (role in dd_schema()$roles) {
    if (!is.null(col[[role]])) add("\\definecolor{", role, "}{HTML}{", dd_hex(col[[role]]), "}")
  }
  add("\\color{text}")

  add("\\usepackage[explicit]{titlesec}")
  hspec <- function(level, cmd) {
    h <- hd[[level]]
    size <- round(base * as.numeric(h$scale), 1); lead <- round(size * 1.2, 1)
    wt <- if ((h$weight %||% "bold") == "bold") "\\bfseries" else "\\mdseries"
    txt <- if (identical(h$case, "upper")) "\\MakeUppercase{#1}" else "#1"
    label <- if (isTRUE(hd$number_sections) && cmd == "\\section") "\\thesection\\hspace{0.6em}" else ""
    fmt <- paste0(head_cmd, "\\fontsize{", size, "}{", lead, "}\\selectfont", wt,
                  "\\color{", h$color %||% "accent", "}")
    line <- paste0("\\titleformat{", cmd, "}[block]{", fmt, "}{", label, "}{0pt}{", txt, "}")
    rule <- dd_rule_tex(h$rule, "medium")
    if (nzchar(rule)) line <- paste0(line, "[\\vspace{2pt}", rule, "]")
    line
  }
  add(hspec("h1", "\\section")); add(hspec("h2", "\\subsection")); add(hspec("h3", "\\subsubsection"))
  for (lvl in c("h1", "h2", "h3")) {
    cmd <- c(h1 = "\\section", h2 = "\\subsection", h3 = "\\subsubsection")[[lvl]]
    add("\\titlespacing*{", cmd, "}{0pt}{",
        dd_len("space", hd[[lvl]]$space_before, "lg"), "}{",
        dd_len("space", hd[[lvl]]$space_after, "sm"), "}")
  }

  add("\\usepackage{titling}")
  tsize <- round(base * ti$scale, 1)
  add("\\pretitle{\\begin{flushleft}", head_cmd, "\\fontsize{", tsize, "}{",
      round(tsize * 1.1, 1), "}\\selectfont\\bfseries\\color{accent}}")
  # \titlerule takes [weight]; \rule takes {width}{height}. Build inline rather
  # than reuse dd_rule_tex(), whose output suits titlesec's after-code only.
  if (!is.null(ti$rule) && !identical(ti$rule$position %||% "none", "none")) {
    w <- dd_len("rule_weight", ti$rule$weight, "thick")
    add("\\posttitle{\\par\\end{flushleft}\\vskip0.3em{\\color{", ti$rule$color %||% "rule",
        "}\\rule{\\linewidth}{", w, "}}\\vskip0.4em}")
  } else {
    add("\\posttitle{\\par\\end{flushleft}\\vskip0.4em}")
  }
  add("\\preauthor{\\begin{flushleft}\\large\\color{", ti$byline$color %||% "muted", "}}")
  add("\\postauthor{\\end{flushleft}}")
  add("\\predate{\\begin{flushleft}\\color{", ti$date$color %||% "muted", "}}")
  add("\\postdate{\\end{flushleft}}")

  if (isTRUE(ty$microtype)) add("\\usepackage{microtype}")
  add("\\usepackage{booktabs}")
  add("\\renewcommand{\\arraystretch}{", s$table$row_stretch, "}")
  add("\\setlength{\\parindent}{", dd_len("indent", s$paragraph$indent, "none"), "}")
  add("\\setlength{\\parskip}{", dd_len("space", s$paragraph$spacing, "sm"), "}")
  add("\\linespread{", ty$line_height, "}")

  add("\\usepackage{fancyhdr}\\pagestyle{fancy}\\fancyhf{}")
  add("\\renewcommand{\\headrulewidth}{0pt}")
  add("\\renewcommand{\\footrulewidth}{", if (isTRUE(s$header_footer$footer$rule)) "0.4pt" else "0pt", "}")
  slot <- c(left = "L", center = "C", right = "R")
  for (pos in names(slot)) {
    what <- s$header_footer$footer[[pos]] %||% "none"
    if (identical(what, "none")) next
    content <- switch(what, page = "\\thepage", title = "\\thetitle", "\\thepage")
    add("\\fancyfoot[", slot[[pos]], "]{\\small\\color{muted}", content, "}")
  }
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
  margin <- dd_len("margin", s$page$margin, "normal")

  pargs <- c("-V", paste0("geometry:margin=", margin),
             "-V", paste0("papersize=", s$page$papersize),
             "-V", paste0("fontsize=", fontsize),
             "-V", "colorlinks=true",
             "-V", paste0("linkcolor=", s$links$color %||% "accent"),
             "-V", paste0("urlcolor=", s$links$color %||% "accent"))

  hl <- s$code$highlight %||% "tango"
  pargs <- c(pargs, if (identical(hl, "none")) "--no-highlight" else c("--highlight-style", hl))

  if ((s$page$columns %||% 1) == 2) {
    pargs <- c(pargs, "-V", "classoption=twocolumn")
    # longtable (pandoc's default table) is illegal under twocolumn; convert
    # tables to spanning table* floats with a booktabs tabular instead.
    pargs <- c(pargs, "--lua-filter", dd_pkg_file("engine", "twocolumn-tables.lua"))
  }

  rmarkdown::pdf_document(...,
    latex_engine = "xelatex",
    number_sections = isTRUE(s$headings$number_sections),
    includes = rmarkdown::includes(in_header = header),
    pandoc_args = pargs)
}
