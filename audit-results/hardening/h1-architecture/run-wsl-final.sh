#!/usr/bin/env bash
set -u
cd /mnt/c/programming_pj/r_textualize || exit 2
out=audit-results/hardening/h1-architecture
archive="$PWD/$out/build/termr_1.0.1.tar.gz"
test -f "$archive" || exit 3
mkdir -p /tmp/termr-h1-lib /tmp/termr-h1-check
export R_LIBS_USER=/tmp/termr-h1-lib:/home/user001/R/x86_64-pc-linux-gnu-library/4.5
export LANG=C.UTF-8 LC_ALL=C.UTF-8 TERM=xterm-256color NOT_CRAN=true
export _R_CHECK_FORCE_SUGGESTS_=false
R CMD INSTALL -l /tmp/termr-h1-lib /mnt/c/programming_pj/ink-for-r > "$out/install-inkr-wsl-final.log" 2>&1 || exit 4
R CMD INSTALL -l /tmp/termr-h1-lib "$archive" > "$out/install-package-wsl-final.log" 2>&1 || exit 5
sha256sum "$archive" > "$out/archive-sha256-wsl.txt"
Rscript "$out/inventory.R" > "$out/inventory-wsl-final.log" 2>&1
echo $? > "$out/inventory-wsl-final.exit"
Rscript "$out/probe-contracts.R" > "$out/probes-wsl-final.log" 2>&1
echo $? > "$out/probes-wsl-final.exit"
Rscript "$out/run-open-regressions.R" > "$out/open-regressions-wsl.log" 2>&1
echo $? > "$out/open-regressions-wsl.exit"
Rscript -e 'testthat::test_local(".", filter="h1-contracts|datatable|native-charts|chart-streams|inkr-integration|streams|mirai|nanonext|plotly", reporter="summary")' > "$out/focused-wsl.log" 2>&1
echo $? > "$out/focused-wsl.exit"
R_LIBS_USER=/home/user001/R/x86_64-pc-linux-gnu-library/4.5 Rscript audit-results/inkr-integration/run-focused-tests.R > "$out/optional-free-wsl.log" 2>&1
echo $? > "$out/optional-free-wsl.exit"
Rscript tools/dev.R test > "$out/full-wsl.log" 2>&1
suite_status=$?
echo "$suite_status" > "$out/full-wsl.exit"
tail -n 5 "$out/full-wsl.log"
NOT_CRAN=false R CMD check --no-manual --no-vignettes --output=/tmp/termr-h1-check "$archive" > "$out/check-wsl-console.log" 2>&1
check_status=$?
echo "$check_status" > "$out/check-wsl.exit"
cp /tmp/termr-h1-check/termr.Rcheck/00check.log "$out/check-wsl.log"
cp /tmp/termr-h1-check/termr.Rcheck/tests/testthat.Rout "$out/check-wsl-testthat.Rout"
Rscript tools/pty/test-fixture.R > "$out/pty-fixture-wsl-final.log" 2>&1
echo $? > "$out/pty-fixture-wsl-final.exit"
python3 tools/pty/pty-check.py > "$out/pty-full-wsl.log" 2>&1
echo $? > "$out/pty-full-wsl.exit"
for iteration in 1 2; do
  python3 tools/pty/pty-check.py --case combined_focus_session > "$out/pty-combined-wsl-repeat-$iteration.log" 2>&1
  echo $? > "$out/pty-combined-wsl-repeat-$iteration.exit"
done
python3 tools/pty/pty-check-binary.py > "$out/pty-binary-wsl.log" 2>&1
echo $? > "$out/pty-binary-wsl.exit"
tail -n 5 "$out/check-wsl.log"
tail -n 6 "$out/pty-full-wsl.log"
cat "$out/probes-wsl-final.log"
if test "$suite_status" -ne 0 || test "$check_status" -ne 0; then exit 1; fi
