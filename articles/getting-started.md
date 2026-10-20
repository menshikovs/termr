# Build a Terminal UI in R with termr

termr is a reactive terminal user interface (TUI) framework for R.
Applications combine a widget tree, layouts, event handlers and keyboard
bindings. This tutorial uses stable exported APIs and the verified basic
application recipe.

## Install termr

Use R 4.1 or newer. termr is available through R-universe, not CRAN:

``` r

install.packages(
  "termr",
  repos = c("https://menshikovs.r-universe.dev", "https://cloud.r-project.org")
)
```

For development installation and platform limits, see the [installation
guide](https://menshikovs.github.io/termr/index.html#installation) and
[platform
matrix](https://github.com/menshikovs/termr/blob/main/docs/platform-testing.md).

## Compose your first application

Save the following chunk as `basic-app.R`. It constructs the app without
starting terminal input, so the same object can be tested headlessly.

``` r

library(termr)

ui <- vertical(
  label("What is your name?"),
  input(id = "name", placeholder = "Your name"),
  button("Say hello", id = "hello", variant = "primary"),
  label("", id = "output")
)

application <- app(
  ui,
  on("button.pressed", "#hello", function(event, app) {
    name <- app$query_one("#name")$value
    app$query_one("#output")$update(paste("Hello,", name))
  }),
  bind("escape", "quit")
)
```

[`vertical()`](https://menshikovs.github.io/termr/reference/vertical.md)
stacks the widgets. Use
[`horizontal()`](https://menshikovs.github.io/termr/reference/vertical.md)
for a row or
[`grid_layout()`](https://menshikovs.github.io/termr/reference/grid_layout.md)
for a grid. `id` identifies a widget for selectors such as `#name`; the
button event handler reads the input’s `$value` and updates the output
label. [`bind()`](https://menshikovs.github.io/termr/reference/bind.md)
connects a key to an action.

## Run in a real terminal

``` sh
Rscript -e "source('basic-app.R'); termr::run(application)"
```

Type a name, press Tab to focus the button, then Enter. Escape quits.
Use a real terminal or IDE terminal tab; an IDE console cannot host the
full-screen app. Handled exits restore the terminal, while forced
process termination cannot guarantee cleanup.

## Verify without a terminal

After sourcing `basic-app.R` in a fresh R session, run:

``` r

verify_greeting <- function() {
  pilot <- test_app(application, width = 40, height = 10)
  on.exit(pilot$stop(), add = TRUE)
  pilot$type("Ada")
  pilot$press("tab", "enter")
  stopifnot(identical(pilot$query_one("#output")$text, "Hello, Ada"))
  stopifnot(any(grepl("Hello, Ada", pilot$screen_text(), fixed = TRUE)))
}
verify_greeting()
```

This chunk executes during the website build. It checks keyboard
handling, widget state and rendered text through the normal event loop.

## Continue building

- [Build a navigable, sortable
  dashboard](https://menshikovs.github.io/termr/articles/terminal-dashboards.md).
- [Test keyboard input and screen
  output](https://menshikovs.github.io/termr/articles/testing-terminal-ui.md).
- Browse the
  [`app()`](https://menshikovs.github.io/termr/reference/app.md),
  [`data_table()`](https://menshikovs.github.io/termr/reference/data_table.md)
  and
  [`test_app()`](https://menshikovs.github.io/termr/reference/test_app.md)
  references.
- Consult the original [getting started
  guide](https://github.com/menshikovs/termr/blob/main/docs/getting-started.md)
  and [canonical
  recipes](https://github.com/menshikovs/termr/tree/main/docs/agent-recipes).

The reactive graph and advanced database, worker and extension APIs are
experimental; see the [stability
policy](https://github.com/menshikovs/termr/blob/main/docs/stability.md).
