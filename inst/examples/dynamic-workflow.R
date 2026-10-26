# Dynamic widgets, focus and reactive status using termr's public APIs.
# Run with: Rscript -e 'termr::run_example("dynamic-workflow")'
# Keys: arrows move through the list and table; Enter selects a filter;
# Ctrl+H toggles the details form.

library(termr)

job_data <- new.env(parent = emptyenv())
job_data$all <- data.frame(
  task = c("Read source", "Run checks", "Build report", "Review output", "Publish notes"),
  state = c("active", "active", "complete", "review", "complete"),
  stringsAsFactors = FALSE
)
filter_choices <- c(All = "all", Active = "active", Completed = "complete")
filters <- option_list(filter_choices, id = "filters", style = style(width = 22, height = 6))
results <- data_table(job_data$all, id = "jobs", style = style(width = "1fr", height = 8))
details <- vertical(
  label("Optional review note"),
  input(id = "note", placeholder = "Type a note"),
  id = "details"
)
details$visible <- TRUE

status_text <- signal("Ready")
visible_rows <- signal(nrow(job_data$all))
summary_text <- computed(function() {
  paste0(status_text(), " | ", visible_rows(), " rows")
})

show_rows <- function(value) {
  data <- job_data$all
  if (identical(value, "active")) data <- data[data$state == "active", , drop = FALSE]
  if (identical(value, "complete")) data <- data[data$state == "complete", , drop = FALSE]
  if (identical(value, "review")) data <- data[data$state == "review", , drop = FALSE]
  results$set_data(data)
  visible_rows(nrow(data))
}

toggle_details <- function(app) {
  details$visible <- !details$visible
  status_text(if (details$visible) "Details shown" else "Details hidden")
}

application <- app(
  vertical(
    label("Dynamic job workflow", style = style(bold = TRUE)),
    label("Select a filter and press Enter. Ctrl+H shows or hides the note field."),
    horizontal(filters, results, style = style(height = 8)),
    horizontal(
      button("Add review filter", id = "add-review", on_press = function(event, app) {
        if (!"review" %in% unname(filter_choices)) {
          filter_choices <<- c(filter_choices, `Needs review` = "review")
          filters$set_choices(filter_choices)
          status_text("Added a filter; the list now starts at the first choice")
        }
      }),
      button("Complete first task", id = "complete-task", on_press = function(event, app) {
        job_data$all$state[[1L]] <- "complete"
        show_rows(filters$value)
        status_text("Updated task state and refreshed the table")
      })
    ),
    details,
    label(function() summary_text(), id = "status")
  ),
  bindings = list(bind("ctrl+h", "toggle_details", "Toggle details")),
  actions = list(toggle_details = toggle_details),
  on("option_list.selected", function(event, app) {
    show_rows(event$data$value)
    status_text(paste("Showing", event$data$label))
  })
)

run(application)
