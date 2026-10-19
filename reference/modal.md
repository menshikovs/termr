# Modal screens and dialogs

`modal()` builds a screen that is drawn over the current one and takes
the keyboard and mouse until it is closed. Show it with
`app$push_screen()`; close it with Escape or `screen$dismiss(result)`.
The previously focused widget gets focus back.

## Usage

``` r
modal(
  ...,
  title = NULL,
  width = 50L,
  dim = TRUE,
  dismissable = TRUE,
  on_dismiss = NULL,
  id = NULL
)

confirm_dialog(
  message,
  on_confirm = NULL,
  on_cancel = NULL,
  title = "Confirm",
  confirm_label = "OK",
  cancel_label = "Cancel",
  width = 50L
)

alert_dialog(message, title = "Message", button_label = "OK", width = 50L)
```

## Arguments

- ...:

  Content widgets (placed in a bordered panel).

- title:

  Panel title.

- width:

  Panel width (cells, `"auto"`, `"50%"`, ...).

- dim:

  Dim the screens below?

- dismissable:

  Can Escape close the dialog?

- on_dismiss:

  `function(result, app)` called when the dialog closes.

- id:

  Optional identifier of the screen.

- message:

  Message text.

- on_confirm, on_cancel:

  `function(app)` called when the user confirms, or cancels (Cancel
  button or Escape).

- confirm_label, cancel_label:

  Button labels.

- button_label:

  Label of the close button.

## Value

A `ModalScreen`.

## Details

`confirm_dialog()` and `alert_dialog()` are ready-made dialogs built on
`modal()`.

## Examples

``` r
dlg <- confirm_dialog("Delete file?", on_confirm = function(app) message("deleted"))
a <- app(label("main"))
pilot <- test_app(a, 40, 10)
a$push_screen(dlg)
pilot$press("tab", "enter") # move to OK, press it
#> deleted
pilot$stop()
```
