#!/usr/bin/env bash
set -u
cd /mnt/c/programming_pj/r_textualize || exit 2
export LC_ALL=C.UTF-8 TERMR_USE_INSTALLED=1
Rscript tools/integration/run-all.R --mode=unit,headless,process,lifecycle,lint,profile,benchmark --timeout=600 --out=audit-results/real-world-apps/runner-wsl > audit-results/real-world-apps/runner-wsl.log 2>&1
echo $? > audit-results/real-world-apps/runner-wsl.exit
python3 integration-apps/automation/pty-e2e.py --app=showcase --crash --out=audit-results/real-world-apps/pty-crash > audit-results/real-world-apps/pty-crash.log 2>&1
echo $? > audit-results/real-world-apps/pty-crash.exit
python3 integration-apps/automation/pty-e2e.py --app=rtop --legacy-library=baseline --out=audit-results/real-world-apps/pty-baseline > audit-results/real-world-apps/pty-baseline.log 2>&1
echo $? > audit-results/real-world-apps/pty-baseline.exit
Rscript tools/integration/run-all.R --mode=recording --timeout=300 --out=audit-results/real-world-apps/recordings > audit-results/real-world-apps/recordings.log 2>&1
echo $? > audit-results/real-world-apps/recordings.exit
