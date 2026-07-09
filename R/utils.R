# Small shared helpers. Defined once; sourced by every other file in the
# package. Do not re-define `%||%` elsewhere.

`%||%` <- function(x, y) if (is.null(x)) y else x

# Coerce a token colour to a bare uppercase RRGGBB string.
#
# YAML is lenient about hex-looking scalars: `accent: 333333` parses as an
# integer, `accent: "#B21F24"` keeps its hash, and `accent: 006A71` stays a
# string only because of the leading zero. Normalise all of them before they
# reach \definecolor, which accepts exactly six hex digits.
dd_hex <- function(x, default = "000000") {
  if (is.null(x)) x <- default
  x <- toupper(sub("^#", "", as.character(x)))
  if (!grepl("^[0-9A-F]{6}$", x)) {
    stop("Not a 6-digit hex colour: '", x, "'", call. = FALSE)
  }
  x
}
