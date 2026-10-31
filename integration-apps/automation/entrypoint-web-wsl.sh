#!/usr/bin/env bash
set -u
cd /mnt/c/programming_pj/r_textualize || exit 2
target=$1
export LC_ALL=C.UTF-8 TERMR_PROJECT_ROOT="$PWD"
unset TERMR_USE_INSTALLED
export TERMR_E_SERVER_READY="$target/ready.json" TERMR_E_STOP="$target/STOP" TERMR_E_EVENTS="$target/events.jsonl"
export R_PROFILE_USER="$PWD/integration-apps/automation/entrypoint-profile.R" TERMR_E_RUNTIME="$target/runtime.json"
Rscript integration-apps/run.R --app=analytics --mode=web > "$target/stdout.log" 2> "$target/stderr.log"
code=$?
echo "$code" > "$target/server-exit-code.txt"
exit "$code"
