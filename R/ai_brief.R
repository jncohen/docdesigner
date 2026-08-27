# The Claude Design constraint brief.
#
# Generated FROM inst/engine/schema.yml (the single source of truth for the
# token vocabulary; see R/schema.R's header) so it can never drift out of
# sync with what the engine actually accepts. Purpose: hand this document to
# Claude Design (as an upload, or the text of a project-level instruction) so
# it designs *within* what docdesigner can express, instead of producing
# something plausible-looking that designer_import_claude_design() can only
# partially translate. See dev/CLAUDE-DESIGN-IMPORT.md for the full pipeline
# this brief is step 1 of.

# Short, hand-written purpose text per colour role. schema.yml declares the
# roles but not what each is *for* -- that's exactly the kind of thing a
# design brief needs and a machine-readable schema doesn't carry.
dd_role_doc <- function() {
  c(
    accent     = "Primary identifying colour. Headings, the title, rules, and links unless overridden. Every style must set this.",
    accent2    = "Optional secondary accent. Nullable -- most shipped styles leave it unset. Use sparingly if at all; this is not a second primary colour.",
    text       = "Body text colour. Every style must set this.",
    muted      = "Secondary text: byline, date, captions, muted labels. Every style must set this.",
    rule       = "Colour of hairlines and rules (under headings, under the title).",
    background = "Page background colour. Nullable -- null means the paper's default (effectively white).",
    code_bg    = "Fill behind code blocks. Nullable -- null means no fill.",
    knockout   = "Colour of text drawn on top of an accent-filled bar. Defaults to white-on-accent."
  )
}

#' The Claude Design constraint brief
#'
#' Generates a Markdown document that states docdesigner's token vocabulary
#' as hard design constraints: the colour roles, the bundled fonts, the named
#' scale steps (space, rule weight, margin, width), the bounded type scale,
#' and the five `title.layout` archetypes. Give this to Claude Design (upload
#' it, or paste it as project instructions) before designing a new style, so
#' the result is something [designer_import_claude_design()] can actually
#' translate rather than a design that merely resembles one.
#'
#' This is generated from `inst/engine/schema.yml`, not hand-maintained, so
#' it cannot drift from what the engine actually accepts the way a
#' hand-written brief would as the schema evolves.
#'
#' @param path If given, write the brief to this file. Otherwise return it as
#'   a character vector of lines.
#' @return Character vector of Markdown lines, invisibly if `path` is given.
#' @export
designer_ai_brief <- function(path = NULL) {
  schema <- dd_schema()
  scale_table <- function(name) {
    steps <- schema$scales[[name]]
    paste0("`", names(steps), "` = ", unlist(steps), collapse = ", ")
  }

  L <- c(
    "# docdesigner design brief for Claude Design",
    "",
    "You are designing a print PDF style for **docdesigner**, an R Markdown",
    "rendering engine. The engine only understands a fixed, bounded set of",
    "design tokens -- it cannot render anything outside them. Treat every",
    "constraint below as a hard boundary, not a suggestion: a design that",
    "relies on something not listed here (a gradient, a fifth accent hue, an",
    "arbitrary font) will only be partially recoverable when it's imported",
    "back into docdesigner.",
    "",
    "This is a **print** design, not a responsive web page. Design for a",
    "single fixed page width (see `page.margin` below), not a fluid layout.",
    "",
    "## Colour",
    "",
    "Exactly these roles exist. Do not introduce more distinct hues than",
    "this list allows.",
    ""
  )

  roles <- schema$roles
  docs <- dd_role_doc()
  for (r in roles) {
    L <- c(L, paste0("- **", r, "**: ", docs[[r]] %||% ""))
  }

  L <- c(L, "",
    "## Fonts",
    "",
    paste0("Bundled (usable with no extra work): ",
           paste0("*", schema$bundled_fonts, "*", collapse = ", "), "."),
    "",
    "**All four bundled families are serif or monospace -- there is no",
    "bundled sans-serif.** A sans-serif design is not out of bounds, but it",
    "means supplying font files (`fonts.<Family>.regular/bold/italic/",
    "bolditalic`) rather than using what's already available.",
    "",
    "Three font roles: `typography.body`, `typography.heading` (falls back",
    "to body if unset), `typography.mono` (code). At most three families in",
    "a single design -- docdesigner has no fourth type role.",
    "",
    "## Type scale",
    "",
    paste0("- Base body size: one of ", paste0("`", schema$tokens$typography.base_size$values, "`", collapse = ", "), "."),
    "- Line height: 1.0-2.0x (typical: 1.2-1.4).",
    "- Heading sizes are a *multiple of the base size*, not a free value: h1/h2/h3 each between 0.5x and 4.0x body size. A typical scale is h1 around 1.3-1.5x, h2 around 1.1-1.2x, h3 at or near 1.0x.",
    "- Heading weight: light, regular, or bold -- no in-between.",
    "- Heading case: none, upper, lower, or smallcaps.",
    "",
    "## Rules and rhythm \u2014 named steps only",
    "",
    "These are enums, not free dimensions. A design that uses a rule weight",
    "or a spacing value off this list cannot be represented exactly.",
    "",
    paste0("- Rule weight: ", scale_table("rule_weight")),
    paste0("- Vertical space (heading/paragraph spacing): ", scale_table("space")),
    paste0("- Paragraph indent: ", scale_table("indent")),
    paste0("- Page margin: ", scale_table("margin"), " (or a custom margin in inches, 0.4-2.0)"),
    "",
    "## Title treatment",
    "",
    "Five archetypes exist for how the title/byline/abstract block reads.",
    "**Pick one** and design toward it -- a design that mixes elements from",
    "several will not map cleanly onto any single archetype:",
    ""
  )

  ti <- schema$tokens$title.layout
  for (v in ti$values) {
    doc <- if (!is.null(ti$doc)) {
      m <- regmatches(ti$doc, regexpr(paste0(v, ": [^.]*\\."), ti$doc))
      if (length(m) && nzchar(m)) sub(paste0("^", v, ": "), "", m) else ""
    } else ""
    L <- c(L, paste0("- **", v, "**", if (nzchar(doc)) paste0(" -- ", doc) else ""))
  }

  L <- c(L, "",
    "**Caveat, stated plainly:** `title.layout` is implemented in",
    "docdesigner's LaTeX template but not yet wired up to the `pdf()` output",
    "path (tracked in `dev/PORT-PLAN.md`). A design built around, say, a",
    "full-page `journal` title page is valuable now for its colour, type,",
    "and heading choices -- those import cleanly -- but the full-page",
    "treatment itself will not render until that port lands. Don't be",
    "surprised if an early import comes back with a plain flush-left title",
    "regardless of what the Claude Design canvas shows; that's this gap, not",
    "a bug in the import.",
    "",
    "## Tables and code",
    "",
    paste0("- Table style: one of ", paste0("`", schema$tokens$table.style$values, "`", collapse = ", "), "."),
    paste0("- Code syntax theme: one of ", paste0("`", schema$tokens$code.highlight$values, "`", collapse = ", "), "."),
    "",
    "## Explicitly out of bounds",
    "",
    "- Gradients, drop shadows, or any effect implying a light source.",
    "- More than two accent hues (`accent` + optional `accent2`).",
    "- Background images or photography behind text.",
    "- Partial transparency on text or rules (must survive grayscale print).",
    "- More than four heading levels.",
    "- Arbitrary pixel font sizes not expressible as one of the base sizes",
    "  above, or a heading scale multiple of one.",
    "",
    "## What to do with the result",
    "",
    "Export as **standalone HTML** (Claude Design's Export menu). Then, in",
    "R:",
    "",
    "```r",
    "docdesigner::designer_import_claude_design(",
    "  html = \"path/to/export.html\",",
    "  id   = \"your-style-id\",",
    "  from = \"minimal\"",
    ")",
    "docdesigner::designer_validate_style(\"your-style-id\")",
    "```",
    "",
    "The import extracts colour, font, and type-scale values mechanically.",
    "It does not set `title.layout` or any other structural token -- those",
    "are still your call, informed by which archetype you designed toward",
    "above. See `dev/CLAUDE-DESIGN-IMPORT.md` for the full accounting of",
    "what is and isn't extracted."
  )

  if (!is.null(path)) {
    writeLines(L, path)
    message("Wrote design brief to ", path)
    return(invisible(L))
  }
  L
}
