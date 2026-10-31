# Base termr styling needs no inkr installation.
library(termr)

ui <- app(
  vertical(
    label("This app uses only termr's built-in styles"),
    button("Continue", style = style(background = "$primary", bold = TRUE))
  ),
  theme = "dark",
  bind("q", "quit")
)
run(ui)
