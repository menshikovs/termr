#!/usr/bin/env bash
set -u
cd /mnt/c/programming_pj/r_textualize || exit 2
export R_LIBS_USER="$PWD/integration-apps/.deps/R-linux:/home/user001/R/x86_64-pc-linux-gnu-library/4.5"
export LC_ALL=C.UTF-8 LANG=C.UTF-8 NOT_CRAN=true
export TERMR_PROJECT_ROOT="$PWD" TERMR_USE_INSTALLED=1
Rscript tools/dev.R test > audit-results/real-world-apps/full-wsl.log 2>&1
echo $? > audit-results/real-world-apps/full-wsl.exit
Rscript integration-apps/automation/run-app-tests.R > audit-results/real-world-apps/apps-wsl.log 2>&1
echo $? > audit-results/real-world-apps/apps-wsl.exit
