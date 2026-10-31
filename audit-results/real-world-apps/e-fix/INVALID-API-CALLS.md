# E-FIX — Invalid Api Calls

No nonexistent exported function had to be invented or substituted. The material
API misuse was the **return contract**: DataTable$selected_row() returns a row
index/source key, not row data. The original details dialog displayed that index;
an interim repair that treated it as a list failed with `$ operator is invalid
for atomic vectors`. Current code uses row_data(index), then the actual task's
public info()/result() methods. Before/after regression logs retain the failure.

Static installed-API audit:

| Platform | Namespace calls | Invalid namespace calls | Resolved method calls | Invalid methods |
| --- | --- | --- | --- | --- |
| Windows | 189 | 0 | 80 | 0 |
| WSL | 189 | 0 | 80 | 0 |


`namespace-calls.csv` records file, expression and actual installed formals for
termr/shiny/ggplot2/plotly/mirai/nanonext/inkr calls. `method-calls.csv` checks
statically resolvable app/view/table/chart/stream/pool receivers. The summary
records real constructor classes and public method signatures; selected_row is
integer while row_data is a list. Dynamic owner callbacks are not falsely claimed
to be completely statically resolved: actual constructor, headless, PTY, browser
and worker tests cover their runtime contracts.

The documented on(type, function(event, app) ...) overload is valid even though
handler is a formally missing argument. The initial generic required-argument
checker falsely flagged two such calls; the audit now recognizes that documented
overload. Events cell_changed, row_activated, tabs.changed and chart selection
were checked against current documentation and actual emitted events. No
termr::: or private R6 access was added. App APIs are experimental where noted
in docs/stability.md; these applications are not new stable exports.

Evidence: `proof-windows/api-summary.json`, namespace/method CSVs there,
and `proof-wsl/`. These are new E-FIX runs against current-* installed builds.
