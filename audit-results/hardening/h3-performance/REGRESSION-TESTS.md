# Regression contracts

New test-h3-performance-contracts.R covers EventQueue FIFO/allocation/lifetime
indices, no-sheet unmount cache identity, shared inkr parent construction,
epoch/state override invalidation, ancestor classes, stylesheet swap/removal,
reparenting, continuously advancing chart output, bounded points and cleanup.
failing-first*.log and queue-failing-first.log preserve the original failures.
No public API, generated documentation or dependency changes were necessary.

Existing test-chart-streams.R and test-h2-contracts.R change only the expected
first-chunk publication. Finite drain, bounded queue, order and cleanup checks
remain. h3-only.patch shows exact additions against the initial dirty snapshot.

H1/H2 filters cover atomic source replacement (F01), exact sorted/filtered
reproducibility (F02), detached ancestor bubbling (F04), Pilot startup cleanup
(F05), projection-key collisions (F06), documentation hygiene (F07), owned DBI
cleanup (F08) and finite/whole count validation (F09). Windows DBI tests skip;
the WSL dependency matrix executes them. inkr optional-free tests are run in
separate processes without the temporary inkr library path.

The full suites also include widget/layout/dirty-render, typed attributes,
data-source schema/cache/atomicity, native chart selection and streaming,
timers, key parsing, lifecycle and worker contracts. Check logs preserve the
actual platform exclusions. One initial focused run overlapped a queue-source
edit and saw an old loaded method with a newly added test; its log is retained
as focused-windows-initial.*, and final focused/full runs use frozen code.
