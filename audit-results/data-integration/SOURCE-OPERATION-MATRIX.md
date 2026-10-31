# Source operation matrix

| Operation | Local frame/tibble | Generic `table_source()` | `db_table_source()` | `db_query_source()` |
|---|---|---|---|---|
| Page/viewport read | Local indexed access | Required `get_rows()` callback | SQLite `LIMIT`/`OFFSET`, selected columns | SQLite pager or caller adapter, bounded pages |
| Exact row count | `nrow()` | Required exact callback/value | `COUNT(*)`, recounted after filter and refresh | `COUNT(*)` at creation and explicit refresh; cached during paint |
| Unknown/estimated row count | Not applicable | Rejected | Not applicable | Rejected by adapter validation |
| Sort | Local operation | Delegated only when `sort` exists | SQL `ORDER BY` with quoted names | Not pushed into query; source is read-only |
| Filter | Local predicate/filter | Delegated only when `filter` exists | Parameterized `equals`, `contains`, `range`, `missing` filters; function filters rejected | Not pushed into query |
| Search | Local value scan | Delegated only when `search` exists | No built-in callback | No built-in callback |
| Edit | Typed local `set_cell()` | Delegated only when `set_value` exists and column is editable | No built-in edit callback | Read-only |
| Refresh | Re-read local object only by replacing data | Optional callback; invalidates source page cache | Recounts current filtered table | Re-runs cached count callback; clears page cache |
| Close | No source resource | Optional explicit callback | Disconnect only when `owned = TRUE` | Marks source closed; connection remains caller-owned |
| Fetch error | R error | Error, or page placeholder via `on_error` | Propagated through source handling | Error is exposed through placeholder/status; retry requires successful read/refresh |

An adapter must implement backend operations itself. A missing source operation is an explicit error; there is no fallback that collects all rows and applies a local sort, filter, or search. DBI query mode counts a result set but does not infer predicate pushdown from SQL text. The callback contract requires an exact count, but a generic callback that supplies a rounded integer estimate cannot be distinguished from an exact count; providers are trusted to honor the contract.
