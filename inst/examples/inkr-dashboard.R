# Nested selectors across a dashboard widget tree. Requires inkr.
library(termr)

sheet <- inkr::ink_compile(inkr::ink_parse("
  .dashboard { color: white; background: #20252d; padding: 1; }
  .dashboard > .toolbar { background: #303945; padding: 0 1; }
  .dashboard Button.primary { border: round #70b7ff; text-style: bold; }
  .dashboard .warning { color: bright-yellow; }
"))

ui <- app(
  vertical(
    horizontal(button("Refresh", classes = "primary"), button("Delete", classes = "warning"),
               classes = "toolbar"),
    label("Dashboard content", classes = "content"),
    classes = "dashboard"
  ),
  inkr_stylesheet = sheet,
  bind("q", "quit")
)
run(ui)
