# Application

An `App` owns the widget tree (through its
[Screen](https://menshikovs.github.io/termr/reference/Screen.md)), the
event queue, timers, key bindings, focus and the terminal driver. Create
one with [`app()`](https://menshikovs.github.io/termr/reference/app.md)
and start it with
[`run()`](https://menshikovs.github.io/termr/reference/run.md).

## Event loop

Each tick of the loop waits for input (or the next timer), turns input
into events, fires due timers, dispatches every queued event and then,
if any widget was invalidated, repaints the screen once: the new frame
is diffed against the previous one and only changed cells are written.

## Event dispatch

An event goes to its target widget (key events: the focused widget) and
bubbles up through the ancestors to the app. At each widget the
`on_<type>` method runs, then handlers added with `widget$on()`, then -
for key events - the widget's key bindings. At the app, handlers added
with `app$on()` /
[`on()`](https://menshikovs.github.io/termr/reference/on.md) run, then
app bindings. `event$stop()` stops propagation.

## Public fields

- `title`:

  Optional application title.

- `reduce_motion`:

  `NULL` (follow the option / environment variable), `TRUE` or `FALSE`:
  reduce decorative animation? See
  [`motion_reduced()`](https://menshikovs.github.io/termr/reference/motion_reduced.md).

- `clipboard`:

  Text copied by widgets (Ctrl+C / Ctrl+X in inputs). This is the app's
  own clipboard, not the operating system's.

## Active bindings

- `screen`:

  The current
  [Screen](https://menshikovs.github.io/termr/reference/Screen.md).

- `screens`:

  The screen stack, bottom first.

- `focused`:

  The focused widget, or `NULL`.

- `theme`:

  The
  [`termr_theme()`](https://menshikovs.github.io/termr/reference/termr_theme.md)
  (assign a theme or a theme name).

- `stylesheets`:

  The stylesheets of the app.

- `hovered`:

  The widget under the mouse pointer, or `NULL`.

- `size`:

  Terminal size: `c(width =, height =)`.

- `running`:

  Is the app running?

- `last_paint`:

  Instrumentation of the last repaint: screen cells, repainted cells,
  dirty rectangles, whether it was a full repaint and the ANSI bytes
  written. For benchmarks and debugging.

- `profile_last_frame`:

  Optional timings and structural counters; enable with
  `options(termr.profile = TRUE)`. Times are milliseconds.

- `frame_stats`:

  Number of full and incremental repaints and of layout passes so far.

- `frame`:

  The last rendered
  [ScreenBuffer](https://menshikovs.github.io/termr/reference/ScreenBuffer.md).

## Methods

### Public methods

- [`App$new()`](#method-App-initialize)

- [`App$run()`](#method-App-run)

- [`App$exit()`](#method-App-exit)

- [`App$query()`](#method-App-query)

- [`App$query_one()`](#method-App-query_one)

- [`App$mount()`](#method-App-mount)

- [`App$on()`](#method-App-on)

- [`App$bind()`](#method-App-bind)

- [`App$log_events()`](#method-App-log_events)

- [`App$event_log()`](#method-App-event_log)

- [`App$toggle_debug()`](#method-App-toggle_debug)

- [`App$add_command()`](#method-App-add_command)

- [`App$show_help()`](#method-App-show_help)

- [`App$bindings()`](#method-App-bindings)

- [`App$post()`](#method-App-post)

- [`App$post_message()`](#method-App-post_message)

- [`App$clipboard_write()`](#method-App-clipboard_write)

- [`App$capture_mouse()`](#method-App-capture_mouse)

- [`App$release_mouse()`](#method-App-release_mouse)

- [`App$run_action()`](#method-App-run_action)

- [`App$request_repaint()`](#method-App-request_repaint)

- [`App$refresh()`](#method-App-refresh)

- [`App$set_focus()`](#method-App-set_focus)

- [`App$add_stylesheet()`](#method-App-add_stylesheet)

- [`App$clear_stylesheets()`](#method-App-clear_stylesheets)

- [`App$stylesheet_style()`](#method-App-stylesheet_style)

- [`App$push_screen()`](#method-App-push_screen)

- [`App$pop_screen()`](#method-App-pop_screen)

- [`App$switch_screen()`](#method-App-switch_screen)

- [`App$run_worker()`](#method-App-run_worker)

- [`App$run_process()`](#method-App-run_process)

- [`App$workers()`](#method-App-workers)

- [`App$notify()`](#method-App-notify)

- [`App$notifications()`](#method-App-notifications)

- [`App$scroll_into_view()`](#method-App-scroll_into_view)

- [`App$focus_next()`](#method-App-focus_next)

- [`App$focus_previous()`](#method-App-focus_previous)

- [`App$focus_chain()`](#method-App-focus_chain)

- [`App$set_timeout()`](#method-App-set_timeout)

- [`App$set_interval()`](#method-App-set_interval)

- [`App$call_later()`](#method-App-call_later)

- [`App$print()`](#method-App-print)

- [`App$clone()`](#method-App-clone)

------------------------------------------------------------------------

### `App$new()`

Create an app. See
[`app()`](https://menshikovs.github.io/termr/reference/app.md).

#### Usage

    App$new(
      ...,
      bindings = list(),
      actions = list(),
      title = NULL,
      mouse = TRUE,
      stylesheet = NULL,
      theme = "default",
      debug = FALSE,
      reduce_motion = NULL
    )

#### Arguments

- `...`:

  Widgets, [`on()`](https://menshikovs.github.io/termr/reference/on.md)
  handlers and
  [`bind()`](https://menshikovs.github.io/termr/reference/bind.md)
  bindings.

- `bindings`:

  A list of
  [`bind()`](https://menshikovs.github.io/termr/reference/bind.md)
  bindings.

- `actions`:

  A named list of functions `function(app)`.

- `title`:

  Optional title.

- `mouse`:

  Enable mouse input?

- `stylesheet`:

  A
  [`stylesheet()`](https://menshikovs.github.io/termr/reference/stylesheet.md),
  stylesheet text or a file path (or a list of them).

- `theme`:

  A
  [`termr_theme()`](https://menshikovs.github.io/termr/reference/termr_theme.md)
  or the name of a built-in theme.

- `debug`:

  Bind F12 to the debug overlay?

- `reduce_motion`:

  `TRUE` to turn decorative animation off, `NULL` to follow
  `options(termr.reduce_motion)` / the `TERMR_REDUCE_MOTION` environment
  variable.

------------------------------------------------------------------------

### `App$run()`

Run the app until it exits. Restores the terminal on exit, on error and
on interrupt.

#### Usage

    App$run(driver = NULL)

#### Arguments

- `driver`:

  A terminal driver; detected automatically by default.

#### Returns

The value passed to `exit()`, invisibly.

------------------------------------------------------------------------

### `App$exit()`

Ask the app to stop after the current event.

#### Usage

    App$exit(value = NULL)

#### Arguments

- `value`:

  Value returned by
  [`run()`](https://menshikovs.github.io/termr/reference/run.md).

------------------------------------------------------------------------

### `App$query()`

Find widgets matching a selector.

#### Usage

    App$query(selector)

#### Arguments

- `selector`:

  A selector such as `"Button"`, `"#id"`, `".class"`.

------------------------------------------------------------------------

### `App$query_one()`

The first widget matching a selector (error if none).

#### Usage

    App$query_one(selector)

#### Arguments

- `selector`:

  A selector.

------------------------------------------------------------------------

### `App$mount()`

Mount widgets on the screen.

#### Usage

    App$mount(...)

#### Arguments

- `...`:

  Widgets.

------------------------------------------------------------------------

### `App$on()`

Add an event handler, see
[`on()`](https://menshikovs.github.io/termr/reference/on.md).

#### Usage

    App$on(type, selector = NULL, handler)

#### Arguments

- `type`:

  Event type.

- `selector`:

  Optional selector matched against the sender.

- `handler`:

  `function(event, app)`.

------------------------------------------------------------------------

### `App$bind()`

Add an app-level key binding, see
[`bind()`](https://menshikovs.github.io/termr/reference/bind.md).

#### Usage

    App$bind(key, action = NULL, description = NULL)

#### Arguments

- `key`:

  Key name or a binding created by
  [`bind()`](https://menshikovs.github.io/termr/reference/bind.md).

- `action`:

  Action name or function.

- `description`:

  Optional description.

------------------------------------------------------------------------

### `App$log_events()`

Record dispatched events (for debugging). Off by default, so normal apps
pay nothing.

#### Usage

    App$log_events(enable = TRUE, size = 200L)

#### Arguments

- `enable`:

  Start (`TRUE`) or stop (`FALSE`) recording.

- `size`:

  Number of events kept.

------------------------------------------------------------------------

### `App$event_log()`

The recorded events as a data frame (see `log_events()`).

#### Usage

    App$event_log()

------------------------------------------------------------------------

### `App$toggle_debug()`

Show or hide the debug overlay (also F12 with `app(debug = TRUE)`).

#### Usage

    App$toggle_debug()

------------------------------------------------------------------------

### `App$add_command()`

Add a command to the command palette (Ctrl+P) and the help screen (F1).
See
[`command()`](https://menshikovs.github.io/termr/reference/command.md).

#### Usage

    App$add_command(
      label,
      action = NULL,
      category = NULL,
      shortcut = NULL,
      enabled = NULL,
      description = NULL
    )

#### Arguments

- `label`:

  Text shown in the palette, or a
  [`command()`](https://menshikovs.github.io/termr/reference/command.md)
  object.

- `action`:

  An action name or `function(app)`.

- `category, shortcut, enabled, description`:

  See
  [`command()`](https://menshikovs.github.io/termr/reference/command.md).

------------------------------------------------------------------------

### `App$show_help()`

Show the help screen (F1): key bindings of the focused widget, its
ancestors and the app, and the app's commands.

#### Usage

    App$show_help()

------------------------------------------------------------------------

### `App$bindings()`

All app-level bindings.

#### Usage

    App$bindings()

------------------------------------------------------------------------

### `App$post()`

Queue an event for dispatch.

#### Usage

    App$post(event)

#### Arguments

- `event`:

  An [Event](https://menshikovs.github.io/termr/reference/Event.md).

------------------------------------------------------------------------

### `App$post_message()`

Send a custom message from the app (bubbles from the screen).

#### Usage

    App$post_message(type, data = list())

#### Arguments

- `type`:

  Message name.

- `data`:

  List of values.

------------------------------------------------------------------------

### `App$clipboard_write()`

Copy text to the clipboard. The app clipboard (`app$clipboard`) is
always set; when `system = TRUE` and the terminal supports OSC 52 the
text is also sent to the system clipboard (write-only: termr never reads
the system clipboard). Long text is truncated to 100 kB for the
terminal.

#### Usage

    App$clipboard_write(text, system = TRUE)

#### Arguments

- `text`:

  A string.

- `system`:

  Also write to the system clipboard?

#### Returns

`TRUE` (invisibly) if the text was sent to the terminal.

------------------------------------------------------------------------

### `App$capture_mouse()`

Send all mouse events to `widget` (even outside its region) until
`release_mouse()` or the next button release. Used for drags that start
elsewhere, e.g. splitters.

#### Usage

    App$capture_mouse(widget)

#### Arguments

- `widget`:

  A mounted widget.

------------------------------------------------------------------------

### `App$release_mouse()`

Stop capturing the mouse.

#### Usage

    App$release_mouse()

------------------------------------------------------------------------

### `App$run_action()`

Run an action by name (or a function).

#### Usage

    App$run_action(action, widget = NULL)

#### Arguments

- `action`:

  Action name such as `"quit"`, or a function.

- `widget`:

  Widget where the lookup starts (`NULL`: the app).

------------------------------------------------------------------------

### `App$request_repaint()`

Schedule a repaint at the end of the current tick.

#### Usage

    App$request_repaint(widget = NULL, full = is.null(widget), layout = TRUE)

#### Arguments

- `widget`:

  The widget that changed, if known. Without it the next repaint redraws
  everything; with it only the rows of changed widgets are repainted
  when the layout did not change.

- `full`:

  Force a full repaint?

- `layout`:

  Does the change possibly affect sizes or positions? When `FALSE` and
  nothing else changed the layout pass is skipped.

------------------------------------------------------------------------

### `App$refresh()`

Redraw the whole screen (e.g. after external output).

#### Usage

    App$refresh()

------------------------------------------------------------------------

### `App$set_focus()`

Give focus to a widget (or remove focus with `NULL`).

#### Usage

    App$set_focus(widget)

#### Arguments

- `widget`:

  A focusable widget in this app, or `NULL`.

#### Returns

`TRUE` if focus changed.

------------------------------------------------------------------------

### `App$add_stylesheet()`

Add a stylesheet; its rules apply to all screens.

#### Usage

    App$add_stylesheet(sheet)

#### Arguments

- `sheet`:

  A
  [`stylesheet()`](https://menshikovs.github.io/termr/reference/stylesheet.md),
  stylesheet text or a file path.

------------------------------------------------------------------------

### `App$clear_stylesheets()`

Remove all stylesheets.

#### Usage

    App$clear_stylesheets()

------------------------------------------------------------------------

### `App$stylesheet_style()`

The merged stylesheet rules that apply to a widget.

#### Usage

    App$stylesheet_style(widget, states = widget$pseudo_states())

#### Arguments

- `widget`:

  A widget.

- `states`:

  Its pseudo states.

------------------------------------------------------------------------

### `App$push_screen()`

Show a screen on top of the current one. A widget is wrapped in a new
[Screen](https://menshikovs.github.io/termr/reference/Screen.md). Use
[`modal()`](https://menshikovs.github.io/termr/reference/modal.md) for
dialogs.

#### Usage

    App$push_screen(screen, callback = NULL)

#### Arguments

- `screen`:

  A [Screen](https://menshikovs.github.io/termr/reference/Screen.md) (or
  [ModalScreen](https://menshikovs.github.io/termr/reference/ModalScreen.md))
  or a widget.

- `callback`:

  Optional `function(result, app)` called when the screen is dismissed /
  popped with a result.

#### Returns

The screen, invisibly.

------------------------------------------------------------------------

### `App$pop_screen()`

Remove the top screen (or a given screen) and return to the one below,
restoring its focus.

#### Usage

    App$pop_screen(result = NULL, screen = self$screen)

#### Arguments

- `result`:

  Passed to the screen's callbacks.

- `screen`:

  The screen to remove (default: the top screen).

------------------------------------------------------------------------

### `App$switch_screen()`

Replace the top screen.

#### Usage

    App$switch_screen(screen)

#### Arguments

- `screen`:

  A [Screen](https://menshikovs.github.io/termr/reference/Screen.md) or
  a widget.

------------------------------------------------------------------------

### `App$run_worker()`

Run a function in a background R process. See
[`run_worker()`](https://menshikovs.github.io/termr/reference/run_worker.md)
for the arguments.

#### Usage

    App$run_worker(
      fn,
      args = list(),
      on_complete = NULL,
      on_error = NULL,
      on_progress = NULL,
      name = NULL,
      owner = NULL,
      packages = character(),
      inline = FALSE,
      on_stdout = NULL,
      on_stderr = NULL,
      timeout = NULL
    )

#### Arguments

- `fn, args, on_complete, on_error, on_progress, name, owner, packages, inline`:

  See
  [`run_worker()`](https://menshikovs.github.io/termr/reference/run_worker.md).

- `on_stdout, on_stderr, timeout`:

  See
  [`run_worker()`](https://menshikovs.github.io/termr/reference/run_worker.md).

------------------------------------------------------------------------

### `App$run_process()`

Run an external program in the background, without a shell. See
[`run_process()`](https://menshikovs.github.io/termr/reference/run_worker.md).

#### Usage

    App$run_process(
      command,
      args = character(),
      on_complete = NULL,
      on_error = NULL,
      on_stdout = NULL,
      on_stderr = NULL,
      on_exit = NULL,
      timeout = NULL,
      wd = NULL,
      env = NULL,
      name = NULL,
      owner = NULL
    )

#### Arguments

- `command, args, on_complete, on_error, on_stdout, on_stderr, on_exit, timeout, wd, env, name, owner`:

  See
  [`run_process()`](https://menshikovs.github.io/termr/reference/run_worker.md).

------------------------------------------------------------------------

### `App$workers()`

Running workers.

#### Usage

    App$workers()

------------------------------------------------------------------------

### `App$notify()`

Show a notification (toast) in the bottom-right corner.

#### Usage

    App$notify(message, title = NULL, severity = "information", timeout = 3)

#### Arguments

- `message`:

  Text.

- `title`:

  Optional title.

- `severity`:

  `"information"`, `"success"`, `"warning"` or `"error"`.

- `timeout`:

  Seconds before it disappears (`Inf`: until clicked).

#### Returns

The `Toast` widget, invisibly.

------------------------------------------------------------------------

### `App$notifications()`

Active notifications (toasts).

#### Usage

    App$notifications()

------------------------------------------------------------------------

### `App$scroll_into_view()`

Scroll every scroll view containing `widget` so that it becomes visible
(done at the next repaint).

#### Usage

    App$scroll_into_view(widget)

#### Arguments

- `widget`:

  A widget of this app.

------------------------------------------------------------------------

### `App$focus_next()`

Move focus to the next focusable widget.

#### Usage

    App$focus_next()

------------------------------------------------------------------------

### `App$focus_previous()`

Move focus to the previous focusable widget.

#### Usage

    App$focus_previous()

------------------------------------------------------------------------

### `App$focus_chain()`

Focusable widgets in focus order.

#### Usage

    App$focus_chain()

------------------------------------------------------------------------

### `App$set_timeout()`

Call `callback(app)` once after `delay` seconds.

#### Usage

    App$set_timeout(delay, callback)

#### Arguments

- `delay`:

  Seconds.

- `callback`:

  Function.

------------------------------------------------------------------------

### `App$set_interval()`

Call `callback(app)` every `interval` seconds.

#### Usage

    App$set_interval(interval, callback)

#### Arguments

- `interval`:

  Seconds.

- `callback`:

  Function.

------------------------------------------------------------------------

### `App$call_later()`

Call `callback(app)` at the start of the next tick.

#### Usage

    App$call_later(callback)

#### Arguments

- `callback`:

  Function.

------------------------------------------------------------------------

### `App$print()`

Print a summary of the app.

#### Usage

    App$print(...)

#### Arguments

- `...`:

  Ignored.

------------------------------------------------------------------------

### `App$clone()`

The objects of this class are cloneable with this method.

#### Usage

    App$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
