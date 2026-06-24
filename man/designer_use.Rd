\name{designer_use}
\alias{designer_use}
\title{Create a docdesigner starter}
\usage{
designer_use(path = ".", template = c("pdf", "html", "snapshot"),
  file = NULL, overwrite = FALSE, local_assets = FALSE)
}
\arguments{
\item{path}{Destination directory. Defaults to the current working directory.}
\item{template}{Starter type: \code{"pdf"}, \code{"html"}, or \code{"snapshot"}.}
\item{file}{Optional output filename.}
\item{overwrite}{Whether to replace an existing starter file.}
\item{local_assets}{Whether to copy editable local template, font, and CSL assets.}
}
\description{
Creates a small starter R Markdown file. The default workflow uses bundled
package assets directly, so starter YAML stays short.
}
\value{
Invisibly returns the starter path.
}
