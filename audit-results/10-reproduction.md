# 10 Reproduction commands

Windows (Git Bash), from the repository root; `export PATH="/c/Program Files/R/R-4.6.1/bin:$PATH"` first.

```
Rscript tools/dev.R test                          # full suite (about 5 min)
Rscript audit-results/probe-new-api.R             # layout_diagnostics / visible / wait_until_exit probes
Rscript audit-results/diff-fuzz.R 120 50          # incremental vs full render, seeds x ops
Rscript audit-results/widget-matrix.R             # widget x text x size matrix
Rscript audit-results/parser-fuzz.R               # KeyParser byte fuzz
Rscript audit-results/lifecycle-fuzz.R            # events / timers / screens / workers / memory
Rscript audit-results/perf.R ; Rscript audit-results/prof.R
Rscript audit-results/p7.R                        # B-1 repro matrix (before the fix: 4 failing combinations)
Rscript audit-results/p9.R                        # B-2 repro (stale scroll bar)
Rscript audit-results/p13.R                       # B-3 repro (wide glyph dropped)
```

ConPTY (needs a scratch install of the tree and `tools/validation-0.4/python-packages`):
```
R CMD INSTALL --library=<scratch>/winlib <clean copy of tree>
R_LIBS=<scratch>/winlib RSCRIPT="C:/Program Files/R/R-4.6.1/Rscript.exe" PYTHONPATH=tools/validation-0.4/python-packages \
  python tools/e2e-windows.py tools/e2e/hello.json        # also audit-results/pty/conpty-*.json (TERMR_PTY_LOG must be set)
```

WSL (run through `MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu -- bash /mnt/c/programming_pj/r_textualize/audit-results/<script>`):
```
wsl-setup.sh      # copy tree (without audit-results/.git/site/docs) to ~/audit/src and install to ~/audit/lib
wsl-pty.sh        # tools/pty/pty-check.py against that install
pty/run.sh        # pexpect fuzz over 7 sizes + signals (pty-fuzz.py)
pty/run2.sh       # seeded crash hunt (crashhunt.py N); failing runs are written to pty/crash-<seed>.json
audit-results/p5.R pty/crash-<seed>.json   # headless replay of a recorded PTY input stream
wsl-suite.sh      # full suite on Linux;  wsl-cov.sh  # covr;  wsl-perf.sh  # hyperfine startup
```

Verify the regression tests detect the bugs: revert one hunk (for example remove the `if (!length(visible)) return(...)` line in
`R/widget-input.R`) and run `Rscript -e "testthat::test_local('.', filter = 'input')"`; the new test fails.
