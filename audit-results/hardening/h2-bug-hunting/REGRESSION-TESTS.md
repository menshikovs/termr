# Regression Testing Strategy & Results

Phase H2 maintains a multi-layered regression suite preventing any regression of fixed defects:

1. **`tests/testthat/test-h1-contracts.R`**:
   - 7 assertions covering Phase H1 baseline contracts (table source options, focus release, and event dispatch).

2. **`tests/testthat/test-h2-contracts.R`**:
   - 104 assertions covering:
     - F01: 6 atomic source replacement scenarios (throw on count, throw on schema, throw on get_rows, error handler callback, state preservation).
     - F02: 10 sorting and editing reproducible code scenarios.
     - F08: SQLEditor and DatabaseExplorer owned vs borrowed connection lifecycle.
     - F09: `check_count` boundary test matrix (`NULL`, `0`, `Inf`, `-Inf`, `NaN`, `NA`, `1.5`, characters, `2^31`).
     - F03: Chart stream drain-only contract and backlog recovery.
     - F04: Mid-dispatch detached ancestor message suppression.

3. **`tests/testthat/test-h2-state-machine.R`**:
   - 200+ assertions verifying invariant preservation across 40 randomized state transitions in DataTable and dynamic App widget tree lifecycles.

4. **`tests/testthat/test-h2-adversarial-security.R`**:
   - 118 assertions verifying safety against code injection, ANSI escape injection, and fuzz inputs.

**Summary**: 100% of contract and regression tests pass cleanly on both Windows and Linux WSL.\n