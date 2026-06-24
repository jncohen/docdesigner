\name{designer_gallery}
\alias{designer_gallery}
\title{Write a local style gallery}
\usage{
designer_gallery(output_dir = "rendered-examples/gallery",
  file = "style-gallery.html", open = interactive())
}
\arguments{
\item{output_dir}{Directory where the gallery HTML should be written.}
\item{file}{Gallery filename.}
\item{open}{Whether to open the gallery in a browser.}
}
\description{
Creates a small local HTML page listing the installed PDF styles with color
swatches and style metadata.
}
\value{
The gallery path, invisibly.
}
