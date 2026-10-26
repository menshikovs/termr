# Screens, workers and developer tools

## Screens and dialogs

```r
app$push_screen(vertical(label("Settings"), ...))   # a new screen
app$pop_screen()
app$switch_screen(other)

app$push_screen(confirm_dialog("Delete file?", on_confirm = function(app) delete()))
app$push_screen(alert_dialog("Saved"))
dlg <- modal(input(id = "new_name"), button("OK", id = "ok"), title = "Rename")
dlg$on("button.pressed", function(event, app) dlg$dismiss(app$query_one("#new_name")$value))
app$push_screen(dlg, callback = function(result, app) rename(result))
```

The top screen gets the keys, the mouse and the focus. Modal screens are
drawn over the dimmed screen below; Escape closes them and the previous
focus comes back.

## Notifications

```r
app$notify("Saved", title = "File", severity = "success", timeout = 3)
```

Severities: `information`, `success`, `warning`, `error`. Clicking a
notification closes it.

## Background workers

```r
app$run_worker(
  function(path) {
    data <- read.csv(path)
    termr_progress(0.5, "fitting")
    lm(y ~ x, data)
  },
  args = list(path = "data.csv"),
  on_progress = function(value, message, app) bar$set(value = value),
  on_complete = function(fit, app) app$notify("Model ready"),
  on_error = function(message, app) app$notify(message, severity = "error")
)
```

The function runs in a fresh R process (`Rscript --vanilla`): pass data
in `args`, list packages in `packages`. Workers send `worker.*` events,
can be cancelled (`worker$cancel()`), and stop with their owner widget
(`widget$run_worker()`) and with the app. Use `inline = TRUE` in tests.

### External processes

`process_view()` runs a command without a shell and displays bounded stdout and
stderr in a `LogView`. The existing default remains synchronous on Ctrl+X and
when calling `$cancel()`. Set `stop_grace` to opt into non-blocking cancellation:
termr sends processx's platform interrupt, keeps polling output, and forcefully
terminates the process if it remains alive at the deadline.

```r
view <- process_view(
  "Rscript", c("--vanilla", "-e", "cat('started\\n'); Sys.sleep(60)"),
  stop_grace = 3, max_lines = 1000
)
app <- app(view)
# Ctrl+X or view$cancel() requests the graceful stop.
# view$state reports "stopping" until cancellation is finalized.
# view$restart() requests a stop and starts the next run only after this worker ends.
```

`view$exit_status` retains the most recent process exit code; it is
`NA_integer_` when cancellation ends without an exit status. Use
`view$clear_output()` to clear the bounded log without stopping the process.
Each explicit start/restart clears the prior log. `supervision = "parent"` is
an opt-in processx parent-death policy; it is not a guarantee that arbitrary
grandchildren will be terminated. The initial signal cannot currently be
selected separately from processx's platform interrupt.

### Dynamic widgets

Existing `OptionList$set_choices()`, `DataTable$set_data()` / `$set_cell()`,
widget `$visible` / `$disabled`, signals and computed values cover common
live-update needs. Programmatic choice replacement currently resets the
highlight to the first choice, and replacing table data resets its cursor,
scroll, sorting, filtering and selection. The bundled example demonstrates
those existing contracts, conditional form visibility and reactive status:

```r
termr::run_example("dynamic-workflow")
```

## Mouse

Mouse input is on by default (`app(mouse = FALSE)` turns it off): clicks
press buttons, focus widgets and place the input cursor; the wheel scrolls;
`:hover` styles follow the pointer.

## Developer tools

* `inspect_widget(app, "#id")`: type, region, states, state, computed
  style, matching stylesheet rules, bindings, current focus and focus-chain
  position. `app$focus_chain()` returns the focusable widgets in navigation
  order; hidden and disabled widgets are excluded.
* `app$log_events()` / `app$event_log()`: opt-in, bounded dispatch trace with
  timestamp, event type, target and key detail. It records no widget values
  and is disabled by default.
* `app(debug = TRUE)`: F12 shows an overlay with the focused and hovered
  widget, the last event and repaint statistics. It does not take focus.
* `app$frame_stats`: full and incremental repaints.
