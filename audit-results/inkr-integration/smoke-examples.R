pkgload::load_all(".", quiet = TRUE)

examples <- c(
  "inkr-stylesheet", "inkr-dashboard", "inkr-focus", "inkr-theme-switch",
  "inkr-native-chart", "inkr-datatable", "no-inkr-stylesheet"
)

for (name in examples) {
  env <- new.env(parent = globalenv())
  env$run <- function(app) {
    env$app <- app
    invisible(app)
  }
  sys.source(file.path("inst", "examples", paste0(name, ".R")), envir = env)
  stopifnot(inherits(env$app, "App"))
  buffer <- render_widget(env$app, 100L, 30L)
  stopifnot(inherits(buffer, "ScreenBuffer"))
  cat(name, "OK\n")
}
