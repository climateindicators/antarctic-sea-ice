# Regression checks on the generated data for the Antarctic Sea Ice indicator.
#
#   Rscript tests/test-data.R
#
# The checks below are shape-independent: they hold whatever the reshape in
# R/build_data.R turns each figure into. Value snapshots, which pin the actual
# numbers so a data update fails loudly instead of passing silently, are the
# TODO at the bottom.

setwd(here::here())
source("R/utils/write_stable.R")

# Keeps the dictionary check readable when a meta.yml field is absent altogether.
`%||%` <- function(a, b) if (is.null(a)) b else a

failures <- character()
check <- function(label, ok) {
  ok <- isTRUE(ok)
  cat(sprintf("  [%s] %s\n", if (ok) "PASS" else "FAIL", label))
  if (!ok) failures <<- c(failures, label)
  invisible(ok)
}

rd <- function(f) {
  readr::read_csv(file.path("data", f),
                  col_types = readr::cols(.default = readr::col_character()),
                  na = character(), progress = FALSE)
}

meta <- yaml::read_yaml("data/meta.yml")

cat("\nData dictionary\n")
check("meta.yml documents 1 dataset(s)", length(meta$datasets) == 1L)
check("meta.yml has no timestamp",
      !any(grepl("\\d{4}-\\d{2}-\\d{2}T|Sys\\.time|generated_at",
                 readLines("data/meta.yml", warn = FALSE))))

for (ds in meta$datasets) {
  df   <- rd(ds$file)
  cols <- vapply(ds$columns, function(x) x$name, character(1))
  check(sprintf("%s: meta.yml lists the columns the file actually has", ds$file),
        identical(cols, names(df)))
  check(sprintf("%s: meta.yml row count matches the file", ds$file),
        identical(as.integer(ds$rows), nrow(df)))
  check(sprintf("%s: every column has a type and a description", ds$file),
        all(vapply(ds$columns, function(x) nzchar(x$type %||% "") && nzchar(x$description %||% ""), logical(1))))
  check(sprintf("%s: source file is still present and unchanged", ds$file),
        identical(file_sha256(file.path("data-raw", ds$source_file)), ds$source_sha256))
  check(sprintf("%s: no blank rows", ds$file), nrow(df) > 0L)
}

cat("\nFile hygiene\n")
for (f in list.files("data", pattern = "[.](csv|yml)$", full.names = TRUE)) {
  check(sprintf("%s is UTF-8, LF, no BOM, no mojibake", basename(f)),
        tryCatch({ assert_clean_output(f); TRUE },
                 error = function(e) { cat("      ", conditionMessage(e), "\n"); FALSE }))
}

cat("\nValue snapshots\n")
# Pinned from EPA's December 2024 web update. A data update fails here and
# names exactly which value moved. Values compare as strings to keep EPA's
# full precision.
ext <- rd("antarctic_sea_ice_extent.csv")
row_of <- function(df, i) paste(unlist(df[i, ]), collapse = ",")
extreme <- function(m, f) {
  x <- ext[ext$month == m, ]
  paste(unlist(x[f(as.numeric(x$value)), c("year", "value")]), collapse = ",")
}

check("extent: 92 rows (46 years x 2 months)", nrow(ext) == 92L)
check("extent: months are February and September only",
      identical(sort(unique(ext$month)), c("February", "September")))
check("extent: years run 1979 to 2024 with no gaps",
      identical(sort(unique(as.integer(ext$year))), 1979:2024))
check("extent: first row is 1979,February,1.212360779",
      row_of(ext, 1) == "1979,February,1.212360779")
check("extent: last row is 2024,September,6.586902833",
      row_of(ext, nrow(ext)) == "2024,September,6.586902833")
check("extent: February minimum is 2023 at 0.737455124",
      extreme("February", which.min) == "2023,0.737455124")
check("extent: February maximum is 2008 at 1.501937399",
      extreme("February", which.max) == "2008,1.501937399")
check("extent: September minimum is 2023 at 6.486516271",
      extreme("September", which.min) == "2023,6.486516271")
check("extent: September maximum is 2014 at 7.629378662",
      extreme("September", which.max) == "2014,7.629378662")

cat("\n")
if (length(failures)) {
  cat(sprintf("%d FAILED:\n", length(failures)))
  for (f in failures) cat("  -", f, "\n")
  quit(status = 1L)
}
cat("All data checks passed.\n")
