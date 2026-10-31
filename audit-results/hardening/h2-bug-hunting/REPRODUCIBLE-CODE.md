# Reproducible Code Generation & AST Hardening

`DataTable$reproducible_code()` generates safe, self-contained R expressions reproducing user actions.

## 1. Export Modalities
- **`"pipeline"`**: Exports data transformations (filters, sort keys, column selections) applied to a base dataset named `data`.
- **`"edits"`**: Exports recorded local cell assignments (`.termr_data[[col]][[row]] <- val`).
- **`"value"`**: Exports the bounded data payload of selected cells as an inline literal.

## 2. Correctness & Security Invariants
1. **Forward Simulation**: Before declaring `status = "exact"`, `reproducible_code("pipeline")` simulates the row order resulting from the pipeline AST. If local edits have changed the sort order of rows, it safely falls back to `status = "unsupported"`.
2. **No Code Injection**: Column names with backticks, spaces, or shell commands are never concatenated into strings. They are generated using `as.name()` or character indexing `[["..."]]` with `dput()` escaping.
3. **No Dynamic `eval(parse())`**: User input is never evaluated dynamically. AST expressions are constructed via R language objects (`as.call`, `as.name`, `bquote`).\n