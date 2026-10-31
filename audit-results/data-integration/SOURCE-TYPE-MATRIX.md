# Source and type support matrix

This matrix describes observed behavior in the current working tree. “Local” means data is held in the DataTable; “source” means pages are requested through `table_source()`.

| Input/type | Local DataTable | Source DataTable | Notes |
|---|---|---|---|
| `data.frame` | Supported | Required page result | Source must return exact rows and requested columns. |
| tibble | Supported | A tibble page satisfies the data-frame contract | Local grouped metadata is retained by typed edits where covered. |
| `grouped_df`, `rowwise_df` | Supported | No special backend adapter | Tests cover editing a group key and editing a rowwise table; grouping metadata is checked. |
| matrix | Accepted and normalized locally | No | The source page protocol requires a data frame. |
| logical, integer, double, character | Supported with typed format/edit handlers | Supported when page prototype remains stable | Later pages with changed storage type are rejected. |
| factor | Supported with typed display/edit rules | Supported if levels/class attributes remain stable | No implicit character-column conversion in source pages. |
| Date, POSIXct | Supported | Supported if class and attributes (including time zone) remain stable | Time-zone drift between pages is rejected. |
| `difftime`, `hms` | Handler/test coverage exists; `hms` is optional | Same source schema constraints | Windows skipped the optional `hms` case because it was not installed. |
| `integer64` | Optional bit64 handler/test | Same source schema constraints | Available and exercised in WSL; absent on Windows. |
| `units` | Optional units handler/test | Same source schema constraints | Available and exercised in WSL; absent on Windows. |
| haven labelled/SPSS types | Optional labelled display/edit rules and tests | Same source schema constraints | Available and exercised in WSL; Windows skipped those tests. |
| `raw`, raw list-column, `blob` | Binary-safe formatter/tests; values remain binary | Supported as returned page columns if prototype is stable | Read-only formatting; no implicit UTF-8 decode. blob is optional. |
| `sf`/`sfc` | Optional geometry-aware handler/tests | Stable geometry type/CRS required | Slice-specific `bbox` and `n_empty` are excluded from schema identity. |
| custom vctrs/S3 classes | Extension fallback/registration tests exist | Same class/attributes required page-to-page | Custom type owns its semantics; source cannot silently change class. |
| lubridate `Period`, `Duration`, `Interval` | **Not established** | **Not established** | The inspected repository has no A2.3-specific handler/test/report set despite lubridate being installed in WSL. Do not claim A2.3 complete. |
| dbplyr `tbl_lazy` | Rejected directly | Adapter can be written explicitly by the caller | No automatic `collect()` or dbplyr adapter. |
| Arrow `Table` / `Dataset` | Rejected directly | Adapter can be written explicitly by the caller | No implicit conversion/materialization; WSL tests exercise rejection. |
| DuckDB relation | Not directly supported/tested | Caller-supplied DBI/source adapter only | DuckDB is not installed in the audited WSL environment. |

Source mode does not weaken type checks to accommodate heterogeneous pages. The schema sample is bounded to 100 rows, but reads all source columns once to establish the initial column prototypes. Subsequent paint reads only visible columns.
