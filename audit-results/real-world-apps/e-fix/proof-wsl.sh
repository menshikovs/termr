#!/usr/bin/env bash
set -u
cd /mnt/c/programming_pj/r_textualize || exit 2
export LC_ALL=C.UTF-8 NOT_CRAN=true
Rscript tools/integration/run-all.R --mode=api,gates,unit,process,expect,tmux,recording,lint,profile,benchmark --timeout=240 --out=audit-results/real-world-apps/e-fix/proof-wsl > audit-results/real-world-apps/e-fix/proof-wsl.log 2>&1
echo $? > audit-results/real-world-apps/e-fix/proof-wsl.exit
TERMR_E_ARTIFACTS="$PWD/audit-results/real-world-apps/e-fix/proof-coverage" Rscript integration-apps/automation/coverage-apps.R > audit-results/real-world-apps/e-fix/proof-coverage.log 2>&1
echo $? > audit-results/real-world-apps/e-fix/proof-coverage.exit
