#!/usr/bin/env bash
set -u
cd /mnt/c/programming_pj/r_textualize || exit 2
export R_LIBS_USER="$PWD/integration-apps/.deps/current-linux:$PWD/integration-apps/.deps/R-linux:/home/user001/R/x86_64-pc-linux-gnu-library/4.5"
export LC_ALL=C.UTF-8 NOT_CRAN=true _R_CHECK_FORCE_SUGGESTS_=false TERMR_PROJECT_ROOT="$PWD"
export TERMR_E_ARTIFACTS="$PWD/audit-results/real-world-apps/e-fix/tests-final-wsl"
Rscript integration-apps/automation/run-app-tests.R all > audit-results/real-world-apps/e-fix/tests-final-wsl.log 2>&1
echo $? > audit-results/real-world-apps/e-fix/tests-final-wsl.exit
Rscript tools/dev.R test > audit-results/real-world-apps/e-fix/core-wsl.log 2>&1
echo $? > audit-results/real-world-apps/e-fix/core-wsl.exit
mkdir -p audit-results/real-world-apps/e-fix/check-wsl
cd audit-results/real-world-apps/e-fix/check-wsl || exit 2
R CMD build --no-build-vignettes ../package-source > build.log 2>&1
code=$?
echo "$code" > build.exit
if [ "$code" -eq 0 ]; then
  R CMD check --no-manual --no-build-vignettes termr_1.0.1.tar.gz > check.log 2>&1
  echo $? > check.exit
fi
