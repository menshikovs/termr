# Implementation and scope

New maintained files:

- R/shiny_streams.R, R/stream_data.R; generated man/shiny_streams.Rd,
  man/termr_shiny_receiver.Rd, man/termr_stream_data.Rd and five NAMESPACE exports.
- inst/examples/system-monitor-live/dashboard.R, visualization.R,
  ggplot_history.R and README launch/lifecycle instructions.
- tests/testthat/test-shiny-streams.R, test-shiny-process.R, test-stream-data.R,
  test-plotly-live.R and fixtures/shiny_stream_child.R.
- docs/shiny.md, docs/plotly.md, docs/data-stream-visualization.md.

Updates: DESCRIPTION Suggests, NEWS, README, stability and API inventory.
.Rbuildignore excludes the browser tool's local artifact directory. Existing
stream, signal, app, widget, layout and terminal implementations are unchanged
relative to the task's initial 467-file hash manifest. Initial user edits remain.

Evidence-driven corrections:

1. Dashboard observer cursor required enclosing assignment (`<<-`); ordinary
   assignment reset it every run and sent full history repeatedly. Regression
   test proves initial restyle, ordered extend, idle noop and gap replacement.
2. A new publisher with an empty snapshot must clear the previous cached value.
3. Ready native packets are drained with nonblocking recv after the completed
   AIO, bounded by max_messages. Rearming AIO per packet usually delivered only
   one packet per poll and fell behind busy graphs. Pending AIO count stays <=2.
4. One frame conversion per receiver revision is cached across sessions.
5. Acknowledgements bound per-session Plotly commands; 500 ms dashboard batching
   gives reactive fanout time to yield to HTTP. Generic API default stays 50 ms.
6. The owned widget omits a redundant legacy typedarray dependency requiring an
   absent GLOBAL loader. Complete scratch CRAN Shiny assets fix the tested
   system Shiny 1.10.0 strftime asset mismatch. Third-party files are unmodified.
7. Owned processx launchers now use env=c("current",...). A partial environment
   caused Windows native exits, including scripts with no nanonext. This fixes
   tools/data-streams-integration.R, tools/nanonext_integration.R and the nano
   subprocess test. Existing R/workers.R already preserved current environment.

Roxygen: Rscript tools/dev.R doc in WSL; then restore unrelated baseline help
rewritten by a different installed roxygen version. No new help was hand-edited.
No commit, staging, push, release, public bind or system installation performed.
