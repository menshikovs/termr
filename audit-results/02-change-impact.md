# 02 Change impact of the uncommitted work (vs HEAD d6ca75e)

| Change | Files | Hypotheses tested | Result |
|---|---|---|---|
| `App$layout_diagnostics()` + `collect_layout_diagnostics()` | app.R, layout.R | invalid/NA/Inf/huge sizes, unstarted app, repeated calls, region restore, no screen change, hidden subtrees, custom layout, widget render error | Works; **minor** input validation gap with `Inf`/>2^31 (see S-1) |
| `Pilot$wait_until_exit()` | testing.R | NA/0/huge/tiny interval, exit w/o value, callback error, worker busy | Correct; contrived `interval` ~1e-12 gives effectively unbounded loop (S-2) |
| `visible=` on label/vertical/horizontal/grid/widget() | widget-*.R | NA/NULL/non-logical/length 2, hide/show relayout | Validated by existing `check_flag`; OK |
| Deferred key-focus targeting (marker env) | app.R | Tab+Enter batching, removal of focused widget, post-exit events, event log, PTY combined input | OK; `pty-check.py` `combined_focus_session` passes in WSL |
| KeyParser chunk-invariance tests | tests only | fuzzed chunking in 70+ PTY runs | OK |
| `pty-check.py` combined-focus case | tools | ran in WSL | all PASS |
