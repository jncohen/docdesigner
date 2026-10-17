# Build examples/scf2022-specimen.csv, the data behind the short specimen
# (examples/specimen-short.Rmd): household net worth and marital status from
# the 2022 Survey of Consumer Finances.
#
#   Rscript dev/make-specimen-data.R [path/to/scf2022.rds]
#
# The input is the public SCF 2022 data, in 2022 dollars, as a list of the
# five implicates, each a data frame with the summary-extract variables and
# the full public variables (lower case). Only the first implicate and a few
# columns are kept, so the specimen renders anywhere without the full data. The
# estimates it shows are illustrative: one implicate, design ignored.

args <- commandArgs(trailingOnly = TRUE)
src <- if (length(args)) args[1] else "D:/Dropbox/Data/scf/base2022/scf2022.rds"
d <- readRDS(src)[[1]]

# X8023, the respondent's marital status. The public data keep all six codes
# for this variable (other marital items combine them).
marital <- c("Married", "Living with partner", "Separated", "Divorced",
             "Widowed", "Never married")[d$x8023]
out <- data.frame(
  wgt = round(d$wgt, 4),
  networth = round(d$networth),
  income = round(d$income),
  age = d$age,
  educ = c("Less than high school", "High school", "Some college",
           "College degree")[d$edcl],
  marital = marital,
  stringsAsFactors = FALSE)
stopifnot(!anyNA(out$marital), !anyNA(out$educ))

dest <- file.path(dirname(dirname(normalizePath(sub("^--file=", "", grep("^--file=",
  commandArgs(FALSE), value = TRUE)[1]), winslash = "/"))), "examples", "scf2022-specimen.csv")
utils::write.csv(out, dest, row.names = FALSE)
cat(sprintf("Wrote %d households to %s\n", nrow(out), dest))
