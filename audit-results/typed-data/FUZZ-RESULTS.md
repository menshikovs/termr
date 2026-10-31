# Seeded property checks

The new deterministic typed-table property scenario uses seed `20261030`.
Across 60 iterations it samples five rows from an 80-row mixed frame, formats
those visible typed slices, and checks that rendering does not mutate the
input. Each iteration also rejects an invalid integer edit and verifies the
column remains byte-for-byte identical to its pre-edit value. The test passed
in the Windows R 4.6.1 run.

The test also exercises factors with Unicode labels, Date values, logical
missingness and double values. Focused deterministic boundary cases cover
integer limits, Date validity, DST gaps/folds, non-finite doubles, list
summaries and empty frames. Optional hms, integer64 and dplyr checks are
skipped when those packages are absent.

Existing randomized DataTable and rendering property tests remain part of the
full suite; their final result is recorded in `TEST-RESULTS.md`.
