# Phase E — Lintr

Default lintr was run against 35 Phase E/critical-core R files (see actual JSON
file count), retaining style findings instead of reformatting prior user code.
Windows lintr 3.4.0: 4203 findings; WSL lintr 3.3.0.1:
4196. Both report zero `error` diagnostics. The runner's PASS means
the scan completed without error diagnostics, **not** a clean default-lint result.

| Scope | Windows findings | WSL findings |
| --- | --- | --- |
| Phase E application/tool | 3182 | 3175 |
| pre-existing core (unchanged) | 1021 | 1021 |


Most new findings are quotes, long lines, commas, compact semicolon/brace/space
style and indentation. They remain explicit style debt. Existing unchanged core
findings are not new regressions. The two object-usage messages are ggplot2 NSE
bindings `cpu` and `segment` in `aes`, verified against the supplied data frame
and actual rendering; no meaningless globalVariables declarations were added.

`runner-env-final/lintr-findings.csv` and
`runner-env-wsl-final/lintr-findings.csv` contain every location/linter/message and
scope. `lint-summary.json` groups counts. Tool-version differences explain
small platform count differences. No parse-error or confirmed static-analysis
functional bug remains. Broad style cleanup is outside this integration phase;
the reports do not silently suppress or relabel those diagnostics as zero.
