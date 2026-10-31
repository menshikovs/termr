# Read-only native chart dashboard. Run with:
#   Rscript -e 'termr::run_example("native-charts-static")'

library(termr)

set.seed(57)
x <- seq_len(40)
ui <- app(
  vertical(
    horizontal(
      line_chart(x, cumsum(sin(x / 4)), title = "Line", interactive = FALSE),
      scatter_chart(x, cos(x / 5), title = "Scatter", interactive = FALSE)
    ),
    horizontal(
      bar_chart(c("North", "South", "East", "West"), c(8, -3, 5, 11),
                title = "Regions", interactive = FALSE),
      histogram(rnorm(300), title = "Distribution", interactive = FALSE),
      heatmap_chart(matrix(rnorm(100), 10), title = "Residuals", interactive = FALSE)
    )
  ),
  bind("q", "quit")
)

run(ui)
