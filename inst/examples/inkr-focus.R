# Focus is supplied to inkr as a live pseudo state. Requires inkr.
library(termr)

sheet <- inkr::ink_compile(inkr::ink_parse("
  Button { color: white; padding: 0 1; }
  Button:focus { color: black; background: #ffd166; border: round #ffd166; text-style: bold; }
"))

ui <- app(
  vertical(
    label("Use Tab and Shift+Tab to change focus"),
    button("First"), button("Second"), button("Third")
  ),
  inkr_stylesheet = sheet,
  bind("q", "quit")
)
run(ui)
