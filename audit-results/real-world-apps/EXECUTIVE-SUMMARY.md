# Phase E — Executive Summary

Three working applications and opt-in automation are implemented outside the
package core. All final runner tasks passed on their applicable platforms.
One confirmed application shortcut defect was reproduced failing-first and
fixed. No new termr core defect requiring a code fix was confirmed.

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


rtop's eleven fixture scenarios are identical between the genuine release
baseline and the candidate, including normalized screen text. Original upstream
tests and real Linux collectors pass against both. The candidate DESCRIPTION
still says 1.0.1; this is explicitly not a version 2.0.0 release claim.

Windows repeated native compute-profile creation retains approximately two OS
handles per cycle after warmup. A separate direct-mirai reproducer shows the
same trend without termr. This remains an open P2 optional-backend/H4 risk;
worker shutdown and stable RSS are not proof of leak-free native resources.
Native Windows attached-console behavior is not certified. lintr has style
debt (see LINTR.md), and branch coverage is unmeasured.

```sh
Rscript integration-apps/run.R --app=showcase --mode=terminal
Rscript integration-apps/run.R --app=analytics --mode=terminal
Rscript integration-apps/run.R --app=analytics --mode=web
Rscript integration-apps/run.R --app=monitor --mode=terminal
```

On this machine prepend `& 'C:/Program Files/R/R-4.6.1/bin/Rscript.exe'` instead
of `Rscript` in PowerShell. Run commands from the checkout root. Full controls,
isolated dependencies and runner modes are documented in
`../../integration-apps/README.md`.

The checkout remains `2.0-termr` at `1b10370d1df50e54a63706673b150feaf7b04889`.
No commit, push, release, version change or staging was performed. R source,
DESCRIPTION, NAMESPACE and man/ match the Phase E initial hashes. `.Rbuildignore`
adds only exclusions for `integration-apps` and the pre-existing `typescript`
terminal recording (the original recording was retained).

The final hash audit found three H2 test files differing from the initial
snapshot: two trailing-newline changes and a stream-backlog test rewrite in
`test-h2-contracts.R`. Their origin is not established. Current contents were
retained; exact initial bytes, SHA256 and diffs are in
`preservation-baseline/` and `preservation-results.json`. Therefore this report
does not claim that every initial file remained byte-identical: 564 of 568 did.
No core H1/H2/H3 implementation fixes were reverted. Both final tarballs were
checked against 374 current R/man/test/metadata inputs; generated DESCRIPTION
fields/DCF folding are accounted for. Applications, runtime data, audits and
the recording are absent from both 443-entry source archives.

Evidence index: APPLICATIONS.md, E2E-TEST-MATRIX.md, RTOP-COMPATIBILITY.md,
COVERAGE.md, RESOURCE-LIFECYCLE.md, KNOWN-LIMITATIONS.md and H4-HANDOFF.md.
