# Terminal drivers

A driver is the only part of termr that talks to the terminal. It
switches the terminal into application mode (raw input, alternate
screen, hidden cursor), writes output, reports the terminal size and
turns input into
[Event](https://menshikovs.github.io/termr/reference/Event.md)s.
Everything above the driver is pure R and can be tested without a
terminal.

## Details

- `PosixDriver`: Linux, macOS and other Unix terminals (`stty` raw mode,
  input read from `/dev/tty`).

- `WindowsDriver`: Windows consoles and Windows Terminal (a small
  PowerShell helper reads key events).

- `HeadlessDriver`: no terminal at all; output goes to a virtual
  terminal and input is fed programmatically. Used by
  [`test_app()`](https://menshikovs.github.io/termr/reference/test_app.md).

[`run()`](https://menshikovs.github.io/termr/reference/run.md) picks the
right driver with `default_driver()`.
