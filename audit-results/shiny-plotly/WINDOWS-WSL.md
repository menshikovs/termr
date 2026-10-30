# Windows / WSL and native crash

| Collector | Shiny | Observed result |
|---|---|---|
| WSL | WSL | Real browser: base/ggplot2/Plotly, 1/5/20 tabs, stale/restart, bounded history and true extends |
| Windows | Windows | Real Windows collector and Shiny app, browser extends and live status; browser-windows-native.json |
| WSL | Windows | Real Windows Shiny app receives WSL loopback publisher, browser extends; browser-windows-shiny-wsl-collector.json |
| Windows | WSL | Unavailable through localhost: ten-second bounded testServer probe accepted 0 events, state connecting/unavailable; network-receiver-wsl.json |

For the unavailable direction, Windows listened on 127.0.0.1:5571/5572, while
WSL had its own virtual interface (172.22.144.73 during this run). All Windows
firewall profiles were enabled. No packet trace/rule-level diagnosis was made,
so attributing the failure specifically to firewall would be unsupported. The
established observation is that this topology does not forward Windows loopback
into WSL localhost. No system networking, firewall or bind address was changed.
The package deliberately accepts loopback endpoints only. Use one OS for both
ends, or the validated WSL publisher→Windows subscriber direction when available.

Reproduce: run Windows collector with TERMR_METRICS_TRANSPORT=nano and endpoints
tcp://127.0.0.1:5571 / :5572. In WSL run network_receiver.R (bounded ten seconds)
or dashboard.R with those variables. Expect unavailable here. Reverse the hosts
with :5565/:5566 to reproduce the working direction. Normal commands are in the
example README. No public-interface workaround is proposed.

## Native exit diagnosis

The old Phase 3 audit associated Windows exit -1073741819 (0xC0000005) with
pkgload. The controlled current audit narrows it to the **launch environment**:

- minimal cli/rlang/Shiny/pkgload scripts can fail even without nanonext;
- direct Rscript invocation succeeds;
- processx with partial env=c(R_LIBS=...,R_TESTS="") fails;
- inherited, env=c("current",...) and full cloned environments exit 0;
- all 12 repeats of installed/pkgload/no-nano/Shiny matrix modes exit 0 with
  the current-environment form. See environment-crash.json and
  crash-matrix-inherited.json; minimal_crash_child.R is the small reproducer.

The individual missing environment variable/native library defect was not
isolated. The sufficient repair in our owned launchers is preserving current
environment and overriding only R_LIBS/R_TESTS. This is not evidence that termr
or nanonext native code caused the crash. Installed-package and pkgload runtimes
both now complete. No third-party code was patched. Scratch fresh rlang alone
did not fix partial-env launches. R/workers.R already used the correct form.

Initial Windows full tests in the restricted sandbox failed to create processx
pipes (system error 5), a separate permission failure. The approved run outside
that restriction passed; it must not be confused with the native access violation.
