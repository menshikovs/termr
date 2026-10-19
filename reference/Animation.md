# Animation handle

Returned by
[`animate()`](https://menshikovs.github.io/termr/reference/animate.md).

## Public fields

- `widget, property`:

  What is animated.

- `from, to`:

  Start and end values.

- `duration`:

  Seconds.

- `easing`:

  Easing name.

- `start`:

  Clock time of the start.

- `active`:

  Still running?

- `on_complete`:

  `function(widget, app)` or `NULL`.

## Methods

### Public methods

- [`Animation$new()`](#method-Animation-initialize)

- [`Animation$cancel()`](#method-Animation-cancel)

- [`Animation$clone()`](#method-Animation-clone)

------------------------------------------------------------------------

### `Animation$new()`

Create an animation (use
[`animate()`](https://menshikovs.github.io/termr/reference/animate.md)).

#### Usage

    Animation$new(widget, property, from, to, duration, easing, start, on_complete)

#### Arguments

- `widget, property, from, to, duration, easing, start, on_complete`:

  See fields.

------------------------------------------------------------------------

### `Animation$cancel()`

Stop the animation where it is.

#### Usage

    Animation$cancel()

------------------------------------------------------------------------

### `Animation$clone()`

The objects of this class are cloneable with this method.

#### Usage

    Animation$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
