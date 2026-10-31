#!/usr/bin/env bash
set -u
cd /mnt/c/programming_pj/r_textualize || exit 2
base=audit-results/hardening/h3-performance
out=$base/final-validation-ring
mkdir -p "$out"
root="$PWD"
candidate="$PWD/$base/final-validation/build/termr_1.0.1.tar.gz"
test -f "$candidate" || exit 3
mkdir -p /tmp/termr-h3-ring-source /tmp/termr-h3-ring-build "$out/build-wsl"
tar -xzf "$candidate" -C /tmp/termr-h3-ring-source || exit 3
cp "$root"/R/*.R /tmp/termr-h3-ring-source/termr/R/
cp -R "$root"/tests/. /tmp/termr-h3-ring-source/termr/tests/
(cd /tmp/termr-h3-ring-build && R CMD build --no-build-vignettes --no-manual /tmp/termr-h3-ring-source/termr) > "$out/build-wsl.log" 2>&1
build_status=$?
echo "$build_status" > "$out/build-wsl.exit"
test "$build_status" -eq 0 || exit 3
cp /tmp/termr-h3-ring-build/termr_1.0.1.tar.gz "$out/build-wsl/termr_1.0.1.tar.gz"
archive="$PWD/$out/build-wsl/termr_1.0.1.tar.gz"
mkdir -p /tmp/termr-h3-ring-lib /tmp/termr-h3-ring-check
export R_LIBS_USER=/tmp/termr-h3-ring-lib:/home/user001/R/x86_64-pc-linux-gnu-library/4.5
export LANG=C.UTF-8 LC_ALL=C.UTF-8 TERM=xterm-256color NOT_CRAN=true
export _R_CHECK_FORCE_SUGGESTS_=false
R CMD INSTALL -l /tmp/termr-h3-ring-lib /mnt/c/programming_pj/ink-for-r > "$out/install-inkr-wsl-final.log" 2>&1 || exit 4
R CMD INSTALL -l /tmp/termr-h3-ring-lib "$archive" > "$out/install-package-wsl-final.log" 2>&1 || exit 5
sha256sum "$archive" > "$out/archive-sha256-wsl.txt"
Rscript "$base/platform-inventory.R" > "$out/inventory-wsl.log" 2>&1
echo $? > "$out/inventory-wsl.exit"
Rscript "$base/resource-cycles.R" > "$out/resource-cycles-wsl.log" 2>&1
echo $? > "$out/resource-cycles-wsl.exit"
Rscript -e 'testthat::test_local(".", filter="h3-performance-contracts|h2-|h1-contracts|datatable|native-charts|chart-streams|inkr-integration|streams|mirai|nanonext|plotly", reporter="summary")' > "$out/focused-wsl.log" 2>&1
echo $? > "$out/focused-wsl.exit"
R_LIBS_USER=/home/user001/R/x86_64-pc-linux-gnu-library/4.5 Rscript audit-results/inkr-integration/run-focused-tests.R > "$out/optional-free-wsl.log" 2>&1
echo $? > "$out/optional-free-wsl.exit"
Rscript tools/dev.R test > "$out/full-wsl.log" 2>&1
suite_status=$?
echo "$suite_status" > "$out/full-wsl.exit"
tail -n 5 "$out/full-wsl.log"
NOT_CRAN=false R CMD check --no-manual --no-vignettes --output=/tmp/termr-h3-ring-check "$archive" > "$out/check-wsl-console.log" 2>&1
check_status=$?
echo "$check_status" > "$out/check-wsl.exit"
cp /tmp/termr-h3-ring-check/termr.Rcheck/00check.log "$out/check-wsl.log"
cp /tmp/termr-h3-ring-check/termr.Rcheck/tests/testthat.Rout "$out/check-wsl-testthat.Rout"
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

if test "$suite_status" -ne 0 || test "$check_status" -ne 0; then exit 1; fi
