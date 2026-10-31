# Detailed H1 Defect Resolution

## 1. H1-F01 (P1): Atomic DataTable Source Replacement

### Defect Mechanism
In Phase H1, calling `DataTable$set_data(new_source)` mutated internal state (`private$.source`, `private$.data`, `private$.specs`, `private$.filters`) sequentially. If `new_source` failed during row counting, schema discovery, or seed page fetching, `DataTable` was left in a corrupt half-transitioned state:
- `private$.source` pointed to the broken new source.
- `private$.data` retained the old data frame schema or became empty.
- Subsequent calls to `render()`, `goto_row()`, or `selected_row()` crashed with unhandled errors.

### Root Cause
Lack of a staging area (two-phase commit). Mutation occurred before all validation checkpoints succeeded.

### Implementation Fix (`R/widget-datatable.R`)
1. Staged candidate source validation:
   - Evaluated candidate column names, column metadata, and row count into local temporary variables.
   - For lazy sources, fetched an initial sample window (`candidate_source$get_rows(0, sample_size)`) wrapped in `tryCatch`.
   - Handled candidate error callback (`candidate_source$on_error`) if provided, safely isolating failures.
2. Only after all candidate checks succeed is the transaction committed:
   - `private$.source <- candidate_source`
   - `private$.data <- candidate_data`
   - `private$.specs <- candidate_specs`
   - Invalidation of view caches and reset of cursor and scroll.
3. If any step fails:
   - State is untouched.
   - Previous source, cached pages, selection, and edit ledger remain fully valid.
   - Error is raised cleanly or posted via `"datatable.source_error"`.

### Verification
- `test-h2-contracts.R`: 6 multi-step source replacement failure and recovery tests.
- `test-h2-state-machine.R`: Periodic simulated backend crashes during 40-step random sequences.

---

## 2. H1-F02 (P1): Exact Pipeline Reproducibility

### Defect Mechanism
`DataTable$reproducible_code("pipeline")` exports an R expression reconstructing the active view operations (filters, sorting, column subsets, selections). When local cell edits had been made to a sorted table, the exported pipeline code applied `order()` to the original unedited data, whereas the interactive table was displaying view rows reflecting local edits. Consequently:
- `reproducible_code()` returned `status = "exact"`.
- Evaluating the exported code produced a different row ordering than displayed on screen.

### Root Cause
The export generator assumed that the visual order always matched the mathematical projection of `sort(filter(original_data))`. Local edits broke that assumption when editing columns involved in the sort key.

### Implementation Fix (`R/widget-datatable.R`)
1. In `DataTable$set_cell()`, added automatic re-sorting via `private$apply_sort(announce = FALSE)` whenever sorting or filtering is active.
2. In `reproducible_code("pipeline")`, added forward verification:
   - Constructed the simulated row index vector resulting from the proposed pipeline AST.
   - Compared `sim_rows` with `private$view_rows()`.
   - If `!identical(sim_rows, private$view_rows())` or if local edits caused divergence, the generator sets `status <- "unsupported"` with reason `"Local edits have modified the row ordering from the original source pipeline."` instead of returning `"exact"`.

### Verification
- Tested across 10 distinct sorting and editing permutations in `test-h2-contracts.R`:
  1. Sort -> edit non-key column: EXACT.
  2. Edit -> sort: EXACT.
  3. Filter -> edit -> sort: EXACT.
  4. Sort -> edit -> reverse sort: EXACT.
  5. Edit sort-key column: Divergence detected, safely returns UNSUPPORTED.
  6. Multiple edits to one row: Evaluated accurately.
  7. Duplicate sort keys: Stable ordering preserved.
  8. NA sort keys: Radix ordering match verified.
  9. Non-syntactic column names: Safely escaped.
  10. Edit after column reorder: Visual projection preserved.

---

## 3. H1-F08 (P1): DBI Connection Resource Ownership

### Defect Mechanism
`SQLEditor` and `DatabaseExplorer` accepted DBI connections wrapped via `db_connection(con, owned = TRUE)`. When the widget was removed from the widget tree or the application shut down, the underlying DBI connection remained open indefinitely. Conversely, if an owned connection failed, double-closing could trigger warnings.

### Root Cause
`Widget` lifecycle lacked an explicit disposal hook for owned external connections, relying instead on R finalizers / garbage collection.

### Implementation Fix (`R/sql.R` & `R/database-explorer.R`)
1. In `SQLEditor$initialize()`, registered a disposal binding in `widget_private(self)$.reactive_bindings`:
   ```R
   if (isTRUE(connection$owned)) {
     con_obj <- connection$con
     widget_private(self)$.reactive_bindings[[length(widget_private(self)$.reactive_bindings) + 1L]] <- list(
       dispose = function() {
         if (DBI::dbIsValid(con_obj)) {
           try(DBI::dbDisconnect(con_obj), silent = TRUE)
         }
       }
     )
   }
   ```
2. In `DatabaseExplorer$initialize()`, registered identical disposal hooks for owned database connections and child table preview sources.
3. During `widget_unmounting(w, dispose = TRUE)` and `screen_leaving()`, `App` invokes `widget_private(w)$dispose_bindings()`, cleanly closing owned connections. Borrowed connections (`owned = FALSE`) are untouched.

### Verification
- `test-h2-contracts.R`: Verified owned SQLite connection is disconnected on widget removal, disconnected on App shutdown, and that borrowed connections remain valid.

---

## 4. H1-F09 (P2): Invalid Capacity Validation in `check_count()`

### Defect Mechanism
`App$log_events(size = Inf)` was accepted without error during initialization. Later during event logging (`App$record_event()`), `utils::tail(df, private$.event_log_size)` with `size = Inf` failed or produced unexpected buffer sizing.

### Root Cause
`check_count()` in `R/style.R` only checked `!is.numeric(x) || length(x) != 1L || is.na(x) || x < 0`, failing to check `!is.finite(x)` or fractional integers (`1.5`).

### Implementation Fix (`R/style.R`)
Updated `check_count()`:
```R
check_count <- function(x, name = "count") {
  if (is.null(x)) return(NULL)
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || !is.finite(x) || x < 0 ||
      x != as.integer(x) || x > .Machine$integer.max) {
    stop(sprintf("`%s` must be a single non-negative integer.", name), call. = FALSE)
  }
  as.integer(x)
}
```
Rejects `Inf`, `-Inf`, `NaN`, `NA`, `1.5`, characters, negative numbers, and integers exceeding 32-bit limits.

### Verification
- Verified boundary tests in `test-h2-contracts.R`.\n