# Timer handle

Returned by
[`set_timeout()`](https://menshikovs.github.io/termr/reference/set_timeout.md)
and
[`set_interval()`](https://menshikovs.github.io/termr/reference/set_timeout.md).

## Public fields

- `delay`:

  Delay (or interval) in seconds.

- `repeating`:

  Does the timer repeat?

- `due`:

  Clock time of the next run.

- `callback`:

  Function called when the timer fires.

- `active`:

  Is the timer still scheduled?

- `runs`:

  How many times the timer has fired.

## Methods

### Public methods

- [`Timer$new()`](#method-Timer-initialize)

- [`Timer$cancel()`](#method-Timer-cancel)

- [`Timer$print()`](#method-Timer-print)

- [`Timer$clone()`](#method-Timer-clone)

------------------------------------------------------------------------

### `Timer$new()`

Create a timer (use
[`set_timeout()`](https://menshikovs.github.io/termr/reference/set_timeout.md)
instead).

#### Usage

    Timer$new(delay, callback, repeating, now)

#### Arguments

- `delay`:

  Seconds.

- `callback`:

  Function.

- `repeating`:

  Logical.

- `now`:

  Current clock time.

------------------------------------------------------------------------

### `Timer$cancel()`

Stop the timer.

#### Usage

    Timer$cancel()

------------------------------------------------------------------------

### `Timer$print()`

Print the timer.

#### Usage

    Timer$print(...)

#### Arguments

- `...`:

  Ignored.

------------------------------------------------------------------------

### `Timer$clone()`

The objects of this class are cloneable with this method.

#### Usage

    Timer$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
