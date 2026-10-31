# Basic inkr integration. Requires the optional package inkr.
library(termr)

sheet <- inkr::ink_compile(inkr::ink_parse("
  Button.primary { color: white; background: #315caa; text-style: bold; padding: 0 2; }
  Button.primary:focus { border: round yellow; }
"))

ui <- app(
  vertical(
    label("Tab to focus a button"),
    button("Save", classes = "primary"),
    button("Cancel")
  ),
  inkr_stylesheet = sheet,
  bind("q", "quit")
)
run(ui)
