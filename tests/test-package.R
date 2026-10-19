library(docdesigner)

# --- Engine: style discovery -------------------------------------------------
styles <- designer_styles()
stopifnot(is.data.frame(styles))
stopifnot(all(c("style", "label", "description", "set") %in% names(styles)))
stopifnot(all(c("minimal", "modern", "demography", "policy", "nature") %in% styles$style))

# --- Engine: sets ------------------------------------------------------------
sets <- designer_sets()
stopifnot(is.data.frame(sets))
stopifnot(all(c("academic", "public") %in% sets$set))

# --- Engine: resolved tokens (defaults + style, inheritance applied) ---------
modern_tokens <- designer_style("modern")
stopifnot(is.list(modern_tokens))
stopifnot(identical(modern_tokens$id, "modern"))
stopifnot(!is.null(modern_tokens$color$accent))
stopifnot(!is.null(modern_tokens$typography$body))

# An unknown style fails with a clear message.
unknown <- tryCatch(designer_style("does-not-exist"),
                    error = function(e) conditionMessage(e))
stopifnot(grepl("Unknown docdesigner style", unknown))

# `inherits` is a resolution instruction, not a token: it must not survive.
stopifnot(is.null(modern_tokens$inherits))

# Flat files expand: a dotted key never survives as a literal name.
stopifnot(!any(grepl("\\.", names(modern_tokens))))
# Schema defaults reach the resolved spec even when the style is silent.
# These must name tokens `modern` does NOT declare. That is a live hazard: the
# moment a style starts declaring one, the assertion keeps passing but stops
# testing defaults at all. h3.scale was exactly that case -- the thin v1
# minimal (now modern) left it unset, the rebuilt one sets 0.95, and this line failed when
# the rebuilt styles were promoted on 2026-08-26. h4.scale (still unset,
# schema default 1) replaces it; h3.scale moves below to test precedence.
stopifnot(identical(modern_tokens$typography$mono, "Fira Code"))
stopifnot(identical(modern_tokens$headings$h4$scale, 1.00))
stopifnot(identical(modern_tokens$table$style, "booktabs"))

# ...and a value the style DOES declare overrides the schema default. h3.scale
# is declared 0.95 against a default of 1.00, so this fails if declaration
# ever stops winning.
stopifnot(identical(modern_tokens$headings$h3$scale, 0.95))
stopifnot(identical(modern_tokens$page$margin, "normal"))

# Every shipped style resolves, and its fonts are all findable.
for (s in designer_styles()$style) {
  spec <- designer_style(s)
  reg <- docdesigner:::dd_font_registry(spec)
  dirs <- docdesigner:::dd_font_dirs(spec)
  for (role in c("body", "heading", "mono")) {
    docdesigner:::dd_font_family_dir(spec$typography[[role]], reg, dirs)
  }
  invisible(docdesigner:::dd_preamble(spec))
}

# A style id need not match its folder name; resolution keys on the id.
idx <- docdesigner:::dd_style_index()
stopifnot(all(idx$style %in% designer_styles()$style))

# --- html(): body-only stripping ---------------------------------------------
# dd_drop_script_style() must remove <script>/<style> blocks whole. The original
# implementation deleted only the tag lines, leaving the JavaScript between them
# as bare text -- which a CMS renders as visible body copy. Regression pinned
# 2026-08-26.
stripped <- docdesigner:::dd_drop_script_style(c(
  "<p>keep me</p>",
  "<script>",
  "function leaked() { return 1; }",
  "</script>",
  "<style>",
  ".leaked { color: red; }",
  "</style>",
  '<script src="x.js"></script>',
  "<p>keep me too</p>"))
stopifnot(!any(grepl("leaked", stripped)))
stopifnot(!any(grepl("<script|<style", stripped)))
stopifnot(sum(grepl("keep me", stripped)) == 2L)

# --- Colour coercion ---------------------------------------------------------
stopifnot(identical(docdesigner:::dd_hex("#b21f24"), "B21F24"))
stopifnot(identical(docdesigner:::dd_hex("006A71"), "006A71"))
bad <- tryCatch(docdesigner:::dd_hex("nope"), error = function(e) conditionMessage(e))
stopifnot(grepl("hex", bad))

# --- Scaffolding seeds raw tokens, not the resolved spec ---------------------
scratch <- tempfile("docdesigner-scaffold-")
dir.create(scratch)

# complete = FALSE: only the source style's declared tokens.
lean_dir <- designer_new_style("leanstyle", from = "modern", path = scratch,
                               complete = FALSE)
lean <- yaml::read_yaml(file.path(lean_dir, "format.yml"))
stopifnot(identical(lean$id, "leanstyle"))

# The invariant is a set equality: lean holds exactly the tokens the seed
# style declares, no more. Stating it that way is deliberate. This test used
# to name individual tokens modern happened NOT to declare -- first
# typography.line_height, then "no page.* at all" -- and each such assertion
# silently stopped testing anything the moment modern started declaring it.
# Three of them failed together when the rebuilt styles were promoted on
# 2026-08-26. Compared against the seed's own file, this cannot rot.
modern_raw <- yaml::read_yaml(
  file.path(docdesigner:::dd_style_dir("modern"), "format.yml"))
stopifnot(setequal(names(lean), names(modern_raw)))

# ...and the scaffold copies RAW declared tokens rather than freezing the
# resolved spec: modern declares no typography.mono, so the engine's
# "Fira Code" default must not have leaked into the file.
stopifnot(is.null(lean[["typography.mono"]]))
stopifnot(is.null(modern_raw[["typography.mono"]]))

# complete = TRUE: every token, flat, one per line, at column zero.
full_dir <- designer_new_style("fullstyle", from = "modern", path = scratch)
full_lines <- readLines(file.path(full_dir, "format.yml"))
keyed <- grep("^[a-z]", full_lines, value = TRUE)
stopifnot(length(keyed) > 40)
stopifnot(!any(grepl("^\\s+\\S", full_lines)))          # nothing is indented
# Every token is implemented, so the scaffold flags none as ignored.
stopifnot(!any(grepl("NOT YET IMPLEMENTED", full_lines)))
full <- yaml::read_yaml(file.path(full_dir, "format.yml"))
stopifnot(identical(full$id, "fullstyle"))
stopifnot(is.null(full$inherits))                       # never scaffolded
# Types survive the round-trip, and a value the seed declares is carried
# through rather than overwritten by the schema default. Written against
# modern's own file for the reason given above: hardcoding 1.3 and "333333"
# here meant "the schema default", which held only while modern declared
# neither token. The rebuilt modern declares both.
stopifnot(is.numeric(full[["typography.line_height"]]))
stopifnot(identical(full[["typography.line_height"]],
                    modern_raw[["typography.line_height"]]))
stopifnot(isTRUE(full[["headings.number_sections"]]))   # bools stay bools
stopifnot(is.character(full[["color.accent"]]))         # hex stays a string
stopifnot(identical(full[["color.accent"]], modern_raw[["color.accent"]]))
# The scaffold must itself validate.
v <- suppressWarnings(designer_validate_style(file.path(full_dir, "format.yml")))
stopifnot(!any(v$severity == "error"))
unlink(scratch, recursive = TRUE)

# --- Schema and validation ---------------------------------------------------
tok <- designer_tokens()
stopifnot(all(c("key", "type", "allowed", "default", "status") %in% names(tok)))
stopifnot(all(tok$status %in% c("impl", "port", "new", "risk", "deprecated")))
stopifnot("headings.h3.scale" %in% tok$key)             # <h> expanded
stopifnot(identical(tok$default[tok$key == "headings.h1.scale"], "1.35"))

# The status marks must not drift from what dd_preamble() and pdf() actually
# consume. A token marked `new` that the engine reads -- or `impl` that it
# ignores -- makes the whole status system a lie. Pin the implemented set.
consumed <- c(
  "typography.body", "typography.heading", "typography.mono",
  "typography.base_size", "typography.line_height", "typography.mono_scale",
  "typography.microtype",
  "color.accent", "color.text", "color.muted", "color.rule",
  "headings.number_sections",
  "headings.h1.scale", "headings.h2.scale", "headings.h3.scale",
  "headings.h1.weight", "headings.h1.case", "headings.h1.color",
  "headings.h1.space_before", "headings.h1.space_after",
  "headings.h1.rule.position", "headings.h1.rule.weight", "headings.h1.rule.color",
  "title.scale", "title.rule.position", "title.rule.weight", "title.rule.color",
  "title.byline.color", "title.date.color",
  "paragraph.indent", "paragraph.spacing",
  "page.papersize", "page.margin", "page.columns",
  "table.row_stretch", "code.highlight", "links.color",
  "header_footer.footer.right", "header_footer.footer.rule",
  "header_footer.alternate", "header_footer.section_chars", "title.warning.auto",
  "markup.line_numbers", "markup.paragraph_numbers", "markup.flags", "markup.flag_color",
  "markup.cite_keys", "markup.map", "markup.claim_check", "markup.changebars", "markup.floats")
status <- stats::setNames(tok$status, tok$key)
mismarked <- consumed[status[consumed] != "impl"]
if (length(mismarked)) {
  stop("These tokens are read by the engine but are not marked `impl` in ",
       "schema.yml: ", paste(mismarked, collapse = ", "))
}

# Scale lookups.
stopifnot(identical(docdesigner:::dd_len("rule_weight", "hairline"), "0.4pt"))
stopifnot(identical(docdesigner:::dd_len("space", NULL, "sm"), "0.5em"))
bad_step <- tryCatch(docdesigner:::dd_len("space", "enormous"),
                     error = function(e) conditionMessage(e))
stopifnot(grepl("not a step", bad_step))

# Dotted expansion round-trips.
flat <- list("a.b.c" = 1, "a.b.d" = 2, "e" = 3)
nested <- docdesigner:::dd_expand_dotted(flat)
stopifnot(identical(nested$a$b$c, 1), identical(nested$e, 3))
stopifnot(setequal(names(docdesigner:::dd_flatten_dotted(nested)), names(flat)))

# Every shipped style validates without errors.
for (s in designer_styles()$style) {
  v <- suppressWarnings(designer_validate_style(s))
  stopifnot(!any(v$severity == "error"))
}

# A bad style is caught: unknown key, illegal enum, hex where a role belongs.
bad <- tempfile("docdesigner-bad-"); dir.create(bad)
writeLines(c("id: bad", "label: Bad", "nonsense.key: 1",
             "page.columns: 3", "headings.h1.color: \"FF0000\"",
             "typography.body: Comic Sans"),
           file.path(bad, "format.yml"))
v <- suppressWarnings(designer_validate_style(file.path(bad, "format.yml")))
stopifnot(sum(v$severity == "error") >= 4)
stopifnot(any(grepl("unknown token", v$message)))
stopifnot(any(grepl("colour role", v$message)))
unlink(bad, recursive = TRUE)

# No shipped style exceeds the 1.25in margin cap (thesis layouts exempt).
for (s in designer_styles()$style) {
  v <- suppressWarnings(designer_validate_style(s))
  stopifnot(!any(grepl("margin cap", v$message)))
}
wide <- tempfile("docdesigner-wide-"); dir.create(wide)
writeLines(c("id: wide", "label: Wide", "page.margins.inner: 1.5"),
           file.path(wide, "format.yml"))
v <- suppressWarnings(designer_validate_style(file.path(wide, "format.yml")))
stopifnot(any(grepl("margin cap", v$message)))
# A markup style's OUTER margin is a writing workspace and is exempt; its
# other margins are not, and a publication style's outer margin is not.
writeLines(c("id: wide", "label: Wide", "markup.line_numbers: 5",
             "page.margins.outer: 3.0", "page.margins.inner: 1.5"),
           file.path(wide, "format.yml"))
v <- suppressWarnings(designer_validate_style(file.path(wide, "format.yml")))
stopifnot(!any(v$key == "page.margins.outer" & grepl("margin cap", v$message)))
stopifnot(any(v$key == "page.margins.inner" & grepl("margin cap", v$message)))
writeLines(c("id: wide", "label: Wide", "page.margins.outer: 3.0"),
           file.path(wide, "format.yml"))
v <- suppressWarnings(designer_validate_style(file.path(wide, "format.yml")))
stopifnot(any(v$key == "page.margins.outer" & grepl("margin cap", v$message)))
unlink(wide, recursive = TRUE)

# --- Bundled assets are discoverable -----------------------------------------
stopifnot(file.exists(docdesigner:::dd_template()))
stopifnot(dir.exists(docdesigner:::dd_fonts_dir()))
stopifnot(file.exists(docdesigner:::dd_csl()))

# --- Output formats build ----------------------------------------------------
minimal_format <- pdf(style = "minimal")
stopifnot(inherits(minimal_format, "rmarkdown_output_format"))
stopifnot(identical(minimal_format$pandoc$latex_engine, "xelatex"))
# pdf() renders through the package's structural template, not pandoc's.
stopifnot(any(grepl("docdesigner.tex", minimal_format$pandoc$args, fixed = TRUE)))
page_format <- pdf(style = "minimal", title_layout = "page")
stopifnot(any(page_format$pandoc$args == "dd-title-page=true"))

# --- Draft markup (the review style) -----------------------------------------
rv <- designer_style("review")
stopifnot(identical(as.integer(rv$markup$line_numbers), 5L), isTRUE(rv$markup$changebars),
          identical(rv$markup$floats, FALSE), identical(as.integer(rv$markup$map), 2L))
# Off by default: no other shipped style turns any markup on.
for (st in setdiff(designer_styles()$style, "review")) {
  stopifnot(!docdesigner:::dd_markup_on(docdesigner:::dd_flatten_dotted(designer_style(st))))
}
pre_min <- docdesigner:::dd_preamble(designer_style("minimal"))
for (pkg in c("lineno", "changebar", "changepage", "refcount", "{float}")) {
  stopifnot(!grepl(pkg, pre_min, fixed = TRUE))
}
pre_rv <- docdesigner:::dd_preamble(rv)
stopifnot(grepl("\\modulolinenumbers[5]", pre_rv, fixed = TRUE),
          grepl("{changebar}", pre_rv, fixed = TRUE),
          grepl("\\ddsectionhead", pre_rv, fixed = TRUE),
          grepl("\\pageref*{LastPage}", pre_rv, fixed = TRUE))
# float must load before changebar, which patches it.
stopifnot(regexpr("{float}", pre_rv, fixed = TRUE) < regexpr("{changebar}", pre_rv, fixed = TRUE))
# lineno by command, never by package option: fvextra may load it first.
stopifnot(!grepl("]{lineno}", pre_rv, fixed = TRUE))
# review is one-sided: the writing margin, line numbers, flags and bars are
# always on the right, paragraph numbers always on the left.
stopifnot(!isTRUE(rv$page$twoside),
          grepl("\\rightlinenumbers", pre_rv, fixed = TRUE),
          grepl("rightbars", pre_rv, fixed = TRUE),
          !grepl("changepage", pre_rv, fixed = TRUE),
          grepl("\\fancyfoot[R]", pre_rv, fixed = TRUE))
# alternate: under twoside, `right` is the outer edge on every page, and the
# markup follows the outer margin.
two <- rv; two$page$twoside <- TRUE; two$header_footer$alternate <- TRUE
pre_two <- docdesigner:::dd_preamble(two)
stopifnot(grepl("\\fancyfoot[RO,LE]", pre_two, fixed = TRUE),
          grepl("\\switchlinenumbers", pre_two, fixed = TRUE),
          grepl("outerbars", pre_two, fixed = TRUE),
          grepl("changepage", pre_two, fixed = TRUE))
# Margin-note room comes from the outer margin.
stopifnot("marginparwidth=2.35in" %in% docdesigner:::dd_geometry_opts(rv))
# pdf(markup = ) overrides one render; an unknown key is caught.
off <- docdesigner:::dd_apply_markup(rv, list(line_numbers = 0))
stopifnot(!grepl("lineno", docdesigner:::dd_preamble(off), fixed = TRUE))
bad_markup <- tryCatch(pdf(style = "review", markup = list(nonsense = 1)),
                       error = function(e) conditionMessage(e))
stopifnot(grepl("Unknown: nonsense", bad_markup))
review_format <- pdf(style = "review")
stopifnot(any(grepl("markup.lua", review_format$pandoc$args, fixed = TRUE)),
          any(grepl("headings.lua", review_format$pandoc$args, fixed = TRUE)),
          any(review_format$pandoc$args == "dd-tables-float=false"),
          is.function(review_format$pre_processor))
stopifnot(!any(grepl("markup.lua", minimal_format$pandoc$args, fixed = TRUE)))
# Version and change reference degrade quietly outside a repository.
stopifnot(identical(docdesigner:::dd_git_version(file.path(tempdir(), "x.Rmd")), ""))
ref_file <- tempfile(fileext = ".md"); writeLines("Old text.", ref_file)
stopifnot(identical(docdesigner:::dd_changes_ref(file.path(tempdir(), "x.Rmd"), ref_file),
                    normalizePath(ref_file, winslash = "/")))
stopifnot(is.null(suppressMessages(docdesigner:::dd_changes_ref(file.path(tempdir(), "x.Rmd"), "tag"))))
stopifnot(identical(docdesigner:::dd_tex_text("a_b & 50%"), "a\\_b \\& 50\\%"))
stopifnot(identical(docdesigner:::dd_source_file(file.path(tempdir(), "nope.knit.md")),
                    file.path(tempdir(), "nope.knit.md")))

# The filters, through pandoc itself when it is available (no LaTeX needed).
if (rmarkdown::pandoc_available("3.1.8")) {
  run_filter <- function(md, filter, meta) {
    inp <- tempfile(fileext = ".md"); writeLines(md, inp)
    args <- c(inp, "-t", "latex", "--lua-filter", docdesigner:::dd_pkg_file("engine", filter),
              as.vector(rbind("--metadata", meta)))
    paste(system2(rmarkdown::pandoc_exec(), args, stdout = TRUE), collapse = "\n")
  }
  ref <- tempfile(fileext = ".Rmd")
  writeLines(c("```{r setup, include=FALSE}", "x <- 1", "```", "",
               "An unchanged paragraph, cited [@key2020].", "",
               "A paragraph about to change.", "", "```{r}", "y <- 2", "```"), ref)
  out <- run_filter(c("An unchanged paragraph, cited [@key2020].", "",
                      "A paragraph now changed. [[TODO: check this]]", "",
                      "Bare tag here [[CITE]], then text."),
                    "markup.lua",
                    c("dd-markup-parnum=true", "dd-markup-flags=true", "dd-markup-citekeys=true",
                      "dd-markup-changebars=true", paste0("dd-changes-ref=", ref)))
  stopifnot(grepl("\\ddparnum{1}", out, fixed = TRUE), grepl("\\ddparnum{3}", out, fixed = TRUE),
            grepl("\\ddflag{TODO}\\ddflagtext{check this}", out, fixed = TRUE),
            grepl("here\\ddflag{CITE},", out, fixed = TRUE),          # no space before the comma
            grepl("\\ddcitekey{\\detokenize{key2020}}", out, fixed = TRUE))
  # Only the changed and the new paragraphs carry changebars: the reference's
  # chunks are skipped, and its citation is ignored in the comparison.
  stopifnot(lengths(regmatches(out, gregexpr("\\cbstart", out, fixed = TRUE))) == 2L,
            !grepl("\\cbstart{}\\ddparnum{1}", out, fixed = TRUE))
  # Text that is not a known tag is left alone.
  lit <- run_filter("Keep [[not a tag]] as is.", "markup.lua", "dd-markup-flags=true")
  stopifnot(grepl("{[}{[}not a tag{]}{]}", lit, fixed = TRUE) || grepl("[[not a tag]]", lit, fixed = TRUE))

  out <- run_filter(c("# Introduction", "", "Words here.", "",
                      "# Estimates move with the convention", "", "## A sub claim that holds", "",
                      "More words in this part.", "", "# References {-}", "", "Refs."),
                    "headings.lua",
                    c("dd-map-depth=2", "dd-claim-check=true", "dd-section-chars=20",
                      "dd-number-sections=true"))
  stopifnot(grepl("MAP|ddmapopen", out),
            grepl("1 & Introduction & 2 & \\pageref{introduction}", out, fixed = TRUE),
            grepl("\\ddmapsub{2.1\\quad A sub claim that holds}", out, fixed = TRUE),
            grepl("\\ddheadflag{LABEL?}Words", out, fixed = TRUE),     # a label is flagged
            !grepl("\\ddheadflag{LABEL?}More", out, fixed = TRUE),     # a claim is not
            grepl("\\ddsectitle{2}{2\\enspace Estimates move with\u2026}", out, fixed = TRUE),
            grepl("\\ddsecanchor{3}", out, fixed = TRUE),
            !grepl("References &", out, fixed = TRUE))                    # apparatus is not mapped
}

html_format <- html()
stopifnot(inherits(html_format, "rmarkdown_output_format"))


# --- Local gallery -----------------------------------------------------------
gallery <- designer_gallery(output_dir = tempfile("docdesigner-gallery-"),
                            open = FALSE)
stopifnot(file.exists(gallery))

# --- Specimens ---------------------------------------------------------------
# Do not render here: that needs xelatex, and the test suite must run without
# a LaTeX installation. Check only the pieces that do not shell out.
stopifnot(file.exists(docdesigner:::dd_specimen()))
bad_style <- tryCatch(designer_specimens(styles = "no-such-style"),
                      error = function(e) conditionMessage(e))
stopifnot(grepl("Unknown style", bad_style))
stopifnot(identical(docdesigner:::dd_error_digest("a\n\nb\nc"), "a / b / c"))
stopifnot(identical(docdesigner:::dd_error_digest(""), "(no message)"))

# --- User style-set library --------------------------------------------------
# tools::R_user_dir() honours R_USER_DATA_DIR, so we can stand up a throwaway
# user set library and exercise discovery, shadowing, inheritance, and the
# format_version gate against the real code rather than a mock.
old_data_dir <- Sys.getenv("R_USER_DATA_DIR", unset = NA)
sandbox <- tempfile("docdesigner-userlib-")
Sys.setenv(R_USER_DATA_DIR = sandbox)

write_style <- function(set, folder, lines) {
  d <- file.path(docdesigner:::dd_user_sets(), set, "styles", folder)
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, file.path(d, "format.yml"))
  d
}
write_set <- function(folder, lines) {
  d <- file.path(docdesigner:::dd_user_sets(), folder)
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, file.path(d, "set.yml"))
}

# 1. A style id that differs from its folder name resolves on the id.
write_set("custom", c("id: custom", "format_version: 2"))
write_style("custom", "some-folder", c("id: brandnew", "label: Brand New",
                                       'color.accent: "112233"'))
stopifnot("brandnew" %in% designer_styles()$style)
stopifnot(!"some-folder" %in% designer_styles()$style)
stopifnot(identical(designer_style("brandnew")$color$accent, "112233"))
# Tokens still fall back to engine defaults.
stopifnot(identical(designer_style("brandnew")$typography$body, "Source Serif 4"))

# 2. A user set shadows a core style of the same id, and says so.
write_set("shadow", c("id: shadow", "format_version: 2"))
write_style("shadow", "minimal", c("id: minimal", 'color.accent: "FF0000"'))
collided <- tryCatch(designer_styles(), warning = function(w) conditionMessage(w))
stopifnot(grepl("more than one set", collided))
stopifnot(identical(suppressWarnings(designer_style("minimal"))$color$accent, "FF0000"))
unlink(file.path(docdesigner:::dd_user_sets(), "shadow"), recursive = TRUE)

# 3. `inherits` resolves a multi-level chain, root-first.
write_set("chain", c("id: chain", "format_version: 2"))
write_style("chain", "gp", c("id: gp", 'color.accent: "AAAAAA"', 'color.rule: "AAAAAA"',
                             "code.highlight: kate"))
write_style("chain", "parent", c("id: parent", "inherits: gp", 'color.rule: "BBBBBB"'))
write_style("chain", "child", c("id: child", "inherits: parent", 'color.accent: "CCCCCC"'))
child <- designer_style("child")
stopifnot(identical(child$color$accent, "CCCCCC"))   # child wins
stopifnot(identical(child$color$rule, "BBBBBB"))     # parent wins over grandparent
stopifnot(identical(child$code$highlight, "kate"))   # grandparent survives
stopifnot(is.null(child$inherits))

# 4. A cycle errors instead of hanging.
write_style("chain", "loopa", c("id: loopa", "inherits: loopb"))
write_style("chain", "loopb", c("id: loopb", "inherits: loopa"))
cyc <- tryCatch(designer_style("loopa"), error = function(e) conditionMessage(e))
stopifnot(grepl("Circular", cyc))

# 5. A missing parent errors clearly rather than silently ignoring `inherits`.
write_style("chain", "orphan", c("id: orphan", "inherits: nope"))
orphan <- tryCatch(designer_style("orphan"), error = function(e) conditionMessage(e))
stopifnot(grepl("not installed", orphan))
unlink(file.path(docdesigner:::dd_user_sets(), "chain"), recursive = TRUE)

# 6. A set from a newer format is skipped, not mis-rendered.
write_set("future", c("id: future", "format_version: 3"))
write_style("future", "shiny", "id: shiny")
fv <- tryCatch(designer_styles(), warning = function(w) conditionMessage(w))
stopifnot(grepl("format_version", fv))
stopifnot(!"shiny" %in% suppressWarnings(designer_styles())$style)
unlink(file.path(docdesigner:::dd_user_sets(), "future"), recursive = TRUE)

# 7. A set ships its own font family in assets/fonts/.
fdir <- file.path(docdesigner:::dd_user_sets(), "custom", "assets", "fonts")
dir.create(fdir, recursive = TRUE, showWarnings = FALSE)
file.create(file.path(fdir, c("Inter-Regular.otf", "Inter-Bold.otf")))
write_style("custom", "some-folder",
            c("id: brandnew",
              "fonts.Inter.regular: Inter-Regular.otf",
              "fonts.Inter.bold: Inter-Bold.otf",
              "typography.body: Inter",
              "typography.heading: Inter"))
spec <- designer_style("brandnew")
reg <- docdesigner:::dd_font_registry(spec)
dirs <- docdesigner:::dd_font_dirs(spec)
# dd_font_family_dir() returns a normalised path with a trailing slash, because
# that is what fontspec's Path= requires. Do not re-normalise it here: that
# would strip the slash and the comparison would fail on a correct result.
inter_dir <- docdesigner:::dd_font_family_dir("Inter", reg, dirs)
stopifnot(identical(inter_dir, paste0(normalizePath(fdir, winslash = "/"), "/")))
stopifnot(grepl("/$", inter_dir))
# A core family still resolves alongside the set's own font, from a different
# directory -- this is the whole point of the set-aware registry.
fira_dir <- docdesigner:::dd_font_family_dir("Fira Code", reg, dirs)
stopifnot(nzchar(fira_dir), !identical(fira_dir, inter_dir))

# 8. A declared-but-absent font file errors clearly.
write_style("custom", "some-folder",
            c("id: brandnew",
              "fonts.Ghost.regular: Ghost-Regular.otf",
              "fonts.Ghost.bold: Ghost-Bold.otf",
              "typography.body: Ghost"))
spec <- designer_style("brandnew")
ghost <- tryCatch(
  docdesigner:::dd_font_family_dir("Ghost", docdesigner:::dd_font_registry(spec),
                                   docdesigner:::dd_font_dirs(spec)),
  error = function(e) conditionMessage(e))
stopifnot(grepl("not found", ghost))

unlink(sandbox, recursive = TRUE)
if (is.na(old_data_dir)) Sys.unsetenv("R_USER_DATA_DIR") else Sys.setenv(R_USER_DATA_DIR = old_data_dir)

# ---- Title layouts and callouts (port step 2) ------------------------------
# Resolution only: which layout a render gets. The pages themselves are
# checked by dev/page-baseline.R, which needs xelatex.
lay <- docdesigner:::dd_title_layout
stopifnot(identical(lay(designer_style("minimal")), "header"))
stopifnot(identical(lay(designer_style("minimal"), "page"), "page"))
stopifnot(identical(lay(list(title = list(layout = "journal"))), "header"))
stopifnot(identical(lay(list(title = list(page_break_after = TRUE))), "page"))
stopifnot(inherits(tryCatch(lay(designer_style("minimal"), "cover"), error = identity), "error"))

# Every style defines the callout environment and the title-page macros, so a
# document carrying a callout, or rendered with title_layout = "page", sets in
# any style.
for (st in designer_styles()$style) {
  pre <- docdesigner:::dd_preamble(designer_style(st))
  stopifnot(grepl("\\newenvironment{ddcallout}", pre, fixed = TRUE),
            grepl("\\newcommand{\\ddtitlepagetop}", pre, fixed = TRUE),
            grepl("\\fancypagestyle{ddtitlepage}", pre, fixed = TRUE))
}
# A callout tint comes from the style's own palette role.
pre <- docdesigner:::dd_preamble(designer_style("minimal"))
stopifnot(grepl("colback=accent!8!white", pre, fixed = TRUE))

# --- pdf(): document-level double spacing ------------------------------------
# The option must reach the generated preamble, and only when asked for. No
# pandoc or xelatex needed: pdf() builds the format object and writes the
# header file without rendering anything.
header_of <- function(fmt) {
  a <- fmt$pandoc$args
  i <- which(a %in% c("--include-in-header", "-H"))
  readLines(a[i[length(i)] + 1])
}
if (requireNamespace("rmarkdown", quietly = TRUE)) {
  stopifnot(!any(grepl("doublespacing", header_of(pdf(style = "minimal")), fixed = TRUE)))
  stopifnot(any(grepl("doublespacing", header_of(pdf(style = "minimal", doublespace = TRUE)), fixed = TRUE)))
}

# --- Structured authors reach \author{} as names, not "true" -----------------
# Regression: a list of author objects (name/dept/...) printed "TRUE" in the
# title block, because the template rendered the object as a boolean. Checked
# at the pandoc -> LaTeX stage only (no xelatex, so CRAN-safe); the rendered
# PDF text is checked across every style by dev/test-author-render.R.
author_tex <- function(yaml_author) {
  md <- tempfile(fileext = ".md")
  writeLines(c("---", "title: T", yaml_author, "---", "", "Hello."), md)
  tex <- tempfile(fileext = ".tex")
  rmarkdown::pandoc_convert(md, to = "latex", output = tex,
    options = c("--standalone", "--lua-filter",
                docdesigner:::dd_pkg_file("engine", "author.lua")))
  grep("^\\\\author\\{", readLines(tex, warn = FALSE), value = TRUE)
}
if (requireNamespace("rmarkdown", quietly = TRUE) && rmarkdown::pandoc_available()) {
  one_string <- author_tex('author: "Joseph N. Cohen"')
  one_object <- author_tex(c("author:", '  - name: "Joseph N. Cohen"', '    dept: "Sociology"'))
  two_object <- author_tex(c("author:", '  - name: "Ada Lovelace"', '    inst: "X"',
                             '  - name: "Alan Turing"'))
  stopifnot(length(one_string) == 1L, grepl("Joseph N. Cohen", one_string, fixed = TRUE))
  stopifnot(length(one_object) == 1L, grepl("Joseph N. Cohen", one_object, fixed = TRUE),
            !grepl("true", one_object, ignore.case = TRUE))
  stopifnot(grepl("Ada Lovelace", two_object, fixed = TRUE),
            grepl("Alan Turing", two_object, fixed = TRUE),
            grepl("\\and", two_object, fixed = TRUE),
            !grepl("true", two_object, ignore.case = TRUE))

  # Title-page furniture: contact block, warning and acknowledgements reach
  # the package template, on a title page and in the header layout.
  furniture_tex <- function(extra = character()) {
    md <- tempfile(fileext = ".md")
    writeLines(c("---", "title: T",
                 "author:", '  - name: "Ada Lovelace"', '    inst: "X"',
                 '    email: "ada@example.org"', '    web: "example.org"',
                 '  - name: "Alan Turing"',
                 'warning: "DRAFT: DO NOT CIRCULATE"',
                 'acknowledgments: "Thanks to Y."', "---", "", "Hello."), md)
    tex <- tempfile(fileext = ".tex")
    rmarkdown::pandoc_convert(md, to = "latex", output = tex,
      options = c("--standalone", "--template",
                  docdesigner:::dd_pkg_file("templates", "docdesigner.tex"),
                  "--lua-filter", docdesigner:::dd_pkg_file("engine", "author.lua"), extra))
    paste(readLines(tex, warn = FALSE), collapse = "\n")
  }
  page_tex <- furniture_tex(c("-V", "dd-title-page=true"))
  stopifnot(grepl("\\ddcontact{Ada Lovelace", page_tex, fixed = TRUE),
            grepl("mailto:ada@example.org", page_tex, fixed = TRUE),
            grepl("https://example.org", page_tex, fixed = TRUE),
            grepl("\\ddwarning{DRAFT: DO NOT CIRCULATE}", page_tex, fixed = TRUE),
            grepl("\\ddacknowledgements{", page_tex, fixed = TRUE))
  header_tex <- furniture_tex()
  stopifnot(grepl("\\preto{\\maketitlehooka}{\\ddwarning{", header_tex, fixed = TRUE),
            grepl("\\ddtitlenote{Correspondence: Ada Lovelace", header_tex, fixed = TRUE),
            grepl("\\ddtitlenote{\\ddacklabel", header_tex, fixed = TRUE),
            !grepl("\\ddcontact{", header_tex, fixed = TRUE))
}

# --- Page furniture and title tokens added in the 2026-10 style review --------
# Checked on the generated preamble; the rendered pages are checked by eye.
pre_with <- function(...) {
  s <- designer_style("modern")
  over <- docdesigner:::dd_expand_dotted(list(...))
  docdesigner:::dd_preamble(docdesigner:::dd_deep_merge(s, over))
}
has <- function(x, pat) any(grepl(pat, x, fixed = TRUE))
# first_page: none empties page 1; folio keeps the folio but not the title.
stopifnot(has(pre_with(header_footer.first_page = "none"),
              "\\fancypagestyle{plain}{\\fancyhf{}\\renewcommand{\\headrulewidth}{0pt}"))
folio <- pre_with(header_footer.first_page = "folio",
                  header_footer.header.left = "runningtitle",
                  header_footer.header.right = "page")
folio <- strsplit(folio, "\n", fixed = TRUE)[[1]]
plain_style <- grep("\\fancypagestyle{plain}", folio, fixed = TRUE, value = TRUE)
stopifnot(length(plain_style) == 1L, grepl("thepage", plain_style, fixed = TRUE),
          !grepl("ddrtitle", plain_style, fixed = TRUE))
# Running-head ink is muted unless named.
stopifnot(has(pre_with(header_footer.header.left = "page"), "\\fancyhead[L]{\\small\\color{muted}"))
stopifnot(has(pre_with(header_footer.header.left = "page", header_footer.header.color = "text"),
              "\\fancyhead[L]{\\small\\color{text}"))
# A band bleeds to the paper edge unless bleed is false.
band <- list(header_footer.header.fill = "accent", header_footer.header.left = "page")
stopifnot(has(do.call(pre_with, band), "\\paperwidth"))
nobleed <- do.call(pre_with, c(band, header_footer.header.bleed = FALSE))
stopifnot(!has(nobleed, "\\paperwidth"), has(nobleed, "\\headwidth"))
# title.weight: regular unbolds the title.
stopifnot(has(pre_with(title.weight = "regular"), "\\mdseries\\color{"))
# minimal is LaTeX's own look: Latin Modern from the TeX tree, no bundled path.
mpre <- docdesigner:::dd_preamble(designer_style("minimal"))
stopifnot(has(mpre, "\\setmainfont{lmroman10-regular.otf}[BoldFont="),
          has(mpre, "\\setmonofont{lmmono10-regular.otf}[BoldFont="))

# --- Tokens brought to life in 0.11 ------------------------------------------
# Every token in the schema is implemented: none is left "new", "port" or
# "risk", so a style can no longer declare something that silently does
# nothing.
st <- vapply(docdesigner:::dd_token_table(), function(t) {
  if (is.null(t$status)) "" else t$status
}, character(1))
stopifnot(!any(st %in% c("new", "port", "risk")))
# The running title is captured when \title is set (titlesec's \thetitle is
# the section number, which ran as the title in documents without a subtitle).
stopifnot(has(pre_with(), "\\renewcommand{\\title}[1]{\\gdef\\ddrtitle{#1}"))
stopifnot(has(pre_with(headings.h1.bar.fill = "accent"), "\\colorbox{accent}{\\parbox"))
stopifnot(has(pre_with(headings.numbering = "alpha"), "\\renewcommand{\\thesection}{\\Alph{section}}"))
stopifnot(has(pre_with(headings.h1.new_page = TRUE), "\\newcommand{\\sectionbreak}{\\clearpage}"))
stopifnot(has(pre_with(page.column_rule = TRUE), "\\setlength{\\columnseprule}{0.4pt}"))
stopifnot(has(pre_with(typography.hyphenation = FALSE), "\\hyphenpenalty=10000"))
stopifnot(has(pre_with(title.byline.position = "above"), "\\renewcommand{\\maketitlehooka}"))
stopifnot(has(pre_with(figure.placement = "here"), "\\def\\fps@figure{!htbp}"))
stopifnot(has(pre_with(title.keywords.show = FALSE), "\\newcommand{\\ddkeywords}[1]{}"))
# A ragged-right style keeps its paragraph indent.
stopifnot(has(pre_with(typography.justification = "ragged-right", paragraph.indent = "lg"),
              "\\setlength{\\RaggedRightParindent}{1.5em}"))
stopifnot(identical(docdesigner:::dd_title_layout(designer_style("qc-thesis")), "thesis"))
stopifnot(all(c("thesis", "qc-thesis", "bulletin") %in% designer_styles()$style))

# The table filter writes grid rules, and leaves booktabs tables as they were.
if (requireNamespace("rmarkdown", quietly = TRUE) && rmarkdown::pandoc_available()) {
  table_tex <- function(style) {
    md <- tempfile(fileext = ".md")
    writeLines(c("| A | B |", "|---|--:|", "| x | 1 |", "| y | 2 |"), md)
    tex <- tempfile(fileext = ".tex")
    rmarkdown::pandoc_convert(md, to = "latex", output = tex,
      options = c("--lua-filter", docdesigner:::dd_pkg_file("engine", "tables.lua"),
                  "--metadata", "dd-columns=1", "--metadata", paste0("dd-table-style=", style)))
    paste(readLines(tex, warn = FALSE), collapse = "\n")
  }
  stopifnot(grepl("\\begin{tabular}{|l|r|}", table_tex("grid"), fixed = TRUE))
  stopifnot(grepl("\\toprule", table_tex("booktabs"), fixed = TRUE),
            !grepl("\\hline", table_tex("booktabs"), fixed = TRUE))

  # thesis.lua: the document's fields win over the style's defaults, and the
  # signature block can be switched off.
  thesis_tex <- function(extra) {
    md <- tempfile(fileext = ".md")
    writeLines(c("---", "title: T", "author: A", "date: May 2027", extra, "---", "", "x"), md)
    defaults <- tempfile(fileext = ".yaml")
    yaml::write_yaml(list(`dd-thesis-defaults` = list(statement = "S", degree = "Default degree",
      institution = list("College"), signatures = TRUE, roman = TRUE)), defaults)
    tex <- tempfile(fileext = ".tex")
    rmarkdown::pandoc_convert(md, to = "latex", output = tex,
      options = c("--standalone", "--template", docdesigner:::dd_pkg_file("templates", "docdesigner.tex"),
                  "-V", "dd-title-thesis=true", "--metadata-file", defaults,
                  "--lua-filter", docdesigner:::dd_pkg_file("engine", "thesis.lua")))
    paste(readLines(tex, warn = FALSE), collapse = "\n")
  }
  th <- thesis_tex(c('degree: "Master of Arts in X"', "copyright: true"))
  stopifnot(grepl("Master of Arts in X", th, fixed = TRUE), !grepl("Default degree", th, fixed = TRUE),
            grepl("\\ddsignature{}{Committee Chair}", th, fixed = TRUE),
            grepl("2027 A. All rights reserved.", th, fixed = TRUE),
            grepl("\\pagenumbering{roman}", th, fixed = TRUE))
  stopifnot(!grepl("\\ddsignatures", thesis_tex("signatures: false"), fixed = TRUE))

  # kicker: a document replaces the style's kicker, or removes it with "".
  kicker_tex <- function(extra) {
    md <- tempfile(fileext = ".md")
    writeLines(c("---", "title: T", extra, "---", "", "x"), md)
    tex <- tempfile(fileext = ".tex")
    rmarkdown::pandoc_convert(md, to = "latex", output = tex,
      options = c("--standalone", "--template", docdesigner:::dd_pkg_file("templates", "docdesigner.tex"),
                  "--lua-filter", docdesigner:::dd_pkg_file("engine", "author.lua")))
    paste(readLines(tex, warn = FALSE), collapse = "\n")
  }
  stopifnot(grepl("\\def\\ddkickertext{Research Brief}", kicker_tex('kicker: "Research Brief"'), fixed = TRUE),
            grepl("\\def\\ddkickertext{}", kicker_tex('kicker: ""'), fixed = TRUE),
            !grepl("\\def\\ddkickertext", kicker_tex(character()), fixed = TRUE))
}
# The style's kicker is the default; a style without one defines it empty.
stopifnot(has(docdesigner:::dd_preamble(designer_style("policy")), "\\def\\ddkickertext{Policy Brief}"),
          has(docdesigner:::dd_preamble(designer_style("modern")), "\\def\\ddkickertext{}"))
