# Native chart dashboard. Run with:
#   Rscript -e 'termr::run_example("native-charts-dashboard")'
# Press Tab to move focus through the table and charts, arrows to move the
# current selection, r to replace every dataset, and q to quit.

library(termr)

set.seed(41)
x <- seq_len(24)
phase <- 0L
values <- data.frame(
  period = x,
  signal = round(sin(x / 4), 3),
  noise = round(cos(x / 5), 3)
)

table <- data_table(values, id = "chart-data", zebra = TRUE)
line <- line_chart(x, values$signal, title = "Signal", id = "signal-line")
scatter <- scatter_chart(values$signal, values$noise, title = "Signal vs noise", id = "scatter")
bars <- bar_chart(c("North", "South", "East", "West"), c(8, -3, 5, 11),
                  title = "Regional change", id = "regions")
distribution <- histogram(rnorm(300), title = "Noise distribution", id = "distribution")
heat <- heatmap_chart(matrix(rnorm(100), 10,
                             dimnames = list(paste0("r", 1:10), paste0("c", 1:10))),
                      title = "Residuals", id = "residuals")

refresh <- function(app) {
  phase <<- phase + 1L
  next_values <- data.frame(
    period = x,
    signal = round(sin(x / 4 + phase / 3), 3),
    noise = round(cos(x / 5 + phase / 4), 3)
  )
  table$set_data(next_values)
  line$update_data(x = x, y = next_values$signal)
  scatter$update_data(x = next_values$signal, y = next_values$noise)
  bars$update_data(labels = c("North", "South", "East", "West"),
                   values = c(8, -3, 5, 11) * (-1)^phase)
  distribution$update_data(x = rnorm(300, mean = phase / 4))
  heat$update_data(z = matrix(rnorm(100, mean = phase / 5), 10,
                              dimnames = list(paste0("r", 1:10), paste0("c", 1:10))))
  invisible(NULL)
}

ui <- app(
  vertical(
    label("Native charts — Tab selects a widget, arrows move its cursor, r refreshes data"),
    horizontal(table, line, scatter, style = style(height = "1fr")),
    horizontal(bars, distribution, heat, style = style(height = "1fr"))
  ),
  bind("r", refresh, description = "Refresh chart data"),
  bind("q", "quit")
)

run(ui)
