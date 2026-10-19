# Commands

A command is something the user can do: it has a label, an action, an
optional category and keyboard shortcut, and may be enabled or disabled
depending on the app state. The command palette (Ctrl+P) and the help
screen (F1) are built from the same list: commands added with
`app$add_command()`, the described key bindings of the focused widget,
its ancestors and the app, and the app's named actions. Existing
[`bind()`](https://menshikovs.github.io/termr/reference/bind.md)
bindings keep working and appear in both.

## Usage

``` r
command(
  label,
  action,
  category = NULL,
  shortcut = NULL,
  enabled = NULL,
  description = NULL
)
```

## Arguments

- label:

  Text shown in the palette and the help screen.

- action:

  An action name or a `function(app)`.

- category:

  Optional group name, e.g. `"File"`.

- shortcut:

  Optional key shown next to the command (documentation only; use
  [`bind()`](https://menshikovs.github.io/termr/reference/bind.md) to
  create the binding).

- enabled:

  `NULL` (always) or a `function(app)` returning `TRUE` / `FALSE`.
  Disabled commands are dimmed in the palette and cannot run.

- description:

  Optional longer text for the help screen.

## Value

An object of class `termr_command`.

## Examples

``` r
command("Save", action = "save", category = "File", shortcut = "ctrl+s")
#> <command File: Save (ctrl+s)>
```
