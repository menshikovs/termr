# Resource Lifecycle & Ownership

Phase H2 established strict ownership semantics for long-lived system resources:

## 1. Owned vs Borrowed DBI Connections
- **Owned Connection (`owned = TRUE`)**: Created and owned by the widget (`sql_editor`, `db_explorer`). Automatically closed upon widget removal (`dispose = TRUE`) or application shutdown.
- **Borrowed Connection (`owned = FALSE`)**: Supplied by caller. Survives widget unmounting and app shutdown. Never closed by termr.

## 2. Timers and Background Workers
- Widget timers (`set_timeout`, `set_interval`) are tracked in `private$.timers`.
- When a widget is unmounted with `dispose = TRUE`, `widget_private(w)$cancel_timers()` cancels all pending timers immediately.
- Background workers owned by unmounted widgets are cancelled to prevent orphaned processes.\n