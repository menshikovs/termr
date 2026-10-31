#!/bin/sh
repo=/mnt/c/programming_pj/r_textualize
source_win=$(tr -d '\r' < "$repo/audit-results/a2-preflight/check-source-path.txt")
source_dir=$(wslpath -u "$source_win") || exit 2
tarball="$source_dir/termr_1.0.1.tar.gz"
[ -f "$tarball" ] || { echo "Package tarball is missing: $tarball" >&2; exit 2; }
work_dir=$(mktemp -d /tmp/termr-a2-preflight-wsl.XXXXXX) || exit 1
export _R_CHECK_FORCE_SUGGESTS_=false
cd "$work_dir" || exit 1
R CMD check --no-manual --no-build-vignettes "$tarball" > "$repo/audit-results/a2-preflight/check-wsl.log" 2>&1
check_status=$?
printf '%s\n' "$check_status" > "$repo/audit-results/a2-preflight/check-wsl.exit"
tail -n 55 "$repo/audit-results/a2-preflight/check-wsl.log"
exit "$check_status"
