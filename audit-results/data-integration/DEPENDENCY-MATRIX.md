# Dependency and optional integration matrix

`DESCRIPTION` remains the dependency source of truth. No backend integration dependency was added by A3.5. `methods` was added to Imports because source schema validation inspects S4 slots; it is part of the R distribution.

| Integration | DESCRIPTION status | Windows environment | WSL environment | A3.5 result |
|---|---|---|---|---|
| testthat, vctrs, pillar, tibble | Required/suggested as declared | Core tests ran | Core tests ran | Covered by full suite |
| DBI + RSQLite | Suggested | Not installed; DBI/RSQLite tests skipped | DBI 1.2.3, RSQLite 2.4.6 | SQLite table/query adapter tests ran in WSL |
| dbplyr | Not a declared adapter dependency | Not installed | 2.5.2 | Lazy table rejection tested in WSL; no built-in adapter |
| Arrow | Not a declared adapter dependency | Not installed | 23.0.1 | Table/Dataset rejection tested in WSL; no implicit materialization |
| DuckDB | Not a declared adapter dependency | Not audited as installed | Not installed | No direct support or execution test |
| bit64, units, haven, hms, blob, sf | Optional Suggests | Not installed; related tests skipped | bit64 4.6, units 1.0.0, haven 2.5.5, blob 1.3.0, sf 1.0.24 available; hms test ran | Optional typed suites exercised in WSL |
| lubridate | Not an established handler in this checkout | Not installed | 1.9.5 | Package available in WSL but A2.3 handler/tests are absent |
| mirai, nanonext | Optional | Not installed | Not installed | Related tests skipped on both platforms |

R CMD check ran with `_R_CHECK_FORCE_SUGGESTS_=false` so it would not attempt network installation of absent optional packages. Windows reported unavailable optional Suggests; WSL reported only mirai/nanonext unavailable. Neither platform failed package installation because an optional integration was absent.
