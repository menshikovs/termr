# H2 prioritized bug-hunting plan

Run run-open-regressions.R first. Its named cases provide concrete current
failures; F03 and F04 additionally require an explicit contract decision.

| Priority / finding | Fixture and failure trigger | Required invariant / successful fix |
|---|---|---|
| 1 F01 | Local table with edits/filters/selection; replacement callbacks return NA count, throw on seed, change schema, then refresh/switch | Failed replacement preserves previous source, data, schema, selection, cache and edit ledger; successful replacement resets all together |
| 1 F02 | Sorted/filtered table; edit sort/filter key across threshold; hide sort key, reorder columns, select rows | Exact pipeline evaluation under the declared data binding equals current selected/displayed state; otherwise result explicitly unsupported/limited |
| 1 F08 | SQLite owned/borrowed wrappers; unmount, same-App move, screen pop, repeated stop, shared explorer/SQL child | Owned connection closes once at agreed disposal point; borrowed remains valid; same-App move does not release ownership |
| 2 F09 | Public count consumers with NULL,0,1.5,NA,Inf,2^31; record logging startup | Invalid capacities fail at the boundary without warnings/partial state; accepted values have explicit documented rounding/range policy |
| 2 F03 | Existing 64-backlog fixture + 16 arrivals each tick; max_points=100; independent keyboard/timer activity | Choose bounded display cadence; visible progress while queue nonempty; memory count bounded and gap semantics preserved |
| 2 F04 | Detach child/parent during propagation, reparent across Apps, queued key and lifecycle events | Define ordinary vs lifecycle continuation policy, then test no delivery to disallowed inactive targets |
| 2 U01 | Real mirai/nano installed: scheduled completion before cancel, cancel queued task, timeout, process exit during poll, duplicate/stale snapshot | Completion/cancellation terminal states agree; bounded progress; no owned native resources remain after close/error |
| 3 L03 | Valid inkr syntax with unsupported termr color/custom property; matched/unmatched future widgets | Document compile-only transaction or prevalidate mappings safely; rendering must not silently corrupt fallback style |

Automate source/property cases with fixed seeds and public methods. Save the
smallest failing seed, data and exact event order. Do not base race assertions
on arbitrary sleeps: use task readiness, controlled timers and explicit
callback barriers. Compare incremental and forced full frames after failure
recovery. Reuse test-h1-contracts.R for already-fixed lifecycle/cache behavior.

Acceptance requires passing the relevant open regression, failure-then-success
cases, owner cleanup checks, focused old regressions and appropriate platform
checks. Do not “fix” F02 by merely relabeling an inaccurate export as exact or
F08 by closing every supplied connection.
