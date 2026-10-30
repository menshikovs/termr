# A small form that fits comfortably in an 80x24 terminal.
# Run with: Rscript -e 'termr::run_example("compact-form")'

library(termr)

details <- label(
  "Additional context wraps to the available width so its full text remains readable.",
  id = "details",
  wrap = "word",
  visible = FALSE,
  style = style(foreground = "bright_black")
)

ui <- vertical(
  label("Run report", style = style(bold = TRUE)),
  label("Enter a name and choose an output format."),
  input(id = "name", placeholder = "Name"),
  radio_set(
    radio_button("Plain text", "text"),
    radio_button("JSON", "json"),
    selected = "text",
    id = "format"
  ),
  checkbox("Show details", id = "show_details"),
  details,
  button("Continue", id = "continue", variant = "primary"),
  id = "form",
  style = style(padding = c(1, 2), layout = "vertical")
)

application <- app(ui)
application$on("checkbox.changed", "#show_details", function(event, app) {
  app$query_one("#details")$set(visible = event$data$value)
})
application$on("button.pressed", "#continue", function(event, app) {
  name <- trimws(app$query_one("#name")$value)
  app$query_one("#details")$update(
    if (nzchar(name)) paste("Ready for", name) else "Enter a name to continue."
  )
  app$query_one("#details")$set(visible = TRUE)
})

if (interactive()) {
  run(application)
} else {
  pilot <- test_app(application, width = 80, height = 24)
  pilot$click("#show_details")
  stopifnot(isTRUE(details$visible))
  pilot$stop()
}
