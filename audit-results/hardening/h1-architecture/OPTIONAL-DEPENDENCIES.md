# Optional dependencies and actual coverage

DESCRIPTION declares a small Imports set. None of inkr, typed-data extension
packages, DBI, Shiny, Plotly, mirai or nanonext is a mandatory namespace import.
R CMD check's loading-with-stated-dependencies stage passes independently.
Guard/source inspection, not merely skipped tests, supports optionality.

| Package | Windows available version | WSL available version |
|---|---|---|
| inkr | 0.1.0 | 0.1.0 |
| vctrs | 0.7.3 | 0.7.2 |
| pillar | 1.11.1 | 1.11.1 |
| tibble | 3.3.1 | 3.3.1 |
| dplyr | absent | 1.2.0 |
| units | absent | 1.0.0 |
| haven | absent | 2.5.5 |
| lubridate | absent | 1.9.5 |
| bit64 | absent | 4.6.0.1 |
| sf | absent | 1.0.24 |
| blob | absent | 1.3.0 |
| DBI | absent | 1.2.3 |
| RSQLite | absent | 2.4.6 |
| dbplyr | absent | 2.5.2 |
| duckdb | absent | absent |
| arrow | absent | 23.0.1 |
| mirai | absent | absent |
| nanonext | absent | absent |
| shiny | absent | 1.10.0 |
| plotly | absent | 4.10.4 |
| promises | absent | 1.3.2 |

inkr 0.1.0 was installed only into temporary validation libraries from the local
sibling checkout; separate default-library focused runs verified its absence
path on both platforms. No package dependency update was made.

WSL's units, haven, bit64, sf, blob, hms, DBI/SQLite, dbplyr/Arrow and
Shiny/Plotly cases actually execute in current suites. A loaded namespace alone
was not called full integration proof: backend Arrow/dbplyr tests verify
rejection, while lubridate probes show readonly fallback and three value
round-trips. DuckDB is absent and no automatic adapter exists.

mirai/nanonext are absent on both platforms. Their runtime tests are skipped;
JSON/stream/guard-only tests are not described as daemon/socket validation.
System libraries for installed WSL units/sf/Arrow are usable for the tests
exercised; no standalone clean-system installation or macOS UDUNITS/GDAL setup
was attempted. Future CI needs explicit optional-runtime jobs and an available
repository/source for the independent inkr package.
