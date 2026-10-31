# Fuzz and randomized regression results

## Executed model-based coverage

The source tests include a seeded randomized sequence (`set.seed(18)`) of 40 ascending-sort, descending-sort, filter, and clear-filter actions. After each action, the delegated source view and DataTable row values are compared with an in-memory reference. The Windows and WSL full test suites passed this test.

Protocol negative cases cover invalid counts, duplicate/invalid column names, non-data-frame pages, wrong row counts, mismatched names, and callback errors. A regression switches a page from integer to character and a POSIXct column from UTC to America/New_York; both are rejected as schema drift. A projection regression checks every requested field is in the visible projection. Refresh/error tests verify recovery after an injected temporary source failure.

Backend boundary tests create a dbplyr lazy table and Arrow Table/Dataset and confirm direct DataTable construction errors instead of silently collecting them. These run in WSL where dbplyr and Arrow are installed; Windows skips them because the packages are absent.

## Fuzz scope

This is bounded deterministic/model-based randomized coverage, not a long-running arbitrary-input fuzzer. No corpus-based fuzzing of every optional vector class or database driver was performed. The randomized test contains 40 operations per invocation and checks equivalence at each step.
