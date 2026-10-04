# Small shared helpers. Defined once; sourced by every other file in the
# package. Do not re-define `%||%` elsewhere.

`%||%` <- function(x, y) if (is.null(x)) y else x

# Coerce a token colour to a bare uppercase RRGGBB string.
#
# YAML is lenient about hex-looking scalars: `accent: 333333` parses as an
# integer, `accent: "#B21F24"` keeps its hash, and `accent: 006A71` stays a
# string only because of the leading zero. Normalise all of them before they
# reach \definecolor, which accepts exactly six hex digits.
#
# An all-digit colour is only recoverable when YAML read it as a six-digit
# DECIMAL, i.e. 100000-999999. Anything with a leading zero was read as octal
# (`001122` -> 594) or collapsed (`000000` -> 0); the original digits are gone,
# so say "quote it" rather than guess or report a baffling "got '0'".
dd_hex <- function(x, default = "000000") {
  if (is.null(x)) x <- default
  if (is.numeric(x)) {
    if (length(x) == 1L && !is.na(x) && x == round(x) && x >= 100000 && x <= 999999) {
      x <- format(x, scientific = FALSE)
    } else {
      stop("A colour written as bare digits lost its leading zeros when YAML ",
           "read it as a number. Quote it, e.g. \"#001122\".", call. = FALSE)
    }
  }
  x <- toupper(sub("^#", "", as.character(x)))
  if (!grepl("^[0-9A-F]{6}$", x)) {
    stop("Not a 6-digit hex colour: '", x, "'", call. = FALSE)
  }
  x
}
