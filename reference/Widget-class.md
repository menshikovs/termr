# Widget base class

Every element of a termr interface is a `Widget`. Widgets form a tree:
each widget has one parent and an ordered list of children. Most users
create widgets with constructor functions such as
[`label()`](https://menshikovs.github.io/termr/reference/label.md) or
[`vertical()`](https://menshikovs.github.io/termr/reference/vertical.md),
and define new widget types with
[`widget()`](https://menshikovs.github.io/termr/reference/widget.md).
Subclassing `Widget` with
[`R6::R6Class()`](https://r6.r-lib.org/reference/R6Class.html) is also
supported for advanced use.

A subclass usually overrides some of:

- `default_style()`: the built-in
  [`style()`](https://menshikovs.github.io/termr/reference/style.md) of
  the widget type;

- `render()`: returns the content as a string, a character vector of
  lines or
  [`span()`](https://menshikovs.github.io/termr/reference/span.md)s;

- `on_key(event)`: handle a key press (return `TRUE` when handled);

- `paint(buffer, area, st)`: full control over drawing.

## State

Widget state lives in reactive fields: assigning a new value invalidates
the widget and schedules a repaint. Several assignments in one event
loop tick produce a single repaint.

## Public fields

- `id`:

  Unique identifier used by `#id` selectors, or `NULL`.

- `classes`:

  Character vector of classes used by `.class` selectors.

- `help`:

  Optional help text (Markdown) shown on the help screen (F1) while this
  widget or a descendant has focus.

- `paint_states`:

  Names of state fields whose changes only need a repaint (see
  `invalidate_paint()`); used by `set_state()`.

- `focusable`:

  Can the widget receive keyboard focus?

- `region`:

  Border box assigned by the layout engine
  ([`region()`](https://menshikovs.github.io/termr/reference/region.md)).

## Active bindings

- `parent`:

  The parent widget (read-only).

- `children`:

  List of child widgets (read-only).

- `app`:

  The [App](https://menshikovs.github.io/termr/reference/App-class.md)
  this widget belongs to, or `NULL`.

- `type`:

  Widget type name used by type selectors.

- `visible`:

  Is the widget shown? Hidden widgets take no space.

- `disabled`:

  Disabled widgets cannot be focused or used.

- `style`:

  The widget's own
  [`style()`](https://menshikovs.github.io/termr/reference/style.md)
  (layered over its defaults).

- `border_title`:

  Text shown in the top border (reactive), or `NULL`.

- `hovered`:

  Is the mouse pointer over this widget (or a descendant)?

- `focused`:

  Does the widget currently have keyboard focus?

## Methods

### Public methods

- [`Widget$new()`](#method-Widget-initialize)

- [`Widget$default_style()`](#method-Widget-default_style)

- [`Widget$render()`](#method-Widget-render)

- [`Widget$mount()`](#method-Widget-mount)

- [`Widget$replace()`](#method-Widget-replace)

- [`Widget$clear()`](#method-Widget-clear)

- [`Widget$remove()`](#method-Widget-remove)

- [`Widget$remove_children()`](#method-Widget-remove_children)

- [`Widget$walk()`](#method-Widget-walk)

- [`Widget$ancestors()`](#method-Widget-ancestors)

- [`Widget$query()`](#method-Widget-query)

- [`Widget$query_one()`](#method-Widget-query_one)

- [`Widget$matches()`](#method-Widget-matches)

- [`Widget$on()`](#method-Widget-on)

- [`Widget$bind()`](#method-Widget-bind)

- [`Widget$default_bindings()`](#method-Widget-default_bindings)

- [`Widget$bindings()`](#method-Widget-bindings)

- [`Widget$bind_reactive()`](#method-Widget-bind_reactive)

- [`Widget$capture_mouse()`](#method-Widget-capture_mouse)

- [`Widget$release_mouse()`](#method-Widget-release_mouse)

- [`Widget$run_action()`](#method-Widget-run_action)

- [`Widget$post_message()`](#method-Widget-post_message)

- [`Widget$set_timeout()`](#method-Widget-set_timeout)

- [`Widget$set_interval()`](#method-Widget-set_interval)

- [`Widget$animate()`](#method-Widget-animate)

- [`Widget$run_worker()`](#method-Widget-run_worker)

- [`Widget$run_process()`](#method-Widget-run_process)

- [`Widget$focus()`](#method-Widget-focus)

- [`Widget$blur()`](#method-Widget-blur)

- [`Widget$add_class()`](#method-Widget-add_class)

- [`Widget$remove_class()`](#method-Widget-remove_class)

- [`Widget$toggle_class()`](#method-Widget-toggle_class)

- [`Widget$has_class()`](#method-Widget-has_class)

- [`Widget$set()`](#method-Widget-set)

- [`Widget$get_state()`](#method-Widget-get_state)

- [`Widget$set_state()`](#method-Widget-set_state)

- [`Widget$layout_differs()`](#method-Widget-layout_differs)

- [`Widget$invalidate()`](#method-Widget-invalidate)

- [`Widget$invalidate_paint()`](#method-Widget-invalidate_paint)

- [`Widget$refresh()`](#method-Widget-refresh)

- [`Widget$render_lines()`](#method-Widget-render_lines)

- [`Widget$content_width()`](#method-Widget-content_width)

- [`Widget$content_height()`](#method-Widget-content_height)

- [`Widget$arrange_children()`](#method-Widget-arrange_children)

- [`Widget$child_clip()`](#method-Widget-child_clip)

- [`Widget$pseudo_states()`](#method-Widget-pseudo_states)

- [`Widget$computed_style()`](#method-Widget-computed_style)

- [`Widget$layout_descend()`](#method-Widget-layout_descend)

- [`Widget$paint()`](#method-Widget-paint)

- [`Widget$is_enabled()`](#method-Widget-is_enabled)

- [`Widget$is_displayed()`](#method-Widget-is_displayed)

- [`Widget$format()`](#method-Widget-format)

- [`Widget$print()`](#method-Widget-print)

- [`Widget$clone()`](#method-Widget-clone)

------------------------------------------------------------------------

### `Widget$new()`

Create a widget.

#### Usage

    Widget$new(
      ...,
      id = NULL,
      classes = NULL,
      style = NULL,
      disabled = FALSE,
      visible = TRUE
    )

#### Arguments

- `...`:

  Child widgets.

- `id`:

  Optional identifier.

- `classes`:

  Character vector (or space separated string) of classes.

- `style`:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).

- `disabled`:

  Is the widget disabled?

- `visible`:

  Is the widget visible?

------------------------------------------------------------------------

### `Widget$default_style()`

The built-in style of this widget type.

#### Usage

    Widget$default_style()

------------------------------------------------------------------------

### `Widget$render()`

Content of the widget (string, lines or spans). Containers return
`NULL`.

#### Usage

    Widget$render()

------------------------------------------------------------------------

### `Widget$mount()`

Add child widgets, at the end or at a position. A widget that already
has a parent is moved. Ids must be unique within a screen.

#### Usage

    Widget$mount(..., before = NULL, after = NULL)

#### Arguments

- `...`:

  Widgets or lists of widgets.

- `before, after`:

  A child widget (or its index) to insert before / after.

------------------------------------------------------------------------

### `Widget$replace()`

Remove all children and mount new ones.

#### Usage

    Widget$replace(...)

#### Arguments

- `...`:

  Widgets.

------------------------------------------------------------------------

### `Widget$clear()`

Remove all children (containers). Some widgets redefine `clear()` for
their content (e.g.
[`input()`](https://menshikovs.github.io/termr/reference/input.md),
[`log_view()`](https://menshikovs.github.io/termr/reference/log_view.md)).

#### Usage

    Widget$clear()

------------------------------------------------------------------------

### `Widget$remove()`

Detach this widget (and its children) from its parent.

#### Usage

    Widget$remove()

------------------------------------------------------------------------

### `Widget$remove_children()`

Remove all children.

#### Usage

    Widget$remove_children()

------------------------------------------------------------------------

### `Widget$walk()`

This widget followed by all descendants (depth first).

#### Usage

    Widget$walk()

------------------------------------------------------------------------

### `Widget$ancestors()`

Parent, grandparent, ... up to the root.

#### Usage

    Widget$ancestors()

------------------------------------------------------------------------

### `Widget$query()`

Find descendants matching a CSS-like selector.

#### Usage

    Widget$query(selector)

#### Arguments

- `selector`:

  E.g. `"Button"`, `"#name"`, `".danger"`,
  `"Vertical > Button.primary"`, or several separated by commas.

#### Returns

A list of widgets.

------------------------------------------------------------------------

### `Widget$query_one()`

The first descendant matching `selector`.

#### Usage

    Widget$query_one(selector)

#### Arguments

- `selector`:

  A selector, see `query()`.

------------------------------------------------------------------------

### `Widget$matches()`

Does this widget match `selector`?

#### Usage

    Widget$matches(selector)

#### Arguments

- `selector`:

  A selector, see `query()`.

------------------------------------------------------------------------

### `Widget$on()`

Handle events of a type that reach this widget (its own events and
events bubbling up from descendants).

#### Usage

    Widget$on(type, handler, selector = NULL)

#### Arguments

- `type`:

  Event type, or `"*"` for all.

- `handler`:

  `function(event, app)`.

- `selector`:

  Optional selector matched against the event sender. The order of
  [`on()`](https://menshikovs.github.io/termr/reference/on.md) /
  `app$on()`, `widget$on(type, selector, handler)`, is accepted too.

------------------------------------------------------------------------

### `Widget$bind()`

Add a key binding to this widget, see
[`bind()`](https://menshikovs.github.io/termr/reference/bind.md).

#### Usage

    Widget$bind(key, action = NULL, description = NULL)

#### Arguments

- `key`:

  Key name or a
  [`bind()`](https://menshikovs.github.io/termr/reference/bind.md)
  binding.

- `action`:

  Action name or function.

- `description`:

  Optional description.

------------------------------------------------------------------------

### `Widget$default_bindings()`

Built-in bindings of this widget type.

#### Usage

    Widget$default_bindings()

------------------------------------------------------------------------

### `Widget$bindings()`

All bindings of this widget (type bindings first, so instance bindings
win).

#### Usage

    Widget$bindings()

------------------------------------------------------------------------

### `Widget$bind_reactive()`

Keep a field in sync with a reactive function: `fn` runs now and again
whenever the
[`signal()`](https://menshikovs.github.io/termr/reference/signals.md)s
it reads change, and its result is assigned to `field` (e.g. `"text"`
for a label). The binding ends when the widget is removed.

#### Usage

    Widget$bind_reactive(field, fn)

#### Arguments

- `field`:

  Name of a widget field (an active binding such as `text`).

- `fn`:

  A function of no arguments.

------------------------------------------------------------------------

### `Widget$capture_mouse()`

Receive all mouse events (also outside this widget's region) until
`release_mouse()` or the button is released.

#### Usage

    Widget$capture_mouse()

------------------------------------------------------------------------

### `Widget$release_mouse()`

Stop capturing the mouse.

#### Usage

    Widget$release_mouse()

------------------------------------------------------------------------

### `Widget$run_action()`

Run an action, looked up on this widget, its ancestors, then the app.

#### Usage

    Widget$run_action(action)

#### Arguments

- `action`:

  Action name or function.

------------------------------------------------------------------------

### `Widget$post_message()`

Send a message that bubbles up from this widget to the app. Handlers
receive a
[MessageEvent](https://menshikovs.github.io/termr/reference/Event.md)
whose `sender` is this widget.

#### Usage

    Widget$post_message(type, data = list(), bubbles = TRUE)

#### Arguments

- `type`:

  Message name, e.g. `"counter.changed"`.

- `data`:

  A list of values.

- `bubbles`:

  Should the message bubble to ancestors?

#### Returns

The event (invisibly), or `NULL` when not attached to an app.

------------------------------------------------------------------------

### `Widget$set_timeout()`

Call `callback(self, app)` once after `delay` seconds. The timer is
cancelled automatically when the widget is removed.

#### Usage

    Widget$set_timeout(delay, callback)

#### Arguments

- `delay`:

  Seconds.

- `callback`:

  Function.

#### Returns

A [Timer](https://menshikovs.github.io/termr/reference/Timer.md).

------------------------------------------------------------------------

### `Widget$set_interval()`

Call `callback(self, app)` every `interval` seconds while the widget is
mounted.

#### Usage

    Widget$set_interval(interval, callback)

#### Arguments

- `interval`:

  Seconds.

- `callback`:

  Function.

#### Returns

A [Timer](https://menshikovs.github.io/termr/reference/Timer.md).

------------------------------------------------------------------------

### `Widget$animate()`

Animate a numeric field of this widget. See
[`animate()`](https://menshikovs.github.io/termr/reference/animate.md).

#### Usage

    Widget$animate(property, to, ...)

#### Arguments

- `property`:

  Field name.

- `to`:

  Target value.

- `...`:

  Other arguments of
  [`animate()`](https://menshikovs.github.io/termr/reference/animate.md).

------------------------------------------------------------------------

### `Widget$run_worker()`

Run a background worker owned by this widget (cancelled when the widget
is removed). See
[`run_worker()`](https://menshikovs.github.io/termr/reference/run_worker.md).

#### Usage

    Widget$run_worker(fn, ...)

#### Arguments

- `fn`:

  Function to run.

- `...`:

  Other arguments of
  [`run_worker()`](https://menshikovs.github.io/termr/reference/run_worker.md).

------------------------------------------------------------------------

### `Widget$run_process()`

Run an external program owned by this widget. See
[`run_process()`](https://menshikovs.github.io/termr/reference/run_worker.md).

#### Usage

    Widget$run_process(command, ...)

#### Arguments

- `command`:

  Program to run.

- `...`:

  Other arguments of
  [`run_process()`](https://menshikovs.github.io/termr/reference/run_worker.md).

------------------------------------------------------------------------

### `Widget$focus()`

Give keyboard focus to this widget.

#### Usage

    Widget$focus()

------------------------------------------------------------------------

### `Widget$blur()`

Remove keyboard focus from this widget.

#### Usage

    Widget$blur()

------------------------------------------------------------------------

### `Widget$add_class()`

Add classes.

#### Usage

    Widget$add_class(...)

#### Arguments

- `...`:

  Class names.

------------------------------------------------------------------------

### `Widget$remove_class()`

Remove classes.

#### Usage

    Widget$remove_class(...)

#### Arguments

- `...`:

  Class names.

------------------------------------------------------------------------

### `Widget$toggle_class()`

Add a class if absent, remove it if present.

#### Usage

    Widget$toggle_class(name)

#### Arguments

- `name`:

  Class name.

------------------------------------------------------------------------

### `Widget$has_class()`

Does the widget have this class?

#### Usage

    Widget$has_class(name)

#### Arguments

- `name`:

  Class name.

------------------------------------------------------------------------

### `Widget$set()`

Assign one or more fields, e.g.
`app$query_one("#name")$set(value = "")`. R does not allow
`app$query_one("#name")$value <- ""`, so use this method when the widget
comes from a function call.

#### Usage

    Widget$set(...)

#### Arguments

- `...`:

  Named values.

#### Returns

The widget, invisibly (so calls can be chained).

------------------------------------------------------------------------

### `Widget$get_state()`

Read a state field.

#### Usage

    Widget$get_state(name)

#### Arguments

- `name`:

  Field name.

------------------------------------------------------------------------

### `Widget$set_state()`

Write a state field; invalidates the widget when the value changes.

#### Usage

    Widget$set_state(name, value)

#### Arguments

- `name`:

  Field name.

- `value`:

  New value.

------------------------------------------------------------------------

### `Widget$layout_differs()`

Would the widget's size-related style differ if it were in the pseudo
states `with` rather than `without`? Used to decide whether a focus /
hover change needs a layout pass.

#### Usage

    Widget$layout_differs(with, without)

#### Arguments

- `with, without`:

  Character vectors of states.

------------------------------------------------------------------------

### `Widget$invalidate()`

Mark the widget as needing a re-render and schedule a repaint, including
a new layout pass (its size may have changed). Repaints are batched per
event-loop tick.

#### Usage

    Widget$invalidate()

------------------------------------------------------------------------

### `Widget$invalidate_paint()`

Like `invalidate()` for changes that cannot affect the size or position
of anything (a cursor moved, a colour changed): the widget is repainted
but the layout is not recomputed.

#### Usage

    Widget$invalidate_paint()

------------------------------------------------------------------------

### `Widget$refresh()`

Force the widget to re-render on the next repaint.

#### Usage

    Widget$refresh()

------------------------------------------------------------------------

### `Widget$render_lines()`

Rendered content as lines of styled segments (cached until the widget is
invalidated).

#### Usage

    Widget$render_lines(width = NA_integer_)

#### Arguments

- `width`:

  Available content width (may be `NA` while measuring).

------------------------------------------------------------------------

### `Widget$content_width()`

Natural width of the content area.

#### Usage

    Widget$content_width()

------------------------------------------------------------------------

### `Widget$content_height()`

Natural height of the content area for a given width.

#### Usage

    Widget$content_height(width)

#### Arguments

- `width`:

  Content width.

------------------------------------------------------------------------

### `Widget$arrange_children()`

Place the visible children inside the content box. Containers with
special behaviour (scrolling, ...) override this.

#### Usage

    Widget$arrange_children(children, inner, st)

#### Arguments

- `children`:

  Visible child widgets.

- `inner`:

  Content rectangle of this widget.

- `st`:

  Computed style of this widget.

#### Returns

A list with one rectangle per child.

------------------------------------------------------------------------

### `Widget$child_clip()`

The rectangle children are clipped to when painting.

#### Usage

    Widget$child_clip(st)

#### Arguments

- `st`:

  Computed style of this widget.

------------------------------------------------------------------------

### `Widget$pseudo_states()`

Names of active states used to select state styles.

#### Usage

    Widget$pseudo_states()

------------------------------------------------------------------------

### `Widget$computed_style()`

The fully resolved style of the widget.

#### Usage

    Widget$computed_style(inherited = NULL)

#### Arguments

- `inherited`:

  The parent's computed style (computed if `NULL`).

------------------------------------------------------------------------

### `Widget$layout_descend()`

Which children need their own layout? Containers that clip their
children (scroll views) skip the ones that are entirely out of view;
they get their region but not their descendants.

#### Usage

    Widget$layout_descend(rects)

#### Arguments

- `rects`:

  The rectangles `arrange_children()` returned.

------------------------------------------------------------------------

### `Widget$paint()`

Paint the widget (not its children) into a buffer.

#### Usage

    Widget$paint(buffer, area, st)

#### Arguments

- `buffer`:

  A
  [ScreenBuffer](https://menshikovs.github.io/termr/reference/ScreenBuffer.md).

- `area`:

  The visible part of `self$region`.

- `st`:

  The computed style.

------------------------------------------------------------------------

### `Widget$is_enabled()`

Is the widget and every ancestor enabled?

#### Usage

    Widget$is_enabled()

------------------------------------------------------------------------

### `Widget$is_displayed()`

Is the widget and every ancestor visible?

#### Usage

    Widget$is_displayed()

------------------------------------------------------------------------

### `Widget$format()`

A one-line description used by
[`print()`](https://rdrr.io/r/base/print.html).

#### Usage

    Widget$format(...)

#### Arguments

- `...`:

  Ignored.

------------------------------------------------------------------------

### `Widget$print()`

Print the widget tree.

#### Usage

    Widget$print(...)

#### Arguments

- `...`:

  Ignored.

------------------------------------------------------------------------

### `Widget$clone()`

The objects of this class are cloneable with this method.

#### Usage

    Widget$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
