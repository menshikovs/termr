#!/bin/sh
set -eu

TERMR_A22_SOURCE=/tmp/termr-a2.2-source
TERMR_A22_REPORT=/mnt/c/programming_pj/r_textualize/audit-results/advanced-types/haven
mkdir -p "$TERMR_A22_SOURCE" "$TERMR_A22_REPORT"
rsync -a \
  --exclude='.git/' \
  --exclude='.playwright-mcp/' \
  --exclude='.serena/' \
  --exclude='.agents/' \
  --exclude='audit-results/' \
  --exclude='docs/' \
  --exclude='site/' \
  --exclude='pkgdown/' \
  --exclude='tools/' \
  --exclude='.github/' \
  --exclude='.Rproj.user/' \
  --exclude='*.Rproj' \
  /mnt/c/programming_pj/r_textualize/ "$TERMR_A22_SOURCE/"
cd "$TERMR_A22_REPORT"
R CMD build "$TERMR_A22_SOURCE" --no-build-vignettes --no-manual > build-wsl.log 2>&1
cat build-wsl.log
