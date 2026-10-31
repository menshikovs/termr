# Repository baseline

- Date: 2026-10-31, user timezone Europe/Riga.
- Branch: 2.0-termr.
- HEAD: 1b10370d1df50e54a63706673b150feaf7b04889.
- DESCRIPTION: termr 1.0.1, R >= 4.1.0.
- Staged changes at entry: none; see git-staged-before-numstat.txt.
- Existing unstaged/untracked work: see git-status-before.txt and
  git-diff-before-numstat.txt. A1/A2/A3.5/A4/C1/B code was already present.
- Hashed non-audit files at entry: 563. Counts by path:
  R/ 105, tests/ 119, inst/ 49, docs/ 50, man/ 143, tools/ 57.

The working tree, including untracked R source, was the audit target. HEAD was
used only for compatibility comparison, not as a replacement for that tree.
No remote main comparison or fetch was needed.

Current inventory: 170 exports, five additive chart constructors,
78 local R6 class generators. exports.csv, function-signatures.csv,
r6-classes.csv and namespace-usage.csv record reproducible inventories.
Existing audit reports were treated as historical hypotheses. In particular,
old PTY failure and backend-completion claims were checked against fresh
executions and current source rather than copied as conclusions.

baseline-files.csv stores SHA256 values. preservation.csv and git-status-after.txt
record final preservation evidence. H1 source changes are restricted to
R/testing.R, three lines of source-cache key construction in
R/widget-datatable.R, and tests/testthat/test-h1-contracts.R. The report tree is
new. Roxygen regenerated no changed public Rd topic or NAMESPACE.

Source build/check ran from the complete current package tree. audit-results
is already excluded by .Rbuildignore. The exact tarball is stored under build/
and its Windows/WSL digest is recorded; no “clean” checkout discarded local work.
