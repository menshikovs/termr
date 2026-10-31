# Public API and compatibility

exports.csv resolves all 170 NAMESPACE exports in the loaded namespace. The
static alias scan finds no export without an Rd alias. R CMD check separately
validates namespace, documentation and signatures. Production R source and
runnable R examples have no triple-colon calls.

Comparing parsed function definitions with local HEAD adds exactly:
bar_chart, heatmap_chart, histogram, line_chart, scatter_chart. No prior export
was removed. Existing arguments/defaults of app(), column(), data_table() are
unchanged; inkr_stylesheet, label_mode and show_types were appended,
respectively. The comparison is stored in function-signatures.csv, not
inferred from a remote branch.

| Classification | Surface | Evidence / qualification |
|---|---|---|
| Stable | Core constructors/events, RTCSS, in-memory table display | docs/stability.md; full existing regressions |
| Additive | Five charts, typed metadata, bounded R-code exports, App inkr methods | Current R source, NAMESPACE and generated man topics |
| Experimental | Editing, lazy sources, native chart events, signals, streams, workers, mirai, Shiny and inkr | Stability guide explicitly identifies them |
| Internal / undocumented as extension points | Handler lists, caches, ChartWidget generator, private disposal registries, Pilot generator | They are not separately exported; applications must use documented constructors/methods |
| Potentially breaking for reflective clients | Widget id/classes changed from public fields to active bindings; assignment now validates and invalidates | Ordinary documented reads/assignments remain; field-list introspection or invalid IDs can differ |

Chart events deliberately retain the documented termrcharts.* names even
though no termrcharts package is required. This is an existing event contract,
not evidence of a hidden runtime dependency. Shiny control commands are absent.

H1 changes no public signature, export, event payload, dependency or package
version. Pilot's noRd annotation describes an internal class and produces no
new help topic. R6 reference graphs still require explicit ownership; API
compatibility alone cannot establish lifecycle correctness (F01/F05/F08).

Minimum R 4.1 and native macOS were not rerun here. The CI matrix declares
those jobs, but historical CI success is not current-tree evidence.
