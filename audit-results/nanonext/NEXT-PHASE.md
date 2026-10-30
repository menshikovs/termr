# Next phase: Shiny/Plotly adapters

Current transport supplies versioned JSON values, cached latest state, bounded
local history, gap/source diagnostics and explicit main-thread poll/close.
That is sufficient to build an optional session-owned Shiny adapter returning
a reactive latest value and diagnostic status. The existing monitor already
demonstrates reactivePoll and session cleanup; a reusable adapter should own
one poll observer and always release it/socket subscriptions at session end.

Plotly can consume that Shiny reactive value or incremental bounded history.
Keep Plotly optional; batch updates at a view-appropriate rate and surface
source changes/gaps rather than treating a lossy feed as complete history.
Do not block Shiny with recv/call_aio or mutate R from native callback threads.

Before treating this API as stable, broaden version coverage below tested
nanonext 1.10.3, investigate the Windows pkgload-child/native shutdown issue,
test more terminal hosts and sustained large payloads, and decide whether
polling convenience should become a separate explicit App/Shiny owner helper.
The current API's poll and close contract can remain while adapters schedule it.

Remote endpoints, authentication/TLS, discovery, replay/durable event delivery,
generalized brokers and mirai workers require separate design/authorization.
Do not infer these guarantees from local pub/sub or loopback. Network adapters
must preserve bounded queues, schema validation and source/sequence semantics.
Windows->WSL localhost did not connect here; future network configuration work
must not silently change the local-only binding boundary.
