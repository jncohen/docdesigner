\name{designer_check}
\alias{designer_check}
\title{Check a docdesigner setup}
\usage{
designer_check(path = ".", engine = c("xelatex", "pdflatex", "lualatex"))
}
\arguments{
\item{path}{Project directory to inspect.}
\item{engine}{LaTeX engines to check.}
}
\description{
Reports whether docdesigner can find its bundled assets and common rendering
tools.
}
\value{
A data frame with check results.
}
