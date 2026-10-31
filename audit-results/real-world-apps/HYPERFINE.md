# Phase E — Hyperfine

Real external-process benchmarks use one warmup and five measurements, exit 0
throughout. Windows hyperfine 2.0.0 uses schema2 JSON; WSL 1.19.0 uses schema1.
Both original JSON formats are retained, not rewritten to hide version changes.

| Platform | Scenario | Mean ms | SD ms | Runs |
| --- | --- | --- | --- | --- |
| Windows | showcase | 1335.7 | 99.1 | 5 |
| Windows | analytics | 867.5 | 30.8 | 5 |
| Windows | monitor | 1395.7 | 32.9 | 5 |
| WSL | showcase | 1496.6 | 43.7 | 5 |
| WSL | analytics | 835.6 | 75.9 | 5 |
| WSL | monitor | 1399.3 | 42.5 | 5 |
| WSL | rtop-baseline | 2869.4 | 94.6 | 5 |
| WSL | rtop-candidate | 3058.3 | 31.7 | 5 |


App commands launch installed-candidate Rscript, create a headless app, render
an initial frame (`--steps=0`) and cleanly close it. Monitor includes real worker
and socket startup/teardown. These are whole-process CLI measurements, not
microbenchmarks of pure R calls, PTY response times or steady-state rendering.
rtop commands additionally execute eleven deterministic scenarios, so their
absolute times are not comparable with an app's startup-only scenario.

WSL candidate rtop mean is about 6.6% above genuine baseline in this short run.
The packages differ substantially before Phase E, and other validation jobs
overlapped; this is descriptive evidence, not a controlled regression attribution
or an improvement claim. Repeat on an idle same-platform machine with more runs
before setting a performance gate. Cross-platform wall times are not rankings.

Artifacts: `runner-windows-final/hyperfine.json`, `runner-wsl/hyperfine.json`,
stdout/stderr logs and `benchmark-scope.json`. Reproduce with
`Rscript tools/integration/run-all.R --mode=benchmark --timeout=180`.
