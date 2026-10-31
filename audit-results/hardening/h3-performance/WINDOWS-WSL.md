# Platform and dependency matrix

Native Windows R 4.6.1 and WSL Ubuntu R 4.5.2 are independent validation targets.
packages-windows.csv and packages-unix.csv record installed optional versions.
Temporary inkr 0.1.0 libraries use the independent sibling checkout; neither
its source nor a global user library was modified. inkr session behavior is
documented against that installed checkout, not assumed from a newer release.

Windows full suite: TOTAL: 17090 tests, 0 failed, 0 errors, 94 skipped, 0 warnings

Windows check: Status: OK

WSL full suite: TOTAL: 18618 tests, 0 failed, 0 errors, 30 skipped, 0 warnings

WSL check: Status: OK

Each platform builds its own archive from the frozen final working files;
SHA-256 artifacts record archive identity and archive-source-verification.json
checks every packaged R/test source against the workspace. The final archives
are under final-validation-ring/build and final-validation-ring/build-wsl.
_R_CHECK_FORCE_SUGGESTS_=false permits absent optional
dependencies and is not complete Suggests coverage. Missing mirai/nanonext/
duckdb scenarios must remain explicit. WSL has the broader DBI/SQLite/Arrow/
dbplyr/units/haven/sf/lubridate/blob matrix; Windows's absences are visible in
its manifest and skip list.

Windows validation runs outside the restricted sandbox because processx pipe
creation is blocked there. This is an environment constraint, not a termr test
failure. WSL uses C.UTF-8; native Windows clears invalid inherited LC_* values
before R starts. Headless Unicode and parser tests run in the suites. Live
POSIX PTY, binary safety and combined Tab+Enter restoration tests are separate
logs. No current macOS CI or real Windows console session was run; historical
platform reports are not reused as H3 passes.

Use run-windows-ring.ps1 and run-wsl-ring.sh for this final candidate. Preparing
their staging copy requires the trusted earlier archive plus the current R/test
overlay; ring-stage.json records that source set. The first WSL invocation
selected docker-desktop by default, and the first audit shell script needed LF
normalization. Final runs explicitly use `wsl.exe -d Ubuntu` and LF scripts.
These launch/staging issues are not represented as passing package checks.
