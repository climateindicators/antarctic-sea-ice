# Provenance

Every file in this directory is reproduced unmodified from EPA's published
indicator page and its per-figure data downloads. To update the data, replace the
file and rerun `Rscript R/build_data.R`.

## Indicator page

- `source-page.html`  \
  <https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-antarctic-sea-ice/index.html>  \
  sha256 `6bfa51b6b84b345fc9b97d2b49350d5760542f0ed628aa9d2ab048067bd6c30c`

Technical documentation: <https://19january2025snapshot.epa.gov/system/files/documents/2024-12/antarctic-sea-ice_td.pdf>

## Figure data

- `antarctic-sea-ice-fig-1.csv`  \
  <https://19january2025snapshot.epa.gov/system/files/other-files/2022-06/antarctic-sea-ice-fig-1.csv>  \
  sha256 `bf077a2404af2f42c55bbff827eaf0284e6213b711425164b0ad3045f830d1ab`  \
  encoding windows-1252, 46 data rows, columns: `Year`, `February`, `September`  \
  title: Figure 1. February and September Monthly Average Antarctic Sea Ice Extent, 1979–2024  \
  data source: NSIDC, 2024; web update: December 2024; units: million square miles

- **Figure 2** has no data download on EPA's page. The narrative carries the caption; there is nothing to build.
