# inkr styles can target the typed DataTable widget without changing its data.
# Requires inkr.
library(termr)

sheet <- inkr::ink_compile(inkr::ink_parse("
  DataTable { color: #e8edf2; background: #1d2630; border: round #55718e; }
  DataTable:focus { border: round #ffd166; }
"))
data <- data.frame(name = c("Ada", "Grace"), score = c(98, 95))
ui <- app(
  vertical(label("Data stays typed"), data_table(data, show_types = TRUE, row_names = FALSE)),
  inkr_stylesheet = sheet,
  bind("q", "quit")
)
run(ui)
