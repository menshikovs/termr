# Phase E — E2E Test Matrix

| Check | Windows | WSL Ubuntu |
| --- | --- | --- |
| Full checkout testthat | 17,238 PASS / 56 SKIP / 0 FAIL / 0 WARN | 18,736 PASS / 2 SKIP / 0 FAIL / 0 WARN |
| Application tests | 83 expectations / 0 FAIL / 0 SKIP | 83 expectations / 0 FAIL / 0 SKIP |
| Processx | 10 cases PASS | 10 cases PASS |
| R CMD build/check | exit 0 / Status: OK | exit 0 / Status: OK |
| Real terminal | Native attached-console NOT RUN | 4 pexpect apps + 2 Expect + 3 tmux PASS |
| Browser | Chrome/Shiny real browser PASS | Browser engine not rerun in WSL |
| Lifecycle | 100 start/stop + 1000 UI + 100 source/theme/chart | Same controlled workload PASS |
| Profiles / hyperfine | PASS / PASS | PASS incl. rtop / PASS |
| Coverage | Not rerun with covr on Windows | Core 79.04%, apps 92.07% line coverage |


Final reproducible runner invocations (checkout root):

```sh
Rscript tools/integration/run-all.R --mode=unit,headless,process,browser,lint --timeout=180 --out=audit-results/real-world-apps/final-windows
Rscript tools/integration/run-all.R --mode=unit,headless,process,legacy,pty,expect,tmux,lint --timeout=180 --out=audit-results/real-world-apps/final-wsl
Rscript tools/integration/run-all.R --mode=recording,lint --timeout=180 --out=audit-results/real-world-apps/final-recordings
```

The first command was run with native Windows R; the second/third inside Ubuntu
WSL. All final task exit codes are0 in each `run-summary.json`. Heavy lifecycle,
profiling, benchmarking and coverage are separate opt-in modes. `--app` focuses
apps, `--out` controls artifacts, `--timeout` is seconds per task. A missing POSIX
platform/tool yields an explicit SKIP; real task failure yields process exit 1.
`runner-skip/run-summary.json` demonstrates skip output; `runner-invalid.exit`
contains1 for invalid mode input. No ordinary R CMD check starts the demo apps.

PTY asserts semantic state plus terminal restoration; browser asserts actual
data/widget behavior. Headless success is never counted as terminal success.
Earlier harness/profiler/recorder failures remain in separate directories and
are classified in BUG-FINDINGS.md; final results do not erase those failures.
