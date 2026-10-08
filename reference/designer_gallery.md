# Write a local style gallery

Creates a small HTML page that lists the installed PDF styles with color
swatches and style metadata. This is a local browsing aid; it does not
require a website.

## Usage

``` r
designer_gallery(
  output_dir = "rendered-examples/gallery",
  file = "style-gallery.html",
  open = interactive()
)
```

## Arguments

- output_dir:

  Directory where the gallery HTML should be written.

- file:

  Gallery filename.

- open:

  If `TRUE`, open the gallery in a browser.

## Value

The gallery path, invisibly.
