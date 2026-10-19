# Events

Everything that happens in a termr application is an event: key presses,
terminal resizes, focus changes, widgets being mounted, and messages
that widgets send (such as `"button.pressed"`).

Events are delivered to their *target* widget and, if they bubble, to
each ancestor in turn and finally to the
[App](https://menshikovs.github.io/termr/reference/App-class.md). Any
handler can call `event$stop()` to stop propagation.

Event types and their classes:

- `"key"`: `KeyEvent` with fields `key`, `char`, `ctrl`, `alt`, `shift`;

- `"resize"`: `ResizeEvent` with `width` and `height`;

- `"paste"`: `PasteEvent` with the pasted `text` (bracketed paste);

- `"focus"` / `"blur"`: `FocusEvent` / `BlurEvent` (do not bubble);

- `"mount"` / `"unmount"`: `MountEvent` / `UnmountEvent` (do not
  bubble);

- any other name: `MessageEvent`, created by `widget$post_message()`.

## Public fields

- `type`:

  Event type, e.g. `"key"` or `"button.pressed"`.

- `sender`:

  The widget that created the event (or `NULL`).

- `target`:

  The widget the event is delivered to first.

- `current`:

  The widget currently handling the event.

- `data`:

  A list of event-specific values.

- `bubbles`:

  Is the event passed on to ancestors?

- `time`:

  Creation time (seconds, monotonic).

## Active bindings

- `stopped`:

  Has propagation been stopped?

- `default_prevented`:

  Was `prevent_default()` called?

## Methods

### Public methods

- [`Event$new()`](#method-Event-initialize)

- [`Event$stop()`](#method-Event-stop)

- [`Event$prevent_default()`](#method-Event-prevent_default)

- [`Event$format()`](#method-Event-format)

- [`Event$print()`](#method-Event-print)

- [`Event$clone()`](#method-Event-clone)

------------------------------------------------------------------------

### `Event$new()`

Create an event.

#### Usage

    Event$new(type, sender = NULL, data = list(), bubbles = TRUE)

#### Arguments

- `type`:

  Event type.

- `sender`:

  Sending widget.

- `data`:

  List of values.

- `bubbles`:

  Does the event bubble?

------------------------------------------------------------------------

### `Event$stop()`

Stop the event from reaching further handlers.

#### Usage

    Event$stop()

------------------------------------------------------------------------

### `Event$prevent_default()`

Ask the sender not to perform its default behaviour.

#### Usage

    Event$prevent_default()

------------------------------------------------------------------------

### `Event$format()`

One-line description.

#### Usage

    Event$format(...)

#### Arguments

- `...`:

  Ignored.

------------------------------------------------------------------------

### `Event$print()`

Print the event.

#### Usage

    Event$print(...)

#### Arguments

- `...`:

  Ignored.

------------------------------------------------------------------------

### `Event$clone()`

The objects of this class are cloneable with this method.

#### Usage

    Event$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Super class

`Event` -\> `KeyEvent`

## Public fields

- `key`:

  Canonical key name, e.g. `"a"`, `"enter"`, `"ctrl+c"`.

- `char`:

  The printable character, or `""`.

- `ctrl, alt, shift`:

  Modifier flags.

## Methods

### Public methods

- [`KeyEvent$new()`](#method-KeyEvent-initialize)

- [`KeyEvent$is_printable()`](#method-KeyEvent-is_printable)

- [`KeyEvent$clone()`](#method-KeyEvent-clone)

Inherited methods

- [`Event$format()`](https://menshikovs.github.io/termr/reference/Event.html#method-format)
- [`Event$prevent_default()`](https://menshikovs.github.io/termr/reference/Event.html#method-prevent_default)
- [`Event$print()`](https://menshikovs.github.io/termr/reference/Event.html#method-print)
- [`Event$stop()`](https://menshikovs.github.io/termr/reference/Event.html#method-stop)

------------------------------------------------------------------------

### `KeyEvent$new()`

Create a key event.

#### Usage

    KeyEvent$new(key, char = NULL)

#### Arguments

- `key`:

  Key name (normalised).

- `char`:

  Printable character, if any.

------------------------------------------------------------------------

### `KeyEvent$is_printable()`

Is this a printable character without ctrl/alt?

#### Usage

    KeyEvent$is_printable()

------------------------------------------------------------------------

### `KeyEvent$clone()`

The objects of this class are cloneable with this method.

#### Usage

    KeyEvent$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Super class

`Event` -\> `ResizeEvent`

## Public fields

- `width, height`:

  New terminal size.

## Methods

### Public methods

- [`ResizeEvent$new()`](#method-ResizeEvent-initialize)

- [`ResizeEvent$clone()`](#method-ResizeEvent-clone)

Inherited methods

- [`Event$format()`](https://menshikovs.github.io/termr/reference/Event.html#method-format)
- [`Event$prevent_default()`](https://menshikovs.github.io/termr/reference/Event.html#method-prevent_default)
- [`Event$print()`](https://menshikovs.github.io/termr/reference/Event.html#method-print)
- [`Event$stop()`](https://menshikovs.github.io/termr/reference/Event.html#method-stop)

------------------------------------------------------------------------

### `ResizeEvent$new()`

Create a resize event.

#### Usage

    ResizeEvent$new(width, height)

#### Arguments

- `width, height`:

  Terminal size.

------------------------------------------------------------------------

### `ResizeEvent$clone()`

The objects of this class are cloneable with this method.

#### Usage

    ResizeEvent$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Super class

`Event` -\> `PasteEvent`

## Public fields

- `text`:

  The pasted text, normalised: line breaks are LF, tabs are kept and
  other control characters are removed.

## Methods

### Public methods

- [`PasteEvent$new()`](#method-PasteEvent-initialize)

- [`PasteEvent$clone()`](#method-PasteEvent-clone)

Inherited methods

- [`Event$format()`](https://menshikovs.github.io/termr/reference/Event.html#method-format)
- [`Event$prevent_default()`](https://menshikovs.github.io/termr/reference/Event.html#method-prevent_default)
- [`Event$print()`](https://menshikovs.github.io/termr/reference/Event.html#method-print)
- [`Event$stop()`](https://menshikovs.github.io/termr/reference/Event.html#method-stop)

------------------------------------------------------------------------

### `PasteEvent$new()`

Create a paste event.

#### Usage

    PasteEvent$new(text)

#### Arguments

- `text`:

  Pasted text.

------------------------------------------------------------------------

### `PasteEvent$clone()`

The objects of this class are cloneable with this method.

#### Usage

    PasteEvent$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Super class

`Event` -\> `FocusEvent`

## Methods

### Public methods

- [`FocusEvent$new()`](#method-FocusEvent-initialize)

- [`FocusEvent$clone()`](#method-FocusEvent-clone)

Inherited methods

- [`Event$format()`](https://menshikovs.github.io/termr/reference/Event.html#method-format)
- [`Event$prevent_default()`](https://menshikovs.github.io/termr/reference/Event.html#method-prevent_default)
- [`Event$print()`](https://menshikovs.github.io/termr/reference/Event.html#method-print)
- [`Event$stop()`](https://menshikovs.github.io/termr/reference/Event.html#method-stop)

------------------------------------------------------------------------

### `FocusEvent$new()`

Create a focus event.

#### Usage

    FocusEvent$new(widget)

#### Arguments

- `widget`:

  The widget that received focus.

------------------------------------------------------------------------

### `FocusEvent$clone()`

The objects of this class are cloneable with this method.

#### Usage

    FocusEvent$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Super class

`Event` -\> `BlurEvent`

## Methods

### Public methods

- [`BlurEvent$new()`](#method-BlurEvent-initialize)

- [`BlurEvent$clone()`](#method-BlurEvent-clone)

Inherited methods

- [`Event$format()`](https://menshikovs.github.io/termr/reference/Event.html#method-format)
- [`Event$prevent_default()`](https://menshikovs.github.io/termr/reference/Event.html#method-prevent_default)
- [`Event$print()`](https://menshikovs.github.io/termr/reference/Event.html#method-print)
- [`Event$stop()`](https://menshikovs.github.io/termr/reference/Event.html#method-stop)

------------------------------------------------------------------------

### `BlurEvent$new()`

Create a blur event.

#### Usage

    BlurEvent$new(widget)

#### Arguments

- `widget`:

  The widget that lost focus.

------------------------------------------------------------------------

### `BlurEvent$clone()`

The objects of this class are cloneable with this method.

#### Usage

    BlurEvent$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Super class

`Event` -\> `MountEvent`

## Methods

### Public methods

- [`MountEvent$new()`](#method-MountEvent-initialize)

- [`MountEvent$clone()`](#method-MountEvent-clone)

Inherited methods

- [`Event$format()`](https://menshikovs.github.io/termr/reference/Event.html#method-format)
- [`Event$prevent_default()`](https://menshikovs.github.io/termr/reference/Event.html#method-prevent_default)
- [`Event$print()`](https://menshikovs.github.io/termr/reference/Event.html#method-print)
- [`Event$stop()`](https://menshikovs.github.io/termr/reference/Event.html#method-stop)

------------------------------------------------------------------------

### `MountEvent$new()`

Create a mount event.

#### Usage

    MountEvent$new(widget)

#### Arguments

- `widget`:

  The mounted widget.

------------------------------------------------------------------------

### `MountEvent$clone()`

The objects of this class are cloneable with this method.

#### Usage

    MountEvent$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Super class

`Event` -\> `UnmountEvent`

## Methods

### Public methods

- [`UnmountEvent$new()`](#method-UnmountEvent-initialize)

- [`UnmountEvent$clone()`](#method-UnmountEvent-clone)

Inherited methods

- [`Event$format()`](https://menshikovs.github.io/termr/reference/Event.html#method-format)
- [`Event$prevent_default()`](https://menshikovs.github.io/termr/reference/Event.html#method-prevent_default)
- [`Event$print()`](https://menshikovs.github.io/termr/reference/Event.html#method-print)
- [`Event$stop()`](https://menshikovs.github.io/termr/reference/Event.html#method-stop)

------------------------------------------------------------------------

### `UnmountEvent$new()`

Create an unmount event.

#### Usage

    UnmountEvent$new(widget)

#### Arguments

- `widget`:

  The removed widget.

------------------------------------------------------------------------

### `UnmountEvent$clone()`

The objects of this class are cloneable with this method.

#### Usage

    UnmountEvent$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Super class

`Event` -\> `MessageEvent`

## Methods

### Public methods

- [`MessageEvent$new()`](#method-MessageEvent-initialize)

- [`MessageEvent$clone()`](#method-MessageEvent-clone)

Inherited methods

- [`Event$format()`](https://menshikovs.github.io/termr/reference/Event.html#method-format)
- [`Event$prevent_default()`](https://menshikovs.github.io/termr/reference/Event.html#method-prevent_default)
- [`Event$print()`](https://menshikovs.github.io/termr/reference/Event.html#method-print)
- [`Event$stop()`](https://menshikovs.github.io/termr/reference/Event.html#method-stop)

------------------------------------------------------------------------

### `MessageEvent$new()`

Create a custom message.

#### Usage

    MessageEvent$new(type, sender = NULL, data = list(), bubbles = TRUE)

#### Arguments

- `type`:

  Message name, e.g. `"counter.changed"`.

- `sender`:

  Sending widget.

- `data`:

  List of values.

- `bubbles`:

  Does the message bubble?

------------------------------------------------------------------------

### `MessageEvent$clone()`

The objects of this class are cloneable with this method.

#### Usage

    MessageEvent$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Super class

`Event` -\> `MouseEvent`

## Public fields

- `action`:

  `"down"`, `"up"`, `"move"`, `"scroll"` or `"click"`.

- `button`:

  `"left"`, `"middle"`, `"right"` or `"none"`.

- `direction`:

  Wheel direction for scroll events, else `NA`.

- `screen_x, screen_y`:

  Pointer position on the screen (1-based).

- `x, y`:

  Pointer position inside the target widget (1-based, relative to the
  widget's region).

- `origin_x, origin_y`:

  Where the button went down (screen coordinates) for `drag.*` events,
  else `NA`.

- `shift, ctrl, alt`:

  Modifier flags.

## Methods

### Public methods

- [`MouseEvent$new()`](#method-MouseEvent-initialize)

- [`MouseEvent$offset_in()`](#method-MouseEvent-offset_in)

- [`MouseEvent$clone()`](#method-MouseEvent-clone)

Inherited methods

- [`Event$format()`](https://menshikovs.github.io/termr/reference/Event.html#method-format)
- [`Event$prevent_default()`](https://menshikovs.github.io/termr/reference/Event.html#method-prevent_default)
- [`Event$print()`](https://menshikovs.github.io/termr/reference/Event.html#method-print)
- [`Event$stop()`](https://menshikovs.github.io/termr/reference/Event.html#method-stop)

------------------------------------------------------------------------

### `MouseEvent$new()`

Create a mouse event.

#### Usage

    MouseEvent$new(
      action,
      screen_x,
      screen_y,
      button = "none",
      direction = NA_character_,
      shift = FALSE,
      ctrl = FALSE,
      alt = FALSE
    )

#### Arguments

- `action`:

  Event action.

- `screen_x, screen_y`:

  Screen position.

- `button`:

  Button name.

- `direction`:

  Wheel direction (scroll events).

- `shift, ctrl, alt`:

  Modifiers.

------------------------------------------------------------------------

### `MouseEvent$offset_in()`

The pointer position relative to another widget.

#### Usage

    MouseEvent$offset_in(widget)

#### Arguments

- `widget`:

  A widget with a region.

#### Returns

`c(x =, y =)`, 1-based; may be outside the widget.

------------------------------------------------------------------------

### `MouseEvent$clone()`

The objects of this class are cloneable with this method.

#### Usage

    MouseEvent$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
