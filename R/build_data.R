# Build tidy long-format data for the Antarctic Sea Ice indicator.
#
#   Rscript R/build_data.R
#
# Reads EPA's published figure CSVs in data-raw/ and writes data/*.csv plus
# data/meta.yml. Rerunning with unchanged inputs produces byte-identical output.
# Nothing here touches the network.
#
# Generated as a stub by the build-indicator skill. Each figure below has a
# `todo_reshape()` call standing where its reshape belongs. Replace that line,
# then delete the todo_reshape() helper once no call to it remains.
#
# TO UPDATE THE DATA: drop replacement CSVs into data-raw/ and rerun. Headers
# are asserted, not assumed, so a renamed or reordered column stops the build.

suppressPackageStartupMessages({
  library(dplyr)
})

root <- here::here()
source(file.path(root, "R/utils/epa_csv.R"))
source(file.path(root, "R/utils/write_stable.R"))

raw_dir <- file.path(root, "data-raw")
out_dir <- file.path(root, "data")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ---- Indicator constants -----------------------------------------------------

INDICATOR <- list(
  name                    = "Antarctic Sea Ice",
  slug                    = "antarctic-sea-ice",
  publisher               = "U.S. Environmental Protection Agency",
  source_page             = "https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-antarctic-sea-ice/index.html",
  technical_documentation = "https://19january2025snapshot.epa.gov/system/files/documents/2024-12/antarctic-sea-ice_td.pdf",
  rights                  = "Public domain, work of the U.S. Government (17 U.S.C. 105)"
)

# ---- Figure 1: February and September Monthly Average Antarctic Sea Ice Extent, 1979–2024 ----

f1_path <- file.path(raw_dir, "antarctic-sea-ice-fig-1.csv")
f1_meta <- read_epa_preamble(f1_path)
f1_raw  <- read_epa_csv(f1_path)

# All columns are listed as expected headers so a rename or reorder stops the
# build from the first run. When you write the reshape, move the identifier
# columns into id_cols so the split between keys and series is explicit.
assert_headers(
  f1_raw,
  id_cols          = "Year",
  expected_headers = c("February", "September"),
  what             = "antarctic-sea-ice-fig-1.csv"
)

# One row per year and month, in source order (year, then February before
# September). Values stay character so EPA's 10 significant digits survive.
f1 <- f1_raw |>
  tidyr::pivot_longer(c(February, September), names_to = "month", values_to = "value") |>
  transmute(year = Year, month, value)
assert_conservation(f1_raw, c("February", "September"), nrow(f1), "antarctic-sea-ice-fig-1.csv")

write_csv_stable(f1, file.path(out_dir, "antarctic_sea_ice_extent.csv"))

# ---- Data dictionary ---------------------------------------------------------

col <- function(name, type, description) {
  list(name = name, type = type, description = description)
}

# One entry per output column, in order, filled from the data frame itself so it
# cannot drift. A column missing from `docs` leaves a blank type and description,
# which tests/test-data.R fails on.
describe <- function(df) {
  docs <- list(
    year  = c("integer", "Calendar year."),
    month = c("string", "Month of the monthly average: February (annual minimum) or September (annual maximum)."),
    value = c("number", "Monthly average Antarctic sea ice extent, in million square miles.")
  )
  lapply(names(df), function(nm) col(nm, docs[[nm]][1] %||% "", docs[[nm]][2] %||% ""))
}

meta <- list(
  indicator = INDICATOR,
  datasets = list(
    list(
      file            = "antarctic_sea_ice_extent.csv",
      figure          = "Figure 1",
      figure_title    = f1_meta$title,
      source_file     = "antarctic-sea-ice-fig-1.csv",
      source_sha256   = file_sha256(f1_path),
      source_encoding = "windows-1252",
      data_source     = f1_meta$data_source,
      web_update      = f1_meta$web_update,
      unit            = f1_meta$units,
      rows            = nrow(f1),
      columns         = describe(f1)
    )
  )
)

write_yaml_stable(meta, file.path(out_dir, "meta.yml"))

# ---- Verify what was written -------------------------------------------------

written <- list.files(out_dir, pattern = "[.](csv|yml)$", full.names = TRUE)
invisible(lapply(written, assert_clean_output))

cat("\nWrote:\n")
for (p in written) {
  cat(sprintf("  %-34s %8d bytes  %s\n", basename(p), file.size(p), substr(file_sha256(p), 1, 12)))
}
