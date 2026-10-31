#!/bin/sh
repo=/mnt/c/programming_pj/r_textualize
cd "$repo" || exit 2
Rscript tools/dev.R doc > audit-results/a2-preflight/doc-wsl.log 2>&1
doc_status=$?
printf '%s\n' "$doc_status" > audit-results/a2-preflight/doc-wsl.exit
exit "$doc_status"
