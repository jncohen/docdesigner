# The context folder for designing a style with an AI assistant.
#
# Everything an assistant needs in order to write a style that the engine can
# render, gathered in one folder the person adds to the assistant's context:
# the constraints (the design brief), the vocabulary (the token table), worked
# examples (shipped styles with their comments), a test document, a script
# that closes the write-check-look loop, and instructions that tell the
# assistant how to use them. All of it is generated from the installed
# package, so it matches the engine the person will render with, which an
# assistant's memory of docdesigner may not.

#' Write a context folder for designing a style with an AI assistant
#'
#' Writes the files an AI assistant needs to design a docdesigner style well,
#' into one folder to add to the assistant's context (attach the files to a
#' chat, or open the folder in a coding assistant):
#'
#' - `AI-INSTRUCTIONS.md`: how the assistant should work, what each file is
#'   for, the validator's rules and the common mistakes. Load this first.
#' - `brief.md`: the engine's hard constraints, from [designer_design_brief()].
#' - `tokens.csv`: every token with its allowed values, default and status,
#'   from [designer_tokens()]. The only keys that exist.
#' - `examples/<id>.yml`: shipped styles copied with their authors' comments,
#'   as models of a well-reasoned `format.yml`.
#' - `specimen.md`: a test document with every element a style sets.
#' - `check-style.R`: a script that validates a style, renders a document with
#'   it and writes each page as a PNG, so the assistant (or you) can look at
#'   the result. Run `Rscript check-style.R path/to/style`.
#'
#' Everything is generated from the installed package, so it describes the
#' version you will render with. Regenerate it after updating docdesigner.
#'
#' @param path Folder to write. Created if it does not exist.
#' @param from The shipped style the new style will start from. It is copied
#'   into `examples/` and named in the instructions as the scaffold.
#' @param examples Further shipped styles to copy into `examples/`. Two or
#'   three that differ from one another give an assistant a better sense of
#'   the range than one.
#' @param overwrite If `FALSE` (default), refuse to write into a folder that
#'   already holds a context folder.
#' @return The folder path, invisibly.
#' @export
designer_ai_context <- function(path = "docdesigner-context", from = "minimal",
                                examples = NULL, overwrite = FALSE) {
  ids <- unique(c(from, examples))
  dirs <- lapply(ids, dd_style_dir)
  bad <- ids[vapply(dirs, is.null, logical(1))]
  if (length(bad)) {
    stop("Unknown docdesigner style: ", paste(bad, collapse = ", "),
         "\nAvailable: ", paste(designer_styles()$style, collapse = ", "), call. = FALSE)
  }
  if (file.exists(file.path(path, "AI-INSTRUCTIONS.md")) && !isTRUE(overwrite)) {
    stop("A context folder already exists at ", path, ". Use overwrite = TRUE to replace it.",
         call. = FALSE)
  }
  dir.create(file.path(path, "examples"), recursive = TRUE, showWarnings = FALSE)

  designer_design_brief(file.path(path, "brief.md"))
  utils::write.csv(designer_tokens(), file.path(path, "tokens.csv"), row.names = FALSE)
  file.copy(dd_pkg_file("specimen", "specimen.md"), file.path(path, "specimen.md"),
            overwrite = TRUE)
  for (i in seq_along(ids)) {
    file.copy(file.path(dirs[[i]], "format.yml"),
              file.path(path, "examples", paste0(ids[i], ".yml")), overwrite = TRUE)
  }
  writeLines(dd_check_script(), file.path(path, "check-style.R"))
  writeLines(dd_ai_instructions(from, ids), file.path(path, "AI-INSTRUCTIONS.md"))

  message("Wrote a docdesigner context folder to ", path, ".\n",
          "Give the assistant AI-INSTRUCTIONS.md first, then the rest of the folder.")
  invisible(path)
}

# The instructions the assistant reads first. Kept short: every line is a
# rule an assistant would otherwise get wrong, or a pointer to a file.
dd_ai_instructions <- function(from, ids) {
  schema <- dd_schema()
  version <- tryCatch(as.character(utils::packageVersion("docdesigner")),
                      error = function(e) "development")
  rules <- vapply(schema$rules, function(r) {
    paste0("- `", r$id, "` (", r$severity, "): ", r$doc)
  }, character(1))

  c(
    "# Instructions for an AI assistant designing a docdesigner style",
    "",
    "You are helping a person design a print PDF style for docdesigner, an R",
    "package that renders R Markdown to PDF from a style file, `format.yml`.",
    "The person decides what the style is for and judges the result. You write",
    "the style, check it, and show the person the pages.",
    "",
    paste0("These files were generated from docdesigner ", version, " and match it"),
    "exactly. Where they disagree with what you remember about docdesigner,",
    "they are right.",
    "",
    "## The files",
    "",
    "| File | What it is for |",
    "|:--|:--|",
    "| `brief.md` | The engine's hard constraints: colour roles, fonts, named steps, type scale, title layouts, markup styles. Read it before designing anything. |",
    "| `tokens.csv` | Every token: key, type, allowed values, default, status, notes. These are the only keys that exist. |",
    paste0("| `examples/*.yml` | Shipped styles, with their authors' comments. `", from,
           ".yml` is the starting point; ",
           if (length(ids) > 1) "the others show the range. " else "",
           "Model your file and your comments on them. |"),
    "| `specimen.md` | A test document with every element a style sets: headings, lists, quotes, tables, code, footnotes. |",
    "| `check-style.R` | Validates a style, renders a document with it, and writes each page as a PNG. |",
    "",
    "The guide for people, *Creating a style*, covers the principles of good",
    "style and is worth reading if you can fetch it:",
    "<https://jncohen.github.io/docdesigner/articles/creating-styles.html>.",
    "",
    "## How to work",
    "",
    "1. Before writing anything, ask the person what the style is for: the",
    "   kind of document, who reads it and how, and any publication or page it",
    "   should resemble. Ask for images of model pages if they have them.",
    "2. Start from a shipped style. Do not write a style from a blank file:",
    "",
    "   ```r",
    paste0("   docdesigner::designer_new_style(\"my-style\", from = \"", from,
           "\", path = \".\", complete = FALSE)"),
    "   ```",
    "",
    "3. Declare only the tokens that differ from the default. Use only keys in",
    "   `tokens.csv` and only values in its `allowed` column.",
    "4. Write a comment beside every token you set, saying why it has that value.",
    "5. Check the style:",
    "",
    "   ```sh",
    "   Rscript check-style.R path/to/my-style",
    "   ```",
    "",
    "   Fix every error first. Fix each warning or tell the person why it stays.",
    "6. Look at every page image the script writes. If you cannot see images,",
    "   ask the person to look and to tell you what they see. Never describe how",
    "   a page looks without having seen it.",
    "7. Show the person the pages, say what you changed and why, and ask what to",
    "   change next. Change one thing at a time when they are judging a detail.",
    "",
    "If you cannot run R, give the person the commands to run and ask them to",
    "paste back the validator's output and to attach the page images.",
    "",
    "## Rules the validator applies across tokens",
    "",
    rules,
    "",
    "## Mistakes to avoid",
    "",
    "- Inventing keys or values. `font.body`, `heading.color` and `1.5em` do",
    "  not exist; `typography.body`, `headings.h1.color` and the named steps do.",
    "- Hex colours outside `color.*`. Everywhere else a token names a colour",
    "  role (`accent`, `muted`, `rule` and so on).",
    "- Restating defaults. It freezes them when the engine's defaults improve.",
    "- Calling a page clean, balanced or readable without having looked at a",
    "  render. Count the characters on a full line of body text: 60 to 72 is",
    "  the target in one column, 40 to 55 per column in two.",
    "- Relying on a token whose `status` is `new`: it validates but does not",
    "  render yet.",
    "- Using `markup.*` tokens in a publication style. They are for drafts",
    "  printed to be marked up by hand; `brief.md` explains when they apply."
  )
}

# The write-check-look loop as one script, so neither the assistant nor the
# person has to assemble it.
dd_check_script <- function() {
  c(
    "# check-style.R: validate a docdesigner style, render a document with it,",
    "# and write each page as a PNG to look at.",
    "#",
    "# Usage:  Rscript check-style.R path/to/style [document.Rmd]",
    "#",
    "# The document defaults to specimen.md beside this script. Output goes to",
    "# <style>/check/. Page images need the pdftools package.",
    "",
    "args <- commandArgs(trailingOnly = TRUE)",
    "if (!length(args)) stop(\"Usage: Rscript check-style.R path/to/style [document]\", call. = FALSE)",
    "style <- normalizePath(args[1], mustWork = TRUE)",
    "here <- dirname(normalizePath(sub(\"^--file=\", \"\",",
    "  grep(\"^--file=\", commandArgs(FALSE), value = TRUE)[1])))",
    "doc <- normalizePath(if (length(args) > 1) args[2] else file.path(here, \"specimen.md\"),",
    "                     mustWork = TRUE)",
    "",
    "cat(\"== Validation\\n\")",
    "v <- docdesigner::designer_validate_style(style)",
    "if (any(v$severity == \"error\")) {",
    "  cat(\"\\nFix the errors above, then run this again.\\n\")",
    "  quit(status = 1)",
    "}",
    "",
    "cat(\"\\n== Render\\n\")",
    "out_dir <- file.path(style, \"check\")",
    "dir.create(out_dir, showWarnings = FALSE)",
    "pdf <- rmarkdown::render(doc, output_format = docdesigner::pdf(style = style),",
    "                         output_dir = out_dir, quiet = TRUE)",
    "cat(\"PDF:\", pdf, \"\\n\")",
    "",
    "cat(\"\\n== Pages\\n\")",
    "if (requireNamespace(\"pdftools\", quietly = TRUE)) {",
    "  n <- pdftools::pdf_info(pdf)$pages",
    "  pngs <- file.path(out_dir, sprintf(\"page-%02d.png\", seq_len(n)))",
    "  pdftools::pdf_convert(pdf, dpi = 100, filenames = pngs, verbose = FALSE)",
    "  cat(pngs, sep = \"\\n\")",
    "  cat(\"\\nLook at every page before judging the style.\\n\")",
    "} else {",
    "  cat(\"Install pdftools to get page images, or open the PDF and look at every page.\\n\")",
    "}"
  )
}
