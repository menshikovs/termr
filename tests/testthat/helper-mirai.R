mirai_test_pool <- function(...) {
  skip_if_not_installed("mirai", "2.7.3")
  skip_if_not_installed("nanonext", "1.10.0")
  skip_if_not_installed("jsonlite")
  termr_mirai_pool(...)
}

mirai_wait_for <- function(predicate, pool, timeout = 15) {
  deadline <- proc.time()[["elapsed"]] + timeout
  while (!isTRUE(predicate())) {
    pool$poll()
    if (proc.time()[["elapsed"]] > deadline) stop("mirai test timed out")
    Sys.sleep(.005)
  }
}

mirai_example <- function(file) {
  path <- test_path("..", "..", "inst", "examples", "mirai-tasks", file)
  if (!file.exists(path)) path <- system.file("examples", "mirai-tasks", file, package = "termr")
  env <- new.env(parent = globalenv())
  source(path, local = env)
  env
}
