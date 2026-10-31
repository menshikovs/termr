# Phase E — Rtop Compatibility

Upstream: https://github.com/menshikovs/rtop at
`0856d8c1dc33c0c9c7ca6bf0d94204349be56722`, clean isolated `upstream/` checkout.
Baseline: exact local Git tag v1.0.1 at
`79d6871d18f700197a31a17b7756c424c5ac7d66`, separately installed in
`.deps/baseline-linux` (also installed on Windows, where Linux collectors cannot run).
Candidate: current branch source, separately installed in `.deps/R-linux`.

`legacy-source.json` records provenance. Both packages report 1.0.1; the current
checkout was never relabelled2.0.0. Thus the unchanged upstream version gate
accepts this candidate already. `rtop-version-gate.patch` extends only the gate
to permit 2.0.0 in a separate compatibility copy; no upstream UI/module was edited.

```sh
Rscript integration-apps/legacy-rtop/run.R --library=baseline --mode=headless
Rscript integration-apps/legacy-rtop/run.R --library=candidate --mode=headless
python3 integration-apps/automation/pty-e2e.py --app=rtop --legacy-library=baseline
```

| Scenario | Values equal | Screen equal | State equal |
| --- | --- | --- | --- |
| startup | True | True | True |
| refresh | True | True | True |
| sort-c | True | True | True |
| sort-m | True | True | True |
| sort-p | True | True | True |
| filter | True | True | True |
| selection | True | True | True |
| resize-small | True | True | True |
| resize-large | True | True | True |
| controls | True | True | True |
| shutdown | True | True | True |


Only wall-clock HH:MM:SS is normalized. Original widgets, state, formatters,
keyboard bindings, refresh logic and resize behavior are used. Deterministic
collector substitution is confined to the wrapper and disclosed; terminal mode
delegates to real exported `run()`. Original upstream tests ran unchanged with
live `/proc` collectors for both libraries: exit 0, `rtop checks passed` in
`rtop-upstream-baseline.log` and `rtop-upstream-candidate.log`.

Baseline/candidate PTY, candidate tmux and fixture-only asciinema all pass.
`rtop-comparison.csv`, both RDS snapshots, `pty-baseline/results.json`,
`final-wsl/pty/results.json` and `final-recordings/recording/rtop.cast` retain
evidence. No API adapter beyond the optional version-gate copy was needed.
No incompatibility was hidden by rewriting rtop. Linux-specific collectors and
finite fixture coverage limit the compatibility conclusion.
