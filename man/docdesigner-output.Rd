\name{pdf}
\alias{pdf}
\alias{html}
\alias{snapshot}
\title{Render docdesigner outputs}
\usage{
pdf(..., style = "minimal", template = dd_template(), latex_engine = "xelatex")

html(..., assets = TRUE, checklist = TRUE, body_only = TRUE)

snapshot(..., html = TRUE, template = dd_template(), latex_engine = "xelatex",
  html_file = NULL, html_assets = TRUE, html_checklist = TRUE)
}
\arguments{
\item{...}{Arguments passed to the underlying \pkg{rmarkdown} output format.}
\item{style}{A built-in style name from \code{designer_styles()} or a style bundle path.}
\item{template}{LaTeX template path. Defaults to the bundled template.}
\item{latex_engine}{LaTeX engine for PDF output.}
\item{assets}{Whether plain HTML should copy local image assets beside the output.}
\item{checklist}{Whether plain HTML should write a publishing checklist.}
\item{body_only}{Whether plain HTML should strip the outer webpage shell.}
\item{html}{Whether Snapshot should write a plain HTML companion.}
\item{html_file}{Optional Snapshot HTML companion filename.}
\item{html_assets}{Whether Snapshot HTML should copy local image assets.}
\item{html_checklist}{Whether Snapshot HTML should write a checklist.}
}
\description{
The user-facing outputs are \code{pdf()} for designed PDFs, \code{html()} for
plain body HTML, and \code{snapshot()} for the official Snapshot PDF layout with
an optional plain HTML companion.
}
\value{
An R Markdown output format.
}
