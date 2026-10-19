# Draft markup: the features of a working draft printed to be read and marked
# up by hand (the `review` style). Every one is off by default and gated on a
# markup.* token, so no publication style is touched.
#
#   markup.line_numbers       lineno, every nth line, outer margin
#   markup.paragraph_numbers  markup.lua, a marginnote in the inner margin
#   markup.flags              markup.lua, [[TAG]] to an outer-margin tag
#   markup.cite_keys          markup.lua, the key after each citation
#   markup.changebars         markup.lua + changebar, against a reference text
#   markup.map                headings.lua, a map of the argument
#   markup.claim_check        headings.lua, [[LABEL?]] beside label headings
#   markup.floats             tables.lua and float, nothing moves when false

dd_markup_keys <- c("line_numbers", "paragraph_numbers", "flags", "flag_color",
                    "cite_keys", "map", "claim_check", "changebars", "floats")

# pdf(markup = list(...)) overrides the style's markup.* tokens for one
# render, so a single printout can drop line numbers without a second style.
dd_apply_markup <- function(s, markup) {
  if (!length(markup)) return(s)
  markup <- as.list(markup)
  bad <- setdiff(names(markup), dd_markup_keys)
  if (is.null(names(markup)) || length(bad)) {
    stop("markup = takes named markup.* tokens: ", paste(dd_markup_keys, collapse = ", "),
         if (length(bad)) paste0(". Unknown: ", paste(bad, collapse = ", ")), call. = FALSE)
  }
  s$markup <- utils::modifyList(s$markup %||% list(), markup)
  s
}

# Margin notes (paragraph numbers, flags) need room in the margins. geometry
# takes one marginparwidth for both sides; a note in the narrower inner margin
# is set flush toward the text, so the part that matters stays on the page.
dd_markup_notes <- function(s) {
  m <- s$markup
  isTRUE(m$paragraph_numbers) || isTRUE(m$flags) || isTRUE(m$claim_check)
}

dd_markup_geometry <- function(s, outer_in) {
  if (!dd_markup_notes(s)) return(character())
  sep <- 0.35
  width <- max(0.5, round(outer_in - sep - 0.3, 2))
  c(paste0("marginparsep=", sep, "in"), paste0("marginparwidth=", width, "in"))
}

dd_markup_preamble <- function(s) {
  m <- s$markup %||% list()
  L <- character()
  # Two-sided: notes, numbers and bars sit in the OUTER margin, which
  # alternates. One-sided: the outer margin is always the right one, and
  # paragraph numbers always sit at the left.
  twoside <- isTRUE(s$page$twoside)
  ln <- as.integer(m$line_numbers %||% 0L)
  if (ln > 0L) {
    # switch: outer margin under twoside. pagewise: 5, 10, 15 on every page,
    # so "p. 7 l. 15" names a line without counting from the start.
    # By command, not package option: fvextra (code highlighting) may already
    # have loaded lineno, and a second load with options is a LaTeX error.
    L <- c(L, "\\usepackage{lineno}",
           paste0("\\modulolinenumbers[", ln, "]"),
           "\\renewcommand{\\linenumberfont}{\\normalfont\\fontsize{7}{8}\\selectfont\\color{muted}}",
           "\\setlength{\\linenumbersep}{1.1em}",
           paste0("\\AtBeginDocument{", if (twoside) "\\switchlinenumbers" else "\\rightlinenumbers*",
                  "\\pagewiselinenumbers}"))
  }
  if (dd_markup_notes(s)) {
    # \marginpar, not marginnote: lineno re-sets every numbered paragraph,
    # which leaves marginnote's notes at the wrong height; lineno handles
    # \marginpar itself. The optional argument is the note as set in the LEFT
    # margin (flush right, toward the text), the other the note as set in the
    # right. Inside a box or a table cell a marginpar is illegal, so there the
    # note prints inline instead. \\leavevmode: a note at the head of a
    # paragraph must start the paragraph, or it is set beside the line above.
    L <- c(L,
      paste0("\\colorlet{ddflag}{", m$flag_color %||% "accent", "}"),
      "\\newcommand{\\ddnote}[2][0pt]{\\ifinner\\else\\leavevmode\\marginpar[\\raggedleft\\ddnotebox{#1}{#2}]{\\raggedright\\ddnotebox{#1}{#2}}\\fi}",
      "\\newcommand{\\ddnotebox}[2]{\\raisebox{#1}[0pt][0pt]{\\ddlabelfont\\footnotesize #2}}",
      # Paragraph numbers go in the INNER margin. \\reversemarginpar cannot
      # put them there: LaTeX reads it when the page is shipped, not where the
      # note is written. So the number is set beside the first line directly,
      # left or right as changepage reports the page odd or even (it settles
      # on the second pass, which every render makes).
      if (twoside) "\\usepackage{changepage}\\strictpagecheck",
      "\\newlength{\\ddparsep}\\setlength{\\ddparsep}{1.6em}",
      # \\ddparnumbox sets the number beside the start of the line it is
      # called at. \\ddparnum guards against boxes and table cells, where a
      # paragraph number does not belong; \\ddparnumhead is for a run-in
      # heading, which titlesec sets in a box at the start of the line.
      if (twoside) {
        paste0("\\newcommand{\\ddparnumbox}[1]{\\checkoddpage",
               "\\def\\ddpn{{\\normalfont\\ddlabelfont\\footnotesize\\color{muted}\\P\\thinspace#1}}",
               "\\ifoddpage\\llap{\\ddpn\\hspace{\\ddparsep}}",
               "\\else\\rlap{\\hspace{\\linewidth}\\hspace{\\ddparsep}\\ddpn}\\fi}")
      } else {
        paste0("\\newcommand{\\ddparnumbox}[1]{",
               "\\llap{{\\normalfont\\ddlabelfont\\footnotesize\\color{muted}\\P\\thinspace#1}\\hspace{\\ddparsep}}}")
      },
      "\\newcommand{\\ddparnum}[1]{\\ifinner\\else\\leavevmode\\ddparnumbox{#1}\\fi}",
      "\\newcommand{\\ddparnumhead}[1]{\\ddparnumbox{#1}}",
      "\\newcommand{\\ddflag}[1]{\\ifinner{\\ddlabelfont\\footnotesize\\color{ddflag}[#1]}\\else\\ddnote{\\color{ddflag}\\textbf{#1}}\\fi}",
      "\\newcommand{\\ddflagtext}[1]{\\textcolor{ddflag}{#1}}",
      # A heading's flag rides on the paragraph under it, raised to the
      # heading's line.
      "\\newcommand{\\ddheadflag}[1]{\\ddnote[1.35\\baselineskip]{\\color{ddflag}\\textbf{#1}}}")
  }
  if (isTRUE(m$cite_keys)) {
    L <- c(L, "\\newcommand{\\ddcitekey}[1]{{\\ttfamily\\fontsize{6.5}{7.5}\\selectfont\\color{muted}\\,[#1]}}")
  }
  if (identical(m$floats, FALSE)) {
    # Nothing floats: a figure is set where it is written. tables.lua keeps
    # every table a longtable for the same reason. Loaded before changebar,
    # which patches float's environments.
    L <- c(L, "\\usepackage{float}", "\\makeatletter\\def\\fps@figure{H}\\makeatother")
  }
  if (isTRUE(m$changebars)) {
    # outerbars: the bar sits between the text and the line numbers, on the
    # side where the notes are written.
    L <- c(L, paste0("\\usepackage[xetex,", if (twoside) "outerbars" else "rightbars", ",color]{changebar}"),
           "\\setlength{\\changebarsep}{0.45em}\\setlength{\\changebarwidth}{1.5pt}",
           "\\cbcolor{accent}")
  }
  if (as.integer(m$map %||% 0L) > 0L) {
    L <- c(L, "\\usepackage{lastpage}\\usepackage{refcount}",
      "\\newcommand{\\ddmapopen}{\\par\\addvspace{0.6em}\\noindent{\\ddlabelfont\\footnotesize\\color{accent}MAP OF THE ARGUMENT\\par}\\nopagebreak\\vspace{0.15em}}",
      "\\newcommand{\\ddmapclose}{\\par\\addvspace{1.2em}}",
      "\\newcommand{\\ddmaphd}[1]{{\\ddlabelfont\\bfseries #1}}",
      "\\newcommand{\\ddmapsub}[1]{\\hspace{1em}{\\color{muted}#1}}",
      "\\newcommand{\\ddmaptotal}[1]{{\\color{muted}#1}}")
  }
  paste(L, collapse = "\n")
}

# The Lua filters and their metadata. markup.lua runs first: it compares
# paragraphs for changebars before anything is added to them.
dd_markup_args <- function(s) {
  m <- s$markup %||% list()
  args <- character()
  flag <- function(x) if (isTRUE(x)) "true" else "false"
  if (isTRUE(m$paragraph_numbers) || isTRUE(m$flags) || isTRUE(m$cite_keys) ||
      isTRUE(m$changebars)) {
    args <- c(args, "--lua-filter", dd_pkg_file("engine", "markup.lua"),
              "--metadata", paste0("dd-markup-parnum=", flag(m$paragraph_numbers)),
              "--metadata", paste0("dd-markup-flags=", flag(m$flags)),
              "--metadata", paste0("dd-markup-citekeys=", flag(m$cite_keys)),
              "--metadata", paste0("dd-markup-changebars=", flag(m$changebars)),
              "--metadata", paste0("dd-runin-levels=",
                                   paste(sub("^h", "", unlist(s$headings$run_in)), collapse = ",")))
  }
  depth <- as.integer(m$map %||% 0L)
  chars <- s$header_footer$section_chars
  if (depth > 0L || isTRUE(m$claim_check) || !is.null(chars)) {
    args <- c(args, "--lua-filter", dd_pkg_file("engine", "headings.lua"),
              "--metadata", paste0("dd-map-depth=", depth),
              "--metadata", paste0("dd-claim-check=", flag(m$claim_check)),
              "--metadata", paste0("dd-section-chars=", chars %||% 0L),
              "--metadata", paste0("dd-number-sections=", flag(s$headings$number_sections)))
  }
  args
}

# --- Per-render stamps: version, date, change reference ----------------------
# These depend on the document being rendered, which pdf() does not know when
# the format is built. rmarkdown's pre-processor does: it runs per render with
# the input file in hand.

# The source beside rmarkdown's intermediate file (foo.knit.md -> foo.Rmd).
dd_source_file <- function(input_file) {
  stem <- sub("\\.(knit|utf8)\\.md$", "", input_file)
  cands <- c(paste0(stem, c(".Rmd", ".rmd", ".qmd", ".md", ".markdown")), input_file)
  hit <- cands[file.exists(cands)]
  if (length(hit)) normalizePath(hit[[1]], winslash = "/") else input_file
}

dd_git <- function(dir, args) {
  out <- tryCatch(suppressWarnings(system2("git", c("-C", shQuote(dir), args),
                                           stdout = TRUE, stderr = FALSE)),
                  error = function(e) structure(character(), status = 1L))
  if (!is.null(attr(out, "status")) && attr(out, "status") != 0L) return(character())
  out
}

# Short hash of HEAD, with "+" when the file has uncommitted changes. Empty
# outside a repository, or without git.
dd_git_version <- function(src) {
  dir <- dirname(src)
  h <- dd_git(dir, c("rev-parse", "--short", "HEAD"))
  if (!length(h)) return("")
  dirty <- dd_git(dir, c("status", "--porcelain", "--", shQuote(basename(src))))
  paste0(h[[1]], if (length(dirty)) "+" else "")
}

# The reference text changebars compare against, as a file path, or NULL.
# `since`: a file path; a git revision (tag, branch, commit); or TRUE / "tag"
# for the latest tag.
dd_changes_ref <- function(src, since) {
  if (is.null(since) || isFALSE(since)) return(NULL)
  dir <- dirname(src)
  if (isTRUE(since) || identical(since, "tag")) {
    tag <- dd_git(dir, c("describe", "--tags", "--abbrev=0"))
    if (!length(tag)) {
      message("docdesigner: no git tag to compare against, so no changebars. ",
              "Tag a version, or set pdf(changes_since = ).")
      return(NULL)
    }
    since <- tag[[1]]
  }
  # A path, as given or relative to the document.
  for (f in c(since, file.path(dir, since))) {
    if (file.exists(f) && !dir.exists(f)) return(normalizePath(f, winslash = "/"))
  }
  txt <- dd_git(dir, c("show", shQuote(paste0(since, ":./", basename(src)))))
  if (!length(txt)) {
    warning("docdesigner: changes_since = \"", since, "\" is neither a file nor a git ",
            "revision holding ", basename(src), "; no changebars drawn.", call. = FALSE)
    return(NULL)
  }
  ref <- tempfile("dd-changes-ref-", fileext = ".md")
  writeLines(txt, ref, useBytes = TRUE)
  ref
}

dd_tex_text <- function(x) {
  x <- gsub("\\", "\\textbackslash{}", x, fixed = TRUE)
  gsub("([#$%&_{}])", "\\\\\\1", x)
}

dd_pre_processor <- function(s, version, changes_since) {
  hf <- unlist(s$header_footer[c("header", "footer")])
  stamped <- "stamp" %in% hf || isTRUE(s$title$warning$auto)
  function(metadata, input_file, runtime, knit_meta, files_dir, output_dir) {
    src <- dd_source_file(input_file)
    v <- if (is.character(version)) version
         else if (isFALSE(version) || !(stamped || isTRUE(version))) ""
         else dd_git_version(src)
    date <- format(Sys.Date(), "%Y-%m-%d")
    hdr <- tempfile("dd-stamp-", fileext = ".tex")
    writeLines(c(paste0("\\def\\ddversion{", dd_tex_text(v), "}"),
                 paste0("\\def\\ddstampdate{", date, "}")), hdr)
    args <- c("--include-in-header", hdr)
    w <- metadata$warning
    if (identical(w, "auto") || (is.null(w) && isTRUE(s$title$warning$auto))) {
      line <- paste(c("Review draft", if (nzchar(v)) paste0("v", v), date, "do not circulate"),
                    collapse = " \u00b7 ")
      args <- c(args, "-V", paste0("warning=", dd_tex_text(line)))
    }
    since <- changes_since %||% (if (isTRUE(s$markup$changebars)) "tag")
    if (isTRUE(s$markup$changebars) || !is.null(changes_since)) {
      ref <- dd_changes_ref(src, since)
      if (!is.null(ref)) args <- c(args, "--metadata", paste0("dd-changes-ref=", ref))
    }
    args
  }
}
