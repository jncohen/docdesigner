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

  # rmarkdown's pdf_document appends its own `geometry:margin=1in` AFTER our
  # pandoc -V args. geometry lets later options win and `margin` sets all four
  # sides at once, so that default silently clobbered every per-side value —
  # and page.margin too, which is why every style rendered at 1in regardless of
  # its tokens. This preamble is injected via header-includes, i.e. after
  # \usepackage{geometry}, so \geometry{} here is the last word. The -V args in
  # dd_geometry() are kept so the package is still loaded with our values even
  # if rmarkdown ever stops supplying its default.
  add("\\geometry{", paste(dd_geometry_opts(s), collapse = ","), "}")

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
  # Label/furniture face (kickers, callout titles, table headers). Loaded by
  # NAME so a style can point at a system grotesque (Arial, Archivo, ...)
  # without bundling it. \IfFontExistsTF guards a missing font, so \ddlabelfont
  # is always defined and safe to use — it degrades to the body face.
  if (!is.null(ty$label)) {
    add("\\IfFontExistsTF{", ty$label, "}{\\newfontfamily\\ddlabelfont{", ty$label,
        "}}{\\providecommand{\\ddlabelfont}{}}")
  } else {
    add("\\providecommand{\\ddlabelfont}{}")
  }

  add("\\usepackage{xcolor}")
  for (role in dd_schema()$roles) {
    if (!is.null(col[[role]])) add("\\definecolor{", role, "}{HTML}{", dd_hex(col[[role]]), "}")
  }
  add("\\color{text}")

  add("\\usepackage[explicit]{titlesec}")
  case_cmd <- function(case) switch(case %||% "none",
    upper = "\\MakeUppercase{#1}",
    lower = "\\MakeLowercase{#1}",
    smallcaps = "\\textsc{\\MakeLowercase{#1}}",
    "#1")
  align_cmd <- function(align) switch(align %||% "left",
    center = "\\centering ", right = "\\raggedleft ", "")
  # [block] puts the heading on its own line (h1-h3); [runin] keeps it flush
  # with the paragraph that follows (h4) and never carries a numeric label,
  # regardless of headings.number_sections.
  hspec <- function(level, cmd, shape = "block") {
    h <- hd[[level]]
    size <- round(base * as.numeric(h$scale), 1); lead <- round(size * 1.2, 1)
    wt <- if ((h$weight %||% "bold") == "bold") "\\bfseries" else "\\mdseries"
    it <- if (identical(h$style, "italic")) "\\itshape" else ""
    txt <- case_cmd(h$case)
    # Each level takes its own counter (\thesection, \thesubsection, ...), so
    # number_sections numbers h1-h3 rather than h1 alone. [runin] (h4) is never
    # numbered: pandoc's --number-sections raises secnumdepth past h4, and a
    # cascading "1.1.1.1" in front of a run-in heading is never wanted.
    label <- if (isTRUE(hd$number_sections) && !identical(shape, "runin")) {
      paste0("\\the", sub("^\\\\", "", cmd), "\\hspace{0.6em}")
    } else ""
    fmt <- paste0(align_cmd(h$align), head_cmd, "\\fontsize{", size, "}{", lead, "}\\selectfont", wt, it,
                  "\\color{", h$color %||% "accent", "}")
    line <- paste0("\\titleformat{", cmd, "}[", shape, "]{", fmt, "}{", label, "}{0pt}{", txt, "}")
    rule <- dd_rule_tex(h$rule, "medium")
    if (nzchar(rule)) line <- paste0(line, "[\\vspace{2pt}", rule, "]")
    line
  }
  # headings.run_in names the levels that run into the following paragraph
  # instead of standing on their own line -- the ASA/Chicago sub-subheading
  # convention six of the shipped styles ask for. h4 is run-in unconditionally,
  # as it always was. Note that a run-in level loses its section number: the
  # label logic in hspec() keys off the shape, and a cascading "1.1.1" sitting
  # in front of a run-in heading is never what a journal wants.
  run_in <- as.character(hd$run_in %||% character())
  shape_of <- function(lvl) if (lvl %in% run_in) "runin" else "block"
  add(hspec("h1", "\\section"))
  add(hspec("h2", "\\subsection",    shape = shape_of("h2")))
  add(hspec("h3", "\\subsubsection", shape = shape_of("h3")))
  add(hspec("h4", "\\paragraph",     shape = "runin"))
  for (lvl in c("h1", "h2", "h3", "h4")) {
    cmd <- c(h1 = "\\section", h2 = "\\subsection", h3 = "\\subsubsection", h4 = "\\paragraph")[[lvl]]
    add("\\titlespacing*{", cmd, "}{0pt}{",
        dd_len("space", hd[[lvl]]$space_before, "lg"), "}{",
        dd_len("space", hd[[lvl]]$space_after, "sm"), "}")
  }

  add("\\usepackage{titling}")
  add("\\usepackage{etoolbox}")
  tsize <- round(base * ti$scale, 1)
  # title.align (center/left) governs the whole title block, not just the
  # title line itself, so byline/date share the same environment.
  align_env <- if (identical(ti$align, "center")) "center" else "flushleft"

  # pandoc's LaTeX template appends the subtitle to \@title at a fixed \large,
  # inheriting the title's face and colour -- which is why every title.subtitle.*
  # token sat at status: port. It defines \subtitle with \providecommand, i.e.
  # only if undefined, and rmarkdown injects this preamble BEFORE that line. So
  # defining \subtitle here pre-empts pandoc's and is what makes the subtitle
  # independently styleable at all. \normalfont\mdseries resets the \bfseries
  # inherited from \pretitle.
  sub <- ti$subtitle
  ssize <- round(base * as.numeric(sub$scale %||% 1.3), 1)
  sit <- if (identical(sub$style %||% "italic", "italic")) "\\itshape" else ""
  add("\\makeatletter")
  # Capture the clean title BEFORE the subtitle is appended, so running heads
  # (\thetitle would otherwise carry the appended subtitle markup and render as
  # garbage/"0" wherever runningtitle is used).
  add("\\newcommand{\\subtitle}[1]{\\global\\let\\ddrtitle\\@title\\apptocmd{\\@title}{\\par\\vspace{0.3em}",
      "{\\normalfont\\mdseries", head_cmd, "\\fontsize{", ssize, "}{",
      round(ssize * 1.35, 1), "}\\selectfont", sit, "\\color{",
      sub$color %||% "muted", "}#1\\par}}{}{}}")
  add("\\makeatother")

  # Kicker: a short eyebrow label emitted ABOVE the title, inside \pretitle's
  # alignment environment. Defaults to the sans label face so it reads as
  # furniture against the serif headline (the economist/government/policy move).
  kick <- ti$kicker
  kicker_tex <- ""
  if (!is.null(kick$text)) {
    ksize <- round(base * as.numeric(kick$scale %||% 0.8), 1)
    kfont <- switch(kick$font %||% "label", label = "\\ddlabelfont", heading = head_cmd, "")
    kcased <- switch(kick$case %||% "upper",
      upper = paste0("\\MakeUppercase{", kick$text, "}"),
      lower = paste0("\\MakeLowercase{", kick$text, "}"),
      smallcaps = paste0("\\textsc{\\MakeLowercase{", kick$text, "}}"),
      kick$text)
    kicker_tex <- paste0("{", kfont, "\\fontsize{", ksize, "}{", round(ksize * 1.2, 1),
      "}\\selectfont\\bfseries\\color{", kick$color %||% "accent", "}", kcased, "\\par}\\vskip0.35em ")
  }
  add("\\pretitle{\\begin{", align_env, "}", kicker_tex, head_cmd, "\\fontsize{", tsize, "}{",
      round(tsize * 1.18, 1), "}\\selectfont\\bfseries\\color{", ti$color %||% "text", "}}")
  # \titlerule takes [weight]; \rule takes {width}{height}. Build inline rather
  # than reuse dd_rule_tex(), whose output suits titlesec's after-code only.
  if (!is.null(ti$rule) && !identical(ti$rule$position %||% "none", "none")) {
    w <- dd_len("rule_weight", ti$rule$weight, "thick")
    # A short centred rule is a distinct design move from a full-measure one
    # (atlantic's masthead uses 64px), so title.rule.length overrides \linewidth.
    len <- if (!is.null(ti$rule$length)) paste0(ti$rule$length, "in") else "\\linewidth"
    rule_tex <- paste0("{\\color{", ti$rule$color %||% "rule", "}\\rule{", len, "}{", w, "}}")
    # The rule is emitted after \end{center}, i.e. back in ordinary flush-left
    # mode. A full-measure rule fills the line so it looks centred either way,
    # but a short one would sit at the left margin without this.
    if (identical(align_env, "center")) rule_tex <- paste0("\\centerline{", rule_tex, "}")
    add("\\posttitle{\\par\\end{", align_env, "}\\vskip0.3em", rule_tex, "\\vskip0.4em}")
  } else {
    add("\\posttitle{\\par\\end{", align_env, "}\\vskip0.4em}")
  }
  # `abstract` is an environment the document class defines and pandoc emits
  # verbatim, so renewing it here takes it over completely -- the same lever as
  # \subtitle above, and why every title.abstract.* token could sit at
  # status: port. A trivlist gives symmetric margins without pulling in
  # changepage. Three label treatments, because the mockups want three:
  # demography a run-in small-caps label, nature none at all (a bold
  # standfirst), atlantic none (it has a deck instead).
  ab <- ti$abstract
  if (identical(ab$show %||% TRUE, FALSE)) {
    add("\\renewenvironment{abstract}{\\setbox0\\vbox\\bgroup}{\\egroup}")
  } else {
    asize <- round(base * as.numeric(ab$size %||% 0.95), 1)
    aind <- dd_len("indent", ab$indent, "none")
    awt <- if (identical(ab$weight %||% "regular", "bold")) "\\bfseries" else ""
    lab <- ab$label %||% "Abstract"
    lstyle <- ab$label_style %||% "heading"
    # The heading label honours label_align / label_case / label_color, so it
    # works both plain and as the title of a boxed abstract (methods wants a
    # right-justified, all-caps, accent label inside the panel).
    lalign <- switch(ab$label_align %||% "center",
                     right = "\\raggedleft", left = "\\raggedright", "\\centering")
    lcased <- switch(ab$label_case %||% "none",
                     upper = paste0("\\MakeUppercase{", lab, "}"),
                     smallcaps = paste0("\\textsc{\\MakeLowercase{", lab, "}}"), lab)
    heading_lab <- paste0("{", lalign, "\\bfseries\\color{", ab$label_color %||% "text",
                          "}", lcased, "\\par}\\vspace{0.35em}\\noindent\\ignorespaces")
    lab_tex <- switch(lstyle,
      runin = paste0("\\noindent{\\scshape ", lab, "}\\hspace{0.7em}\\ignorespaces"),
      none  = "\\noindent\\ignorespaces",
      heading_lab)
    body_fmt <- paste0("\\fontsize{", asize, "}{", round(asize * 1.4, 1), "}\\selectfont",
                       awt, "\\color{", ab$color %||% "text", "}%")
    if (isTRUE(ab$box)) {
      # Filled/bordered abstract panel; tcolorbox supplies the inset, so the
      # \list margins give way to the box padding.
      add("\\usepackage{tcolorbox}\\tcbuselibrary{skins,breakable}")
      add("\\renewenvironment{abstract}{%")
      add("  \\begin{tcolorbox}[breakable,boxrule=0.4pt,colback=", ab$background %||% "code_bg",
          ",colframe=rule,arc=1pt,left=12pt,right=12pt,top=9pt,bottom=9pt]%")
      add("  ", body_fmt)
      add("  ", lab_tex)
      add("}{\\end{tcolorbox}}")
    } else {
      add("\\renewenvironment{abstract}{%")
      add("  \\list{}{\\leftmargin=", aind, "\\rightmargin=", aind, "}\\item\\relax")
      add("  ", body_fmt)
      add("  ", lab_tex)
      add("}{\\endlist}")
    }
  }

  add("\\preauthor{\\begin{", align_env, "}\\large\\color{", ti$byline$color %||% "muted", "}}")
  add("\\postauthor{\\end{", align_env, "}}")
  add("\\predate{\\begin{", align_env, "}\\color{", ti$date$color %||% "muted", "}}")
  add("\\postdate{\\end{", align_env, "}}")

  if (isTRUE(ty$microtype)) add("\\usepackage{microtype}")
  add("\\usepackage{booktabs}")
  add("\\renewcommand{\\arraystretch}{", s$table$row_stretch, "}")
  add("\\setlength{\\parindent}{", dd_len("indent", s$paragraph$indent, "none"), "}")
  add("\\setlength{\\parskip}{", dd_len("space", s$paragraph$spacing, "sm"), "}")
  add("\\linespread{", ty$line_height, "}")

  # --- Code + reference spacing (unconditional; strict improvements) ---------
  # Listings keep single leading regardless of the body line_height, so a
  # loosely-leaded style (essay/journal) does not double-space its code.
  add("\\AtBeginEnvironment{Highlighting}{\\linespread{1}\\selectfont}")
  add("\\AtBeginEnvironment{verbatim}{\\linespread{1}\\selectfont}")
  add("\\ifdef{\\Verbatim}{\\AtBeginEnvironment{Verbatim}{\\linespread{1}\\selectfont}}{}")
  # Pandoc's CSL reference list separated entries by a full blank line, which
  # reads as an enormous gap; tighten it to an even, modest space. Guarded so
  # it is inert when a document has no bibliography.
  add("\\AtBeginDocument{\\ifcsname CSLReferences\\endcsname",
      "\\AtBeginEnvironment{CSLReferences}{\\setlength{\\parskip}{0.3\\baselineskip}\\setlength{\\itemsep}{0pt}}\\fi}")

  # Wrap long code lines so listings never overflow the measure (especially the
  # narrow two-column body in nature). fvextra augments pandoc's fancyvrb.
  add("\\usepackage{fvextra}")
  add("\\fvset{breaklines=true,breakanywhere=true,breaksymbolleft={}}")

  # --- Code panel: tint / border behind code blocks -------------------------
  # tcolorbox's \tcolorboxenvironment wraps an existing environment; guarded by
  # \ifcsname so it fires only for the code env a document actually uses
  # (Shaded when highlighted, verbatim/Verbatim when plain). code_bg role must
  # be defined by the style when code.background points at it.
  cb <- s$code
  if (!is.null(cb$background) || isTRUE(cb$border)) {
    add("\\usepackage{tcolorbox}\\tcbuselibrary{skins,breakable}")
    cbg   <- if (!is.null(cb$background)) cb$background else "white"
    crule <- if (isTRUE(cb$border)) "0.5pt" else "0pt"
    copts <- paste0("breakable,boxrule=", crule, ",colback=", cbg,
                    ",colframe=rule,arc=1pt,boxsep=1pt,left=6pt,right=6pt,top=5pt,bottom=5pt")
    for (env in c("Shaded", "verbatim", "Verbatim")) {
      add("\\AtBeginDocument{\\ifcsname ", env, "\\endcsname\\tcolorboxenvironment{",
          env, "}{", copts, "}\\fi}")
    }
  }

  # --- Figure and table captions --------------------------------------------
  # Ten styles declare figure.caption.* / table.caption.*; none of it rendered.
  # The caption package owns all of this cleanly. Caption REPOSITIONING (above
  # vs below the float) is deliberately not here -- it needs floatrow, which
  # interacts badly with two-column floats, so it is a separate batch.
  fc <- s$figure$caption
  if (length(fc)) {
    add("\\usepackage{caption}")
    # caption's font= runs a KEYWORD parser over its value, so arbitrary LaTeX
    # cannot be passed there in any form -- neither mixed with keywords nor
    # alone. It expands the first token inside \\csname and fails with
    # "Missing \\endcsname inserted". \\DeclareCaptionFont is the package's
    # documented escape hatch for exactly this: name a bundle of raw
    # declarations, then refer to it by that name.
    fnt <- character()
    if (!is.null(fc$color)) fnt <- c(fnt, paste0("\\color{", fc$color, "}"))
    if (!is.null(fc$size)) {
      csz <- round(base * as.numeric(fc$size), 1)
      fnt <- c(fnt, paste0("\\fontsize{", csz, "}{", round(csz * 1.2, 1), "}\\selectfont"))
    }
    if (identical(fc$family, "heading")) fnt <- c(fnt, head_cmd)
    if (identical(fc$family, "mono"))    fnt <- c(fnt, "\\ttfamily")
    opts <- character()
    if (length(fnt)) {
      add("\\DeclareCaptionFont{ddcapfont}{", paste(fnt, collapse = ""), "}")
      opts <- c(opts, "font=ddcapfont")
    }
    lab <- switch(fc$label_style %||% "",
      bold = "labelfont=bf", italic = "labelfont=it", smallcaps = "labelfont=sc",
      none = "labelformat=empty", "")
    if (nzchar(lab)) opts <- c(opts, lab)
    if (identical(fc$align, "center")) opts <- c(opts, "justification=centering")
    if (identical(fc$align, "left"))   opts <- c(opts, "justification=raggedright")
    if (length(opts)) add("\\captionsetup[figure]{", paste(opts, collapse = ","), "}")
  }

  # --- Quote block ----------------------------------------------------------
  # quote.{indent,style,color,rule} were declared by six shipped styles and
  # rendered by none of them -- the tokens validated, then were silently
  # dropped. Everything here is gated on a token actually being set, so a
  # style that says nothing about quotes keeps LaTeX's stock quote exactly.
  q <- s$quote
  if (length(q)) {
    qpre <- paste0(
      if (!is.null(q$color)) paste0("\\color{", q$color, "}") else "",
      if (identical(q$style, "italic")) "\\itshape" else "")
    if (nzchar(qpre)) add("\\AtBeginEnvironment{quote}{", qpre, "}")
    # A left accent bar needs a frame, not an indent. tcolorbox's blanker
    # skin draws nothing but the single borderline, so the quote keeps its
    # ordinary look and gains only the rule.
    if (isTRUE(q$rule) || !is.null(q$indent)) {
      qind <- dd_len("indent", q$indent, "md")
      if (isTRUE(q$rule)) {
        add("\\usepackage{tcolorbox}\\tcbuselibrary{skins,breakable}")
        add("\\AtBeginDocument{\\tcolorboxenvironment{quote}{blanker,breakable,",
            "left=", qind, ",right=0pt,top=2pt,bottom=2pt,",
            "borderline west={2pt}{0pt}{accent}}}")
      } else {
        add("\\AtBeginDocument{\\renewenvironment{quote}",
            "{\\list{}{\\setlength{\\leftmargin}{", qind, "}",
            "\\setlength{\\rightmargin}{", qind, "}}\\item\\relax}",
            "{\\endlist}}")
      }
    }
  }

  add("\\usepackage{fancyhdr}\\pagestyle{fancy}\\fancyhf{}")
  add("\\renewcommand{\\headrulewidth}{", if (isTRUE(s$header_footer$header$rule)) "0.4pt" else "0pt", "}")
  add("\\renewcommand{\\footrulewidth}{", if (isTRUE(s$header_footer$footer$rule)) "0.4pt" else "0pt", "}")
  slot <- c(left = "L", center = "C", right = "R")
  # LaTeX's default \headheight (12pt) is too small for a populated running
  # head, and fancyhdr warns and overprints. Only widen it when a header is
  # actually declared, so header-less styles keep their existing text block;
  # \topmargin absorbs the extra so the body does not shift down.
  hdr_on <- any(vapply(names(slot), function(p) {
    !identical(s$header_footer$header[[p]] %||% "none", "none")
  }, logical(1)))
  if (hdr_on) {
    add("\\setlength{\\headheight}{14pt}\\addtolength{\\topmargin}{-2pt}")
  }
  # titling's \thetitle/\theauthor stay live outside \maketitle. \rightmark is
  # the article-class running mark \sectionmark updates (article has no
  # \leftmark tracking); "surname" has no name-parsing yet, so it falls back
  # to the full \theauthor like "author" until that's worth splitting out.
  hf_content <- function(what) switch(what,
    page = "\\thepage",
    title = ,
    runningtitle = "\\ifcsname ddrtitle\\endcsname\\ddrtitle\\else\\thetitle\\fi",
    author = ,
    surname = "\\theauthor",
    section = "\\rightmark",
    "\\thepage")
  for (pos in names(slot)) {
    hwhat <- s$header_footer$header[[pos]] %||% "none"
    if (!identical(hwhat, "none")) {
      add("\\fancyhead[", slot[[pos]], "]{\\small\\color{muted}", hf_content(hwhat), "}")
    }
    fwhat <- s$header_footer$footer[[pos]] %||% "none"
    if (!identical(fwhat, "none")) {
      add("\\fancyfoot[", slot[[pos]], "]{\\small\\color{muted}", hf_content(fwhat), "}")
    }
  }
  # article's \maketitle forces \thispagestyle{plain} on the opening page, which
  # drops the fancy running head there — so a header shows on page 2+ but never
  # on page 1. When first_page: header, redefine the plain style to mirror the
  # fancy head/foot so the running head also appears on the first page.
  if (identical(s$header_footer$first_page %||% "plain", "header") && hdr_on) {
    fp <- "\\fancyhf{}"
    for (pos in names(slot)) {
      hwhat <- s$header_footer$header[[pos]] %||% "none"
      if (!identical(hwhat, "none"))
        fp <- paste0(fp, "\\fancyhead[", slot[[pos]], "]{\\small\\color{muted}",
                     hf_content(hwhat), "}")
      fwhat <- s$header_footer$footer[[pos]] %||% "none"
      if (!identical(fwhat, "none"))
        fp <- paste0(fp, "\\fancyfoot[", slot[[pos]], "]{\\small\\color{muted}",
                     hf_content(fwhat), "}")
    }
    fp <- paste0(fp,
      "\\renewcommand{\\headrulewidth}{",
      if (isTRUE(s$header_footer$header$rule)) "0.4pt" else "0pt", "}",
      "\\renewcommand{\\footrulewidth}{",
      if (isTRUE(s$header_footer$footer$rule)) "0.4pt" else "0pt", "}")
    add("\\fancypagestyle{plain}{", fp, "}")
  }
  paste(unlist(L), collapse = "\n")
}

# page.margin is a 3-step scale (0.75/1/1.35in), but real page designs are
# asymmetric — a wider head than foot, wider sides than top. page.margins.*
# (inches) overrides it per side; any side left unset falls back to the
# page.margin shorthand, so a style can adjust one edge without restating all
# four. geometry's inner/outer are binding edges only under twoside; otherwise
# they are plainly left/right, which is how they're mapped here.
dd_geometry_opts <- function(s) {
  shorthand <- dd_len("margin", s$page$margin, "normal")
  mg <- s$page$margins
  inch <- function(x) if (is.null(x)) NULL else paste0(x, "in")
  top <- inch(mg$top); bottom <- inch(mg$bottom)
  inner <- inch(mg$inner); outer <- inch(mg$outer)

  if (is.null(top) && is.null(bottom) && is.null(inner) && is.null(outer)) {
    return(paste0("margin=", shorthand))
  }

  top <- top %||% shorthand; bottom <- bottom %||% shorthand
  inner <- inner %||% shorthand; outer <- outer %||% shorthand
  twoside <- isTRUE(s$page$twoside)
  c(paste0("top=", top), paste0("bottom=", bottom),
    if (twoside) c(paste0("inner=", inner), paste0("outer=", outer))
    else c(paste0("left=", inner), paste0("right=", outer)),
    if (twoside) "twoside")
}

dd_geometry <- function(s) {
  args <- as.vector(rbind("-V", paste0("geometry:", dd_geometry_opts(s))))
  # geometry's twoside mirrors the margins, but only the class option makes
  # LaTeX alternate the running heads to match.
  if (isTRUE(s$page$twoside)) args <- c(args, "-V", "classoption=twoside")
  args
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

  pargs <- c(dd_geometry(s),
             "-V", paste0("papersize=", s$page$papersize),
             "-V", paste0("fontsize=", fontsize),
             "-V", "colorlinks=true",
             "-V", paste0("linkcolor=", s$links$color %||% "accent"),
             "-V", paste0("urlcolor=", s$links$color %||% "accent"))

  hl <- s$code$highlight %||% "tango"
  # BOTH old spellings are deprecated: --no-highlight and --highlight-style are
  # replaced by --syntax-highlighting=<none|style>. --highlight-style is the
  # branch 11 of the 12 styles take, so fixing only the "none" case left the
  # warning on almost every render.
  if (rmarkdown::pandoc_available("3.2")) {
    pargs <- c(pargs, paste0("--syntax-highlighting=", hl))
  } else {
    pargs <- c(pargs, if (identical(hl, "none")) "--no-highlight" else c("--highlight-style", hl))
  }

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
