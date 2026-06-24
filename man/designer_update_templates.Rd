\name{designer_update_templates}
\alias{designer_update_templates}
\title{Update local docdesigner assets}
\usage{
designer_update_templates(path = ".", source = c("installed", "github"),
  branch = "main", overwrite = TRUE)
}
\arguments{
\item{path}{Destination directory.}
\item{source}{\code{"installed"} copies assets from the installed package;
\code{"github"} downloads assets from the repository.}
\item{branch}{GitHub branch or tag when \code{source = "github"}.}
\item{overwrite}{Whether to replace existing local files.}
}
\description{
Refreshes editable local copies of the LaTeX template, fonts, CSL file, and
style manifests. Most projects do not need local assets; use this only when a
project deliberately keeps editable or frozen copies.
}
\value{
Invisibly returns \code{path}.
}
