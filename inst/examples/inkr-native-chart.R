# inkr styles apply to native chart widgets through the ordinary widget tree.
# Requires inkr.
library(termr)

sheet <- inkr::ink_compile(inkr::ink_parse("
  .metrics { padding: 1; background: #171d27; }
  .metrics .line-chart { color: #76c7c0; }
  .metrics .scatter-chart { color: #f4b860; }
"))
x <- seq_len(40)
ui <- app(
  vertical(
    line_chart(x, cumsum(sin(x / 4)), title = "Line", classes = "line-chart", interactive = FALSE),
    scatter_chart(x, cos(x / 5), title = "Scatter", classes = "scatter-chart", interactive = FALSE),
    classes = "metrics"
  ),
  inkr_stylesheet = sheet,
  bind("q", "quit")
)
run(ui)
