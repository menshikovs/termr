test_that("the published worker API keeps its argument order and cancel default", {
  legacy_run_worker <- c(
    "fn", "args", "on_complete", "on_error", "on_progress", "name", "owner",
    "packages", "inline", "on_stdout", "on_stderr", "timeout", "app"
  )
  legacy_run_process <- c(
    "command", "args", "on_complete", "on_error", "on_stdout", "on_stderr",
    "on_exit", "timeout", "wd", "env", "name", "owner", "app"
  )
  legacy_app_run_worker <- legacy_run_worker[-length(legacy_run_worker)]
  legacy_app_run_process <- legacy_run_process[-length(legacy_run_process)]
  legacy_run_worker_defaults <- alist(
    fn =, args = list(), on_complete = NULL, on_error = NULL, on_progress = NULL,
    name = NULL, owner = NULL, packages = character(), inline = FALSE,
    on_stdout = NULL, on_stderr = NULL, timeout = NULL, app = current_app()
  )
  legacy_app_run_worker_defaults <- legacy_run_worker_defaults[-length(legacy_run_worker_defaults)]
  legacy_run_process_defaults <- alist(
    command =, args = character(), on_complete = NULL, on_error = NULL,
    on_stdout = NULL, on_stderr = NULL, on_exit = NULL, timeout = NULL,
    wd = NULL, env = NULL, name = NULL, owner = NULL, app = current_app()
  )
  legacy_app_run_process_defaults <- legacy_run_process_defaults[-length(legacy_run_process_defaults)]

  expect_identical(
    head(names(formals(termr::run_worker)), length(legacy_run_worker)),
    legacy_run_worker
  )
  expect_identical(
    head(names(formals(termr::run_process)), length(legacy_run_process)),
    legacy_run_process
  )
  expect_identical(
    head(names(formals(termr::App$public_methods$run_worker)), length(legacy_app_run_worker)),
    legacy_app_run_worker
  )
  expect_identical(
    head(names(formals(termr::App$public_methods$run_process)), length(legacy_app_run_process)),
    legacy_app_run_process
  )
  expect_identical(
    as.list(formals(termr::run_worker)[legacy_run_worker]),
    as.list(legacy_run_worker_defaults)
  )
  expect_identical(
    as.list(formals(termr::App$public_methods$run_worker)[legacy_app_run_worker]),
    as.list(legacy_app_run_worker_defaults)
  )
  expect_identical(
    as.list(formals(termr::run_process)[legacy_run_process]),
    as.list(legacy_run_process_defaults)
  )
  expect_identical(
    as.list(formals(termr::App$public_methods$run_process)[legacy_app_run_process]),
    as.list(legacy_app_run_process_defaults)
  )
  expect_identical(names(formals(termr::Worker$public_methods$cancel)), "grace")
  expect_identical(formals(termr::Worker$public_methods$cancel)$grace, 0.3)
  expect_identical(names(formals(termr::App$public_methods$exit))[[1]], "value")
  expect_null(formals(termr::App$public_methods$exit)$value)
})

test_that("legacy inline completion, failure and synchronous cancellation remain stable", {
  events <- character()
  callbacks <- new.env(parent = emptyenv())
  callbacks$complete <- 0L
  callbacks$error <- 0L
  application <- termr::app(
    termr::label("compatibility"),
    termr::on("*", function(event, app) {
      if (startsWith(event$type, "worker.")) events <<- c(events, event$type)
    })
  )
  pilot <- termr::test_app(application, width = 20, height = 2)
  on.exit(pilot$stop(), add = TRUE)

  completed <- application$run_worker(
    function() 42L,
    inline = TRUE,
    on_complete = function(result, app) {
      expect_identical(result, 42L)
      callbacks$complete <- callbacks$complete + 1L
    },
    on_error = function(message, app) callbacks$error <- callbacks$error + 1L
  )
  pilot$step()
  expect_identical(completed$state, "completed")
  expect_identical(completed$result, 42L)
  expect_identical(callbacks$complete, 1L)
  expect_identical(callbacks$error, 0L)
  expect_identical(events, c("worker.started", "worker.completed"))
  expect_identical(completed$cancel(), FALSE)

  events <- character()
  failed <- application$run_worker(
    function() stop("compatibility failure"),
    inline = TRUE,
    on_complete = function(result, app) callbacks$complete <- callbacks$complete + 1L,
    on_error = function(message, app) {
      expect_match(message, "compatibility failure")
      callbacks$error <- callbacks$error + 1L
    }
  )
  pilot$step()
  expect_identical(failed$state, "failed")
  expect_match(failed$error, "compatibility failure")
  expect_identical(callbacks$complete, 1L)
  expect_identical(callbacks$error, 1L)
  expect_identical(events, c("worker.started", "worker.failed"))

  standalone <- termr::Worker$new("compatibility-cancel")
  expect_identical(standalone$cancel(), TRUE)
  expect_identical(standalone$state, "cancelled")
  expect_identical(standalone$cancel(), FALSE)
})

test_that("legacy App exit still returns its value and keeps NULL as the default", {
  application <- termr::app(
    termr::label("exit"),
    termr::bind("q", function(app) app$exit("legacy value"))
  )
  pilot <- termr::test_app(application, width = 20, height = 2)
  on.exit(pilot$stop(), add = TRUE)
  pilot$press("q")
  expect_true(pilot$exited)
  expect_identical(pilot$value, "legacy value")

  default_application <- termr::app(
    termr::label("exit"),
    termr::bind("q", function(app) app$exit())
  )
  default_pilot <- termr::test_app(default_application, width = 20, height = 2)
  on.exit(default_pilot$stop(), add = TRUE)
  default_pilot$press("q")
  expect_true(default_pilot$exited)
  expect_null(default_pilot$value)
})
