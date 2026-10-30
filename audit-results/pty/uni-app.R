library(termr)
log_file <- Sys.getenv("TERMR_PTY_LOG")
lg <- function(...) cat(paste0(..., "\n"), file = log_file, append = TRUE)
a <- app(vertical(
  label("Привет, мир 你好世界 😀👨‍👩‍👧 é \x1b[31mRED\x1b[0m tab\there", id = "u"),
  input(id = "in"),
  text_area(id = "ta"),
  button("OK", id = "ok"),
  label("", id = "out"),
  id = "root"))
a$on("button.pressed", "#ok", function(event, app) { lg("pressed"); app$query_one("#out")$update("done") })
a$set_timeout(0, function(app) lg("ready"))
a$on("key", function(event, app) lg("key ", event$key))
termr::run(a)
lg("exited")
