library(termr)
mode <- Sys.getenv("EXC_MODE")
bad_render <- widget("badr", render = function(self, ...) stop("render boom"))
register_layout("custom_bad", function(children, inner, parent_style) stop("layout boom"), function(children, parent_style) list(width = function() 1L, height = function(w) 1L), replace = TRUE)
ui <- switch(mode,
  render = vertical(label("ok"), bad_render()),
  layout = vertical(label("a"), label("b"), style = style(layout = "custom_bad")),
  timer = vertical(label("t")),
  worker = vertical(label("w")),
  worker_spawn = vertical(label("w")),
  stopfail = vertical(label("s")),
  vertical(label("default")))
a <- app(ui)
if (mode == "timer") a$set_timeout(0.3, function(app) stop("timer boom"))
if (mode == "worker") a$set_timeout(0.2, function(app) app$run_worker(function() stop("worker boom"), on_error = function(e, app) cat("worker error seen\n", file = Sys.getenv("TERMR_PTY_LOG"), append = TRUE)))
if (mode == "stopfail") { a$on("key", function(ev, app) if (ev$key == "q") app$exit("bye")); a$on("unmount", function(ev, app) stop("unmount boom")) }
cat("started\n", file = Sys.getenv("TERMR_PTY_LOG"), append = TRUE)
r <- tryCatch(termr::run(a), error = function(e) { cat("run error: ", conditionMessage(e), "\n", file = Sys.getenv("TERMR_PTY_LOG"), append = TRUE); quit(status = 3) })
cat("returned\n", file = Sys.getenv("TERMR_PTY_LOG"), append = TRUE)
