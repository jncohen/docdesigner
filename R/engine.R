# docdesigner engine (Phase A)
# Token-driven rendering: reads engine defaults + a style's format.yml,
# resolves inheritance, maps fonts, builds a LaTeX preamble, and returns an
# R Markdown PDF output format. Port of tools/render_style.py (the dev harness),
# which is the executable spec verified by rendering all shipped styles.

`%||%` <- function(x, y) if (is.null(x)) y else x

# ---- asset locations -------------------------------------------------------
dd_pkg_file <- function(...) {
  p <- system.file(..., package = "docdesigner")
  if (nzchar(p)) return(p)
  file.path(getwd(), "inst", ...)   # dev fallback (devtools::load_all)
}
dd_fontpath <- function() paste0(normalizePath(dd_pkg_file("fonts"), winslash = "/", mustWork = FALSE), "/")

# ---- font registry (family -> bundled files) -------------------------------
dd_font_registry <- function() list(
  "Source Serif 4" = list(regular = "SourceSerif4-Regular.otf", bold = "SourceSerif4-Bold.otf",
                          italic = "SourceSerif4-It.otf", bolditalic = "SourceSerif4-BoldIt.otf"),
  "EB Garamond"    = list(regular = "EBGaramond-Regular.otf", bold = "EBGaramond-Bold.otf",
                          italic = "EBGaramond-Italic.otf", bolditalic = "EBGaramond-BoldItalic.otf"),
  "XITS"           = list(regular = "XITS-Regular.otf", bold = "XITS-Bold.otf",
                          italic = "XITS-Italic.otf", bolditalic = "XITS-BoldItalic.otf"),
  "Fira Code"      = list(regular = "FiraCode-Regular.ttf", bold = "FiraCode-Bold.ttf")
)

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

dd_resolve_style <- function(style) {
  dir <- dd_style_dir(style)
  if (is.null(dir)) {
    stop("Unknown docdesigner style: ", style,
         "\nAvailable: ", paste(designer_styles()$style, collapse = ", "), call. = FALSE)
  }
  spec  <- dd_defaults()
  style_yml <- yaml::read_yaml(file.path(dir, "format.yml"))
  parent <- style_yml$inherits
  if (!is.null(parent)) {
    ppath <- file.path(dirname(dir), parent, "format.yml")
    if (file.exists(ppath)) spec <- dd_deep_merge(spec, yaml::read_yaml(ppath))
  }
  dd_deep_merge(spec, style_yml)
}

# ---- style discovery across sets (core + user library) ---------------------
dd_set_roots <- function() {
  roots <- dd_pkg_file("sets")
  user  <- file.path(tools::R_user_dir("docdesigner", "data"), "sets")
  c(roots, if (dir.exists(user)) user else NULL)
}
dd_all_style_dirs <- function() {
  dirs <- character()
  for (root in dd_set_roots()) {
    if (!dir.exists(root)) next
    for (set in list.dirs(root, recursive = FALSE)) {
      sdir <- file.path(set, "styles")
      if (dir.exists(sdir)) {
        cand <- list.dirs(sdir, recursive = FALSE)
        dirs <- c(dirs, cand[file.exists(file.path(cand, "format.yml"))])
      }
    }
  }
  dirs
}
dd_style_dir <- function(style) {
  if (dir.exists(style) && file.exists(file.path(style, "format.yml"))) return(style)
  hit <- dd_all_style_dirs()[basename(dd_all_style_dirs()) == style]
  if (length(hit)) hit[[1]] else NULL
}

#' List available docdesigner styles
#' @return A data frame of styles with the set they come from.
#' @export
designer_styles <- function() {
  dirs <- dd_all_style_dirs()
  if (!length(dirs)) return(data.frame())
  rows <- lapply(dirs, function(d) {
    y <- yaml::read_yaml(file.path(d, "format.yml"))
    data.frame(style = y$id %||% basename(d),
               label = y$label %||% basename(d),
               description = y$description %||% "",
               set = basename(dirname(dirname(d))),
               stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}

#' Inspect one style's resolved tokens
#' @param style Style name or path to a style directory.
#' @export
designer_style <- function(style = "minimal") dd_resolve_style(style)

# ---- preamble generation (port of harness) ---------------------------------
dd_pt <- function(x) as.numeric(sub("pt", "", x))

dd_fontspec <- function(cmd, family, fontpath) {
  reg <- dd_font_registry()[[family]]
  if (is.null(reg)) stop("Unknown font family: ", family, call. = FALSE)
  tail <- paste0("[Path=", fontpath, ",BoldFont=", reg$bold)
  if (!is.null(reg$italic)) tail <- paste0(tail, ",ItalicFont=", reg$italic,
                                           ",BoldItalicFont=", reg$bolditalic)
  paste0(cmd, "{", reg$regular, "}", tail, "]")
}

dd_preamble <- function(s, fontpath = dd_fontpath()) {
  ty <- s$typography; col <- s$color; hd <- s$headings; ti <- s$title
  base <- dd_pt(ty$base_size); L <- c()
  add <- function(...) L[[length(L) + 1]] <<- paste0(...)
  add("\\usepackage{fontspec}"); add("\\usepackage{anyfontsize}")
  add(dd_fontspec("\\setmainfont", ty$body, fontpath))
  mono <- dd_font_registry()[[ty$mono]]
  add("\\setmonofont{", mono$regular, "}[Path=", fontpath, ",BoldFont=", mono$bold, ",Scale=0.82]")
  head_cmd <- ""
  if (!identical(ty$heading, ty$body)) { add(dd_fontspec("\\newfontfamily\\ddheadfont", ty$heading, fontpath)); head_cmd <- "\\ddheadfont" }
  add("\\usepackage{xcolor}")
  for (role in c("accent","text","muted","rule"))
    add("\\definecolor{", role, "}{HTML}{", toupper(sub("^#","",col[[role]])), "}")
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
