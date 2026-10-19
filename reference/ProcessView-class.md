# ProcessView widget

Runs a program and shows its output. See
[`process_view()`](https://menshikovs.github.io/termr/reference/process_view.md).

## Super classes

[`Widget`](https://menshikovs.github.io/termr/reference/Widget-class.md)
-\>
[`Vertical`](https://menshikovs.github.io/termr/reference/Vertical-class.md)
-\> `ProcessView`

## Public fields

- `command, args, wd, env, timeout`:

  The process to run.

- `autostart`:

  Start when the widget is mounted?

- `worker`:

  The [Worker](https://menshikovs.github.io/termr/reference/Worker.md)
  of the current run, or `NULL`.

## Active bindings

- `running`:

  Is the process running?

- `output`:

  The output lines so far.

## Methods

### Public methods

- [`ProcessView$new()`](#method-ProcessView-initialize)

- [`ProcessView$default_bindings()`](#method-ProcessView-default_bindings)

- [`ProcessView$on_mount()`](#method-ProcessView-on_mount)

- [`ProcessView$start()`](#method-ProcessView-start)

- [`ProcessView$cancel()`](#method-ProcessView-cancel)

- [`ProcessView$restart()`](#method-ProcessView-restart)

- [`ProcessView$action_cancel_process()`](#method-ProcessView-action_cancel_process)

- [`ProcessView$action_restart_process()`](#method-ProcessView-action_restart_process)

- [`ProcessView$clone()`](#method-ProcessView-clone)

Inherited methods

- [`Widget$add_class()`](https://menshikovs.github.io/termr/reference/Widget.html#method-add_class)
- [`Widget$ancestors()`](https://menshikovs.github.io/termr/reference/Widget.html#method-ancestors)
- [`Widget$animate()`](https://menshikovs.github.io/termr/reference/Widget.html#method-animate)
- [`Widget$arrange_children()`](https://menshikovs.github.io/termr/reference/Widget.html#method-arrange_children)
- [`Widget$bind()`](https://menshikovs.github.io/termr/reference/Widget.html#method-bind)
- [`Widget$bind_reactive()`](https://menshikovs.github.io/termr/reference/Widget.html#method-bind_reactive)
- [`Widget$bindings()`](https://menshikovs.github.io/termr/reference/Widget.html#method-bindings)
- [`Widget$blur()`](https://menshikovs.github.io/termr/reference/Widget.html#method-blur)
- [`Widget$capture_mouse()`](https://menshikovs.github.io/termr/reference/Widget.html#method-capture_mouse)
- [`Widget$child_clip()`](https://menshikovs.github.io/termr/reference/Widget.html#method-child_clip)
- [`Widget$clear()`](https://menshikovs.github.io/termr/reference/Widget.html#method-clear)
- [`Widget$computed_style()`](https://menshikovs.github.io/termr/reference/Widget.html#method-computed_style)
- [`Widget$content_height()`](https://menshikovs.github.io/termr/reference/Widget.html#method-content_height)
- [`Widget$content_width()`](https://menshikovs.github.io/termr/reference/Widget.html#method-content_width)
- [`Widget$focus()`](https://menshikovs.github.io/termr/reference/Widget.html#method-focus)
- [`Widget$format()`](https://menshikovs.github.io/termr/reference/Widget.html#method-format)
- [`Widget$get_state()`](https://menshikovs.github.io/termr/reference/Widget.html#method-get_state)
- [`Widget$has_class()`](https://menshikovs.github.io/termr/reference/Widget.html#method-has_class)
- [`Widget$invalidate()`](https://menshikovs.github.io/termr/reference/Widget.html#method-invalidate)
- [`Widget$invalidate_paint()`](https://menshikovs.github.io/termr/reference/Widget.html#method-invalidate_paint)
- [`Widget$is_displayed()`](https://menshikovs.github.io/termr/reference/Widget.html#method-is_displayed)
- [`Widget$is_enabled()`](https://menshikovs.github.io/termr/reference/Widget.html#method-is_enabled)
- [`Widget$layout_descend()`](https://menshikovs.github.io/termr/reference/Widget.html#method-layout_descend)
- [`Widget$layout_differs()`](https://menshikovs.github.io/termr/reference/Widget.html#method-layout_differs)
- [`Widget$matches()`](https://menshikovs.github.io/termr/reference/Widget.html#method-matches)
- [`Widget$mount()`](https://menshikovs.github.io/termr/reference/Widget.html#method-mount)
- [`Widget$on()`](https://menshikovs.github.io/termr/reference/Widget.html#method-on)
- [`Widget$paint()`](https://menshikovs.github.io/termr/reference/Widget.html#method-paint)
- [`Widget$post_message()`](https://menshikovs.github.io/termr/reference/Widget.html#method-post_message)
- [`Widget$print()`](https://menshikovs.github.io/termr/reference/Widget.html#method-print)
- [`Widget$pseudo_states()`](https://menshikovs.github.io/termr/reference/Widget.html#method-pseudo_states)
- [`Widget$query()`](https://menshikovs.github.io/termr/reference/Widget.html#method-query)
- [`Widget$query_one()`](https://menshikovs.github.io/termr/reference/Widget.html#method-query_one)
- [`Widget$refresh()`](https://menshikovs.github.io/termr/reference/Widget.html#method-refresh)
- [`Widget$release_mouse()`](https://menshikovs.github.io/termr/reference/Widget.html#method-release_mouse)
- [`Widget$remove()`](https://menshikovs.github.io/termr/reference/Widget.html#method-remove)
- [`Widget$remove_children()`](https://menshikovs.github.io/termr/reference/Widget.html#method-remove_children)
- [`Widget$remove_class()`](https://menshikovs.github.io/termr/reference/Widget.html#method-remove_class)
- [`Widget$render()`](https://menshikovs.github.io/termr/reference/Widget.html#method-render)
- [`Widget$render_lines()`](https://menshikovs.github.io/termr/reference/Widget.html#method-render_lines)
- [`Widget$replace()`](https://menshikovs.github.io/termr/reference/Widget.html#method-replace)
- [`Widget$run_action()`](https://menshikovs.github.io/termr/reference/Widget.html#method-run_action)
- [`Widget$run_process()`](https://menshikovs.github.io/termr/reference/Widget.html#method-run_process)
- [`Widget$run_worker()`](https://menshikovs.github.io/termr/reference/Widget.html#method-run_worker)
- [`Widget$set()`](https://menshikovs.github.io/termr/reference/Widget.html#method-set)
- [`Widget$set_interval()`](https://menshikovs.github.io/termr/reference/Widget.html#method-set_interval)
- [`Widget$set_state()`](https://menshikovs.github.io/termr/reference/Widget.html#method-set_state)
- [`Widget$set_timeout()`](https://menshikovs.github.io/termr/reference/Widget.html#method-set_timeout)
- [`Widget$toggle_class()`](https://menshikovs.github.io/termr/reference/Widget.html#method-toggle_class)
- [`Widget$walk()`](https://menshikovs.github.io/termr/reference/Widget.html#method-walk)
- [`Vertical$default_style()`](https://menshikovs.github.io/termr/reference/Vertical.html#method-default_style)

------------------------------------------------------------------------

### `ProcessView$new()`

Create a process view. See
[`process_view()`](https://menshikovs.github.io/termr/reference/process_view.md).

#### Usage

    ProcessView$new(
      command,
      args = character(),
      wd = NULL,
      env = NULL,
      timeout = NULL,
      autostart = TRUE,
      max_lines = 2000L,
      id = NULL,
      classes = NULL,
      style = NULL
    )

#### Arguments

- `command, args, wd, env, timeout`:

  The process to run.

- `autostart`:

  Start when mounted?

- `max_lines`:

  Output lines kept.

- `id, classes, style`:

  See
  [Widget](https://menshikovs.github.io/termr/reference/Widget-class.md).

------------------------------------------------------------------------

### `ProcessView$default_bindings()`

Ctrl+X cancels the process, Ctrl+R restarts it.

#### Usage

    ProcessView$default_bindings()

------------------------------------------------------------------------

### `ProcessView$on_mount()`

Start the process when the widget is mounted.

#### Usage

    ProcessView$on_mount(event)

#### Arguments

- `event`:

  A `MountEvent`.

------------------------------------------------------------------------

### `ProcessView$start()`

Run the process (output starts afresh).

#### Usage

    ProcessView$start()

------------------------------------------------------------------------

### `ProcessView$cancel()`

Stop the process.

#### Usage

    ProcessView$cancel()

------------------------------------------------------------------------

### `ProcessView$restart()`

Cancel the process and run it again.

#### Usage

    ProcessView$restart()

------------------------------------------------------------------------

### `ProcessView$action_cancel_process()`

Cancel action.

#### Usage

    ProcessView$action_cancel_process()

------------------------------------------------------------------------

### `ProcessView$action_restart_process()`

Restart action.

#### Usage

    ProcessView$action_restart_process()

------------------------------------------------------------------------

### `ProcessView$clone()`

The objects of this class are cloneable with this method.

#### Usage

    ProcessView$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
