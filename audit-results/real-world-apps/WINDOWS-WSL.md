# Phase E — Windows Wsl

Windows 11 build26100, native R4.6.1; Ubuntu 26.04.1 on WSL2, R4.5.2,
Linux6.18.54.1-microsoft-standard-WSL2. WSL commands explicitly selected Ubuntu
(the default distro is docker-desktop and unsuitable for these shell scripts).
Windows invalid inherited LC_* variables were removed in child launch shells;
WSL ran C.UTF-8. Python is3.14.4 on both platforms.

| Package | Windows | WSL |
| --- | --- | --- |
| inkr | 0.1.0 | 0.1.0 |
| mirai | 2.7.3 | 2.7.3 |
| nanonext | 1.10.3 | 1.10.4 |
| shiny | 1.14.0 | 1.10.0 |
| ggplot2 | 4.0.3 | 4.0.2 |
| plotly | 4.12.1 | 4.10.4 |
| processx | 3.9.0 | 3.9.0 |
| covr | 3.6.5 | 3.6.5 |
| lintr | 3.4.0 | 3.3.0.1 |
| profvis | 0.4.0 | 0.4.0 |


Executable versions/paths and availability are in `tools-windows.json` and
`tools-wsl.json`. `packages-*.csv` preserve full final library paths;
`*-initial.csv` preserve discovery state. Missing optional web/native packages
were installed only into `.deps/R-windows`/`.deps/R-linux`; inkr 0.1.0 was installed
from the sibling source without modifying it. Baseline and candidate termr have
separate libraries. Windows Python Playwright 1.64.1 is under `.deps/python-windows`;
the existing Chrome executable was used. No global installation was performed.

Both R CMD build and check exit 0, `Status: OK`, using `--no-manual
--no-build-vignettes` (no PDF manual/vignette validation claim). `_R_CHECK_FORCE_SUGGESTS_=false`
permits unavailable optional packages; their actual test skips remain visible.
Neither platform reports WARNING/NOTE/ERROR in final00check.log. Windows
PowerShell redirected ordinary native stderr as NativeCommandError text in the
wrapper log; authoritative R exit/00check.log and test counts are retained.

Real Unicode/control/resize/restoration checks ran through Linux PTY/Expect/tmux.
Windows parser/headless tests passed, but no native attached-console run is
claimed. Browser tests used native Windows Chrome. No macOS/SSH/RStudio test ran.

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
