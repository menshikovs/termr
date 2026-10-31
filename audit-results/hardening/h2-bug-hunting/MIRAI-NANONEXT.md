# Background Tasks: Mirai & Nanonext Integration

## 1. Optional Dependency Policy
Per `docs/stability.md` and project rules, `mirai` and `nanonext` are optional suggested packages.
- When `mirai` is absent, standard background workers use base R background process mechanisms.
- All 28 mirai and nanonext unit tests skip cleanly with informative messages when the packages are not installed.
- No mandatory dependency is added to `DESCRIPTION`.

## 2. Error & Shutdown Isolation
When background tasks encounter timeouts, unmounting, or app shutdown, workers are cleanly polled and terminated without leaking open communication pipes.\n