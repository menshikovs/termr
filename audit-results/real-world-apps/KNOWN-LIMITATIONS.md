# Phase E — Known Limitations

1. Native Windows attached-console behavior is NOT RUN. Windows R headless,
   parser, process tests and Chrome are covered; real terminals were WSL POSIX.
   macOS, SSH, RStudio Terminal and arbitrary emulator combinations are untested.
2. Windows lacks bit64/units/haven/hms/sf/RSQLite/dbplyr in the selected libraries;
   corresponding core tests skip and showcase fixtures are conditional. WSL runs
   those available integration/type paths. No absent-package path is labelled PASS.
3. Direct mirai on Windows reproduces approximately 2 retained handles per new
   compute profile. This P2 backend risk remains open for H4 despite stable RSS
   and terminated workers. Private native allocation ownership is not inferred.
4. Core covr run excludes project-only native/inkr integrations while retaining
   their uncovered denominator. App worker compute is uninstrumented. Branch
   coverage and Windows covr are unmeasured; function-label hit metrics group
   some nested/anonymous methods.
5. Default lintr retains substantial new style debt and pre-existing core
   findings. Completion/zero parse errors does not mean lint-clean code.
6. Profiling required a disclosed derived-copy repair for multiline Shiny debug
   labels. Raw data is retained. One earlier rtop/asciinema run hit transient
   errno61; final and standalone repeats passed, portability is not guaranteed.
7. Finite resource/latency series are not a soak test. Hyperfine5-run samples
   overlapped some validation activity and cannot establish performance regressions
   or compare OS speeds. rtop baseline/candidate workload is broader than app startup.
8. Workbench charts use original finite dataset values, not current table filter
   results. Unknown S3/vctrs fixtures remain read-only. A4 uses app-local clipboard.
   No exact round-trip claim is added for unsupported types. A one-point Plotly
   lines-only trace has no visible segment until another sample arrives.
9. Candidate package metadata remains1.0.1. Compatibility establishes current API
   behavior, not a published2.0.0 release/version-gate contract.
10. Three H2 test files differ from the initial manifest; provenance is unresolved.
    Current versions were retained and originals/diffs archived. All R core/man/API
    hashes are unchanged; a blanket byte-for-byte preservation claim is inappropriate.

No known open P0/P1 was found in the tested paths. These limitations are explicit
handoff items, not claims that unsupported workloads are safe.
