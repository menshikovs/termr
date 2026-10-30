# Reproduction (run from the repository root; Git Bash; `export PATH="/c/Program Files/R/R-4.6.1/bin:$PATH"`)

All scripts live in `audit-results/phase-3/` unless noted; raw outputs are in `audit-results/phase-3/logs/`.

```
# benchmarks (set PKG=<path to another source tree> to benchmark it instead)
Rscript audit-results/phase-3/bench-keypress.R baseline      # -> logs/bench-baseline.csv (measured before O-1)
Rscript audit-results/phase-3/bench-keypress.R after-opt     # -> logs/bench-after-opt.csv
TAG=after Rscript audit-results/phase-3/bench-phases.R       # -> logs/phases-after.csv
Rscript audit-results/phase-3/prof-tab.R                     # Rprof of a Tab press (VirtualTerminal cost)
# correctness
Rscript audit-results/phase-3/reactive-fuzz.R 600 40         # model-based reactive graph fuzz + directed cases
Rscript audit-results/phase-3/reactive-widgets.R
Rscript audit-results/phase-3/layout-props.R 300
Rscript audit-results/phase-3/layout-numeric.R > logs/layout-numeric.log     # C-1 / C-2 (fails before the fix)
Rscript audit-results/phase-3/parser-chunking.R 3000
Rscript audit-results/phase-3/diff-fuzz2.R 200 60
Rscript audit-results/phase-3/cursor-state.R ; Rscript audit-results/phase-3/p-unmount.R
# memory
Rscript audit-results/phase-3/memory-stress.R                # 1k and 10k events
Rscript audit-results/phase-3/memory-stress-100k.R           # about 16 minutes
Rscript audit-results/phase-3/memory-attrib2.R ; memory-plateau.R ; memory-plateau2.R ; memory-bisect.R ; memory-locate3.R
# tests
Rscript -e "testthat::test_local('.', filter='input|style|scroll|renderer|layout', reporter='summary')"
Rscript tools/dev.R test
```

WSL (prefix: `MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu -- bash /mnt/c/programming_pj/r_textualize/audit-results/...`):
`wsl-setup.sh` (install current tree), `wsl-pty.sh` (pty-check.py), `pty/run2.sh` (seeded crash hunt),
`phase-3/pty/run-exc.sh` (render / layout / timer / worker / unmount error scenarios), `wsl-suite.sh` (full suite).

Check that the regression tests catch the problems: in `R/widget-input.R` make `paint_only_change` return `TRUE` unconditionally
(tests in `test-input.R` fail, 5 failures); remove the `clamp_cells` call in `parse_size` (tests in `test-style.R` fail).

Note: the first `bench-keypress.R baseline` run was taken with the tree at the end of phase 1, before any phase 3 edit.
