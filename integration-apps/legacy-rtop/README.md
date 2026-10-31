# Legacy rtop compatibility

The isolated read-only checkout is `upstream/` at
`0856d8c1dc33c0c9c7ca6bf0d94204349be56722` from
https://github.com/menshikovs/rtop. The exact termr release baseline is tag
v1.0.1, commit `79d6871d18f700197a31a17b7756c424c5ac7d66`.

```sh
Rscript integration-apps/legacy-rtop/run.R --library=baseline --mode=headless
Rscript integration-apps/legacy-rtop/run.R --library=candidate --mode=headless
Rscript integration-apps/legacy-rtop/run.R --library=candidate --mode=terminal
```

These run the original modules with deterministic collector fixtures and an
instrumented exported `run()` boundary. Terminal mode still calls the real POSIX
driver. `--fixtures=false` uses original live collectors; do not record private
live process data. Upstream's own `tests/run-tests.R` was also run unchanged
against both libraries and real Linux `/proc`.

`prepare.py` creates a separate compatibility copy with only the entrypoint's
version gate extended to permit2.0.0. The upstream checkout is never rewritten.
The current candidate metadata remains1.0.1, so the unchanged gate already
accepts it. The compatibility patch is an adapter for a future version number,
not evidence that a new API or version shim was necessary.

Reports contain eleven exact fixture state/screen comparisons, source hashes,
headless/PTY results and whole-process hyperfine comparisons. Windows cannot
validate rtop's Linux collectors; use WSL Ubuntu.
