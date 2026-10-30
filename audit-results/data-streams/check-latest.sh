#!/usr/bin/env bash
set -euo pipefail
cd /mnt/c/programming_pj/r_textualize
export TERMR_TEST_FILTER='streams|monitor-live'
Rscript --vanilla audit-results/data-streams/check-local.R latest > audit-results/data-streams/check-wsl-latest.log 2>&1
