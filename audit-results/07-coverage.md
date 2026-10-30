# 07 Coverage (covr, WSL, line coverage, full suite including the new tests)

Overall: **86.5%** (raw output: logs/coverage-wsl.log).

Lowest files: widget-process.R 8.3%, terminal-posix.R 40.8% (exercised through forked PTY processes that covr cannot see),
terminal-windows.R 48.6% (Windows only), workers.R 67.2%, layout.R 68.9% (includes new `collect_layout_diagnostics` branches),
events.R 74.4%.

Files touched in this audit: dirty.R 93.2%, widget-scroll.R 93.1%, widget-input.R 94.2%, testing.R 91.6%.
