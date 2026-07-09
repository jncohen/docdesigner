library(docdesigner)

# --- Engine: style discovery -------------------------------------------------
styles <- designer_styles()
stopifnot(is.data.frame(styles))
stopifnot(all(c("style", "label", "description", "set") %in% names(styles)))
stopifnot(all(c("minimal", "demography", "policy", "nature") %in% styles$style))

# --- Engine: sets ------------------------------------------------------------
sets <- designer_sets()
stopifnot(is.data.frame(sets))
stopifnot(all(c("academic", "public") %in% sets$set))

# --- Engine: resolved tokens (defaults + style, inheritance applied) ---------
minimal_tokens <- designer_style("minimal")
stopifnot(is.list(minimal_tokens))
stopifnot(identical(minimal_tokens$id, "minimal"))
stopifnot(!is.null(minimal_tokens$color$accent))
stopifnot(!is.null(minimal_tokens$typography$body))

# An unknown style fails with a clear message.
unknown <- tryCatch(designer_style("does-not-exist"),
                    error = function(e) conditionMessage(e))
stopifnot(grepl("Unknown docdesigner style", unknown))

# `inherits` is a resolution instruction, not a token: it must not survive.
stopifnot(is.null(minimal_tokens$inherits))

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

# --- Colour coercion ---------------------------------------------------------
stopifnot(identical(docdesigner:::dd_hex("#b21f24"), "B21F24"))
stopifnot(identical(docdesigner:::dd_hex("006A71"), "006A71"))
bad <- tryCatch(docdesigner:::dd_hex("nope"), error = function(e) conditionMessage(e))
stopifnot(grepl("hex", bad))

# --- Scaffolding seeds raw tokens, not the resolved spec ---------------------
scratch <- tempfile("docdesigner-scaffold-")
dir.create(scratch)
new_dir <- designer_new_style("scratchstyle", from = "minimal", path = scratch)
seeded <- yaml::read_yaml(file.path(new_dir, "format.yml"))
stopifnot(identical(seeded$id, "scratchstyle"))
# minimal/format.yml declares no line_height; the engine default supplies it.
# If the scaffold froze the resolved spec, line_height would appear here.
stopifnot(is.null(seeded$typography$line_height))
stopifnot(is.null(seeded$page))
unlink(scratch, recursive = TRUE)

# --- Bundled assets are discoverable -----------------------------------------
template <- docdesigner:::dd_template()
fonts <- docdesigner:::dd_fonts()
stopifnot(nzchar(template))
stopifnot(nzchar(fonts))

# --- Output formats build ----------------------------------------------------
minimal_format <- pdf(style = "minimal")
stopifnot(inherits(minimal_format, "rmarkdown_output_format"))
stopifnot(identical(minimal_format$pandoc$latex_engine, "xelatex"))

html_format <- html()
stopifnot(inherits(html_format, "rmarkdown_output_format"))

snapshot_format <- snapshot(html = FALSE)
stopifnot(inherits(snapshot_format, "rmarkdown_output_format"))

# --- Local gallery -----------------------------------------------------------
gallery <- designer_gallery(output_dir = tempfile("docdesigner-gallery-"),
                            open = FALSE)
stopifnot(file.exists(gallery))

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
write_set("custom", c("id: custom", "format_version: 1"))
write_style("custom", "some-folder", c("id: brandnew", "label: Brand New",
                                       'color: { accent: "112233" }'))
stopifnot("brandnew" %in% designer_styles()$style)
stopifnot(!"some-folder" %in% designer_styles()$style)
stopifnot(identical(designer_style("brandnew")$color$accent, "112233"))
# Tokens still fall back to engine defaults.
stopifnot(identical(designer_style("brandnew")$typography$body, "Source Serif 4"))

# 2. A user set shadows a core style of the same id, and says so.
write_set("shadow", c("id: shadow", "format_version: 1"))
write_style("shadow", "minimal", c("id: minimal", 'color: { accent: "FF0000" }'))
collided <- tryCatch(designer_styles(), warning = function(w) conditionMessage(w))
stopifnot(grepl("more than one set", collided))
stopifnot(identical(suppressWarnings(designer_style("minimal"))$color$accent, "FF0000"))
unlink(file.path(docdesigner:::dd_user_sets(), "shadow"), recursive = TRUE)

# 3. `inherits` resolves a multi-level chain, root-first.
write_set("chain", c("id: chain", "format_version: 1"))
write_style("chain", "gp", c("id: gp", 'color: { accent: "AAAAAA", rule: "AAAAAA" }',
                             "highlight: kate"))
write_style("chain", "parent", c("id: parent", "inherits: gp", 'color: { rule: "BBBBBB" }'))
write_style("chain", "child", c("id: child", "inherits: parent", 'color: { accent: "CCCCCC" }'))
child <- designer_style("child")
stopifnot(identical(child$color$accent, "CCCCCC"))   # child wins
stopifnot(identical(child$color$rule, "BBBBBB"))     # parent wins over grandparent
stopifnot(identical(child$highlight, "kate"))        # grandparent survives
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
write_set("future", c("id: future", "format_version: 2"))
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
            c("id: brandnew", "fonts:", "  Inter:",
              "    regular: Inter-Regular.otf", "    bold: Inter-Bold.otf",
              "typography: { body: Inter, heading: Inter }"))
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
            c("id: brandnew", "fonts:", "  Ghost:",
              "    regular: Ghost-Regular.otf", "    bold: Ghost-Bold.otf",
              "typography: { body: Ghost }"))
spec <- designer_style("brandnew")
ghost <- tryCatch(
  docdesigner:::dd_font_family_dir("Ghost", docdesigner:::dd_font_registry(spec),
                                   docdesigner:::dd_font_dirs(spec)),
  error = function(e) conditionMessage(e))
stopifnot(grepl("not found", ghost))

unlink(sandbox, recursive = TRUE)
if (is.na(old_data_dir)) Sys.unsetenv("R_USER_DATA_DIR") else Sys.setenv(R_USER_DATA_DIR = old_data_dir)
