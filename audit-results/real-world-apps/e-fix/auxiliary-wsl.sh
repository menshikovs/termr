#!/usr/bin/env bash
set -u
cd /mnt/c/programming_pj/r_textualize || exit 2
export LC_ALL=C.UTF-8 NOT_CRAN=true
export TERMR_E_ARTIFACTS="$PWD/audit-results/real-world-apps/e-fix/coverage-apps"
Rscript integration-apps/automation/coverage-apps.R > audit-results/real-world-apps/e-fix/coverage-apps.log 2>&1
echo $? > audit-results/real-world-apps/e-fix/coverage-apps.exit
export TERMR_E_ARTIFACTS="$PWD/audit-results/real-world-apps/e-fix/api-final-wsl"
Rscript integration-apps/automation/api-audit.R > audit-results/real-world-apps/e-fix/api-final-wsl.log 2>&1
echo $? > audit-results/real-world-apps/e-fix/api-final-wsl.exit
Rscript tools/integration/run-all.R --mode=process,expect,tmux,recording,lint --timeout=180 --out=audit-results/real-world-apps/e-fix/automation-wsl > audit-results/real-world-apps/e-fix/automation-wsl.log 2>&1
echo $? > audit-results/real-world-apps/e-fix/automation-wsl.exit
Rscript tools/integration/run-all.R --mode=profile,benchmark --timeout=240 --out=audit-results/real-world-apps/e-fix/performance-wsl > audit-results/real-world-apps/e-fix/performance-wsl.log 2>&1
echo $? > audit-results/real-world-apps/e-fix/performance-wsl.exit
