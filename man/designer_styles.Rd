\name{designer_styles}
\alias{designer_styles}
\alias{designer_style}
\title{List and read docdesigner styles}
\usage{
designer_styles()

designer_style(style = "minimal")
}
\arguments{
\item{style}{A built-in style name or path to a style bundle directory.}
}
\description{
Styles are data-driven bundles stored as \code{style.yml} files under
\code{inst/styles/<style-name>/}. A style controls the visual treatment of
general PDFs: fontset, accent color, syntax highlighting, columns, section
numbering, and citation link behavior.
}
\value{
\code{designer_styles()} returns a data frame. \code{designer_style()} returns
a list with one style's metadata.
}
