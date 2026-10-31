#!/usr/bin/env bash
set -u
cd /mnt/c/programming_pj/r_textualize || exit 2
export LC_ALL=C.UTF-8 NOT_CRAN=false
# No project optional library for the core instrumentation process.
R_LIBS_USER=/home/user001/R/x86_64-pc-linux-gnu-library/4.5 Rscript integration-apps/automation/coverage-core.R > audit-results/real-world-apps/coverage-core.log 2>&1
echo $? > audit-results/real-world-apps/coverage-core.exit
TERMR_USE_INSTALLED=1 Rscript integration-apps/automation/coverage-apps.R > audit-results/real-world-apps/coverage-apps.log 2>&1
echo $? > audit-results/real-world-apps/coverage-apps.exit
