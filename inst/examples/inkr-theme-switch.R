# Replace the compiled inkr sheet when changing inkr themes. Requires inkr.
library(termr)

light_sheet <- inkr::ink_compile(inkr::ink_parse(
  ".panel { color: #20252d; background: #f0f2f5; } Button { background: #d5e6ff; }"
))
dark_sheet <- inkr::ink_compile(inkr::ink_parse(
  ".panel { color: #f0f2f5; background: #20252d; } Button { background: #38475c; }"
))
state <- new.env(parent = emptyenv())
state$dark <- FALSE

ui <- app(
  vertical(
    label("Theme is switched by replacing the compiled inkr sheet", classes = "panel"),
    button("Toggle theme", id = "theme")
  ),
  inkr_stylesheet = light_sheet,
  on("button.pressed", "#theme", function(event, app) {
    state$dark <- !state$dark
    app$theme <- if (state$dark) "dark" else "light"
    app$set_inkr_stylesheet(if (state$dark) dark_sheet else light_sheet)
  }),
  bind("q", "quit")
)
run(ui)
