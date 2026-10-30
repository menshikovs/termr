test_that("streams validate configuration and retain bounded chronological values", {
  for (bad in list(-1, NA_real_, Inf, 1.5, "3", numeric(), c(1, 2), .Machine$integer.max + 1)) {
    expect_error(termr_stream(history = bad), "history")
  }
  expect_error(termr_stream(name = 1), "name")
  x <- termr_stream(history = 3L)
  expect_null(x$latest())
  expect_identical(x$history(), list())
  x$emit(NULL)
  expect_identical(x$history(), list(NULL))
  for (i in 1:10) x$emit(i)
  expect_identical(x$history(), as.list(8:10))
  expect_identical(x$latest(), 10L)
  copy <- x$history()
  copy[[3]] <- -1
  expect_identical(x$latest(), 10L)
  x$clear()
  expect_null(x$latest())
  expect_identical(x$history(), list())
  x$emit(20)
  expect_identical(x$history(), list(20))
  y <- termr_stream(history = 0)
  y$emit(1)
  expect_identical(y$history(), list())
  expect_identical(y$latest(), 1)
  ref <- new.env()
  y$emit(ref)
  ref$value <- 2
  expect_identical(y$latest()$value, 2)
})

test_that("dispatch order is stable through subscription mutation", {
  x <- termr_stream()
  seen <- character()
  first <- x$subscribe(function(v) {
    seen <<- c(seen, paste0("a", v))
    second$unsubscribe()
    x$subscribe(function(v) seen <<- c(seen, paste0("c", v)))
  })
  second <- x$subscribe(function(v) seen <<- c(seen, paste0("b", v)))
  x$emit(1)
  expect_identical(seen, "a1")
  x$emit(2)
  expect_identical(seen, c("a1", "a2", "c2"))
  first$unsubscribe()
  first$unsubscribe()
  x$emit(3)
  expect_identical(tail(seen, 2), c("c3", "c3"))
  expect_identical(x$subscriber_count(), 2L)
  x$close()
  expect_identical(x$subscriber_count(), 0L)
})

test_that("self unsubscribe, errors, nested emissions and close are bounded", {
  x <- termr_stream()
  self <- x$subscribe(function(v) self$unsubscribe())
  x$subscribe(function(v) stop("broken"))
  x$subscribe(function(v) x$emit(v + 1))
  seen <- list()
  x$subscribe(function(v) seen[[length(seen) + 1L]] <<- v)
  expect_warning(x$emit(1), "callback errors \\(2\\): broken")
  expect_identical(seen, list(1))
  expect_identical(x$history(), list(1))
  expect_warning(x$emit(2), "callback errors")
  expect_identical(seen, list(1, 2))
  x$close(); x$close(); self$unsubscribe()
  expect_true(x$is_closed())
  expect_error(x$emit(3), "closed")
  expect_error(x$subscribe(identity), "closed")
  expect_identical(x$latest(), 2)
  y <- termr_stream()
  y$subscribe(function(v) y$close())
  y$subscribe(function(v) stop("should not run"))
  expect_silent(y$emit(1))
  expect_identical(y$subscriber_count(), 0L)
  expect_error(termr_stream()$subscribe(1), "callback")
})

test_that("stream callbacks bridge signals without adding implicit dependencies", {
  x <- termr_stream()
  a <- signal(0)
  other <- signal(5)
  seen <- numeric()
  w <- watch(function() seen <<- c(seen, a()))
  on.exit(dispose(w), add = TRUE)
  sub <- x$subscribe(function(v) { other(); a(v) })
  x$emit(1); x$emit(1)
  expect_identical(seen, c(0, 1))
  sub$unsubscribe()
  x$emit(2)
  expect_identical(peek(a), 1)
  trigger <- signal(0)
  outer <- watch(function() { trigger(); x$emit(3) })
  on.exit(dispose(outer), add = TRUE)
  sub2 <- x$subscribe(function(v) other())
  trigger(1)
  expect_identical(inspect_signal(outer)$dependencies, inspect_signal(trigger)$name)
  sub2$unsubscribe()
})

test_that("inactive handles release callbacks and clear releases retained values", {
  x <- termr_stream(history = 2L)
  finalized <- new.env()
  finalized$n <- 0L
  make_object <- function() {
    object <- new.env()
    reg.finalizer(object, function(e) finalized$n <- finalized$n + 1L)
    object
  }
  install <- function() {
    object <- make_object()
    x$subscribe(function(v) object)
  }
  handle <- install()
  handle$unsubscribe()
  invisible(gc())
  expect_identical(finalized$n, 1L)
  x$emit(make_object())
  x$clear()
  invisible(gc())
  expect_identical(finalized$n, 2L)
  handle <- install()
  x$close()
  invisible(gc())
  expect_identical(finalized$n, 3L)
  # New instances are independent, including after another instance closes.
  expect_silent(termr_stream()$emit(1))
})

test_that("ring history matches a seeded model including null and repeated values", {
  set.seed(8321)
  for (capacity in c(0L, 1L, 2L, 7L, 50L)) {
    x <- termr_stream(history = capacity)
    model <- list()
    latest <- NULL
    for (step in seq_len(500L)) {
      if (runif(1) < 0.08) {
        x$clear(); model <- list(); latest <- NULL
      } else {
        latest <- sample(list(NULL, 1L, 2L, "data"), 1L)[[1L]]
        x$emit(latest)
        model <- tail(c(model, list(latest)), capacity)
      }
      expect_identical(x$history(), model)
      expect_identical(x$latest(), latest)
    }
  }
})

test_that("100000 emissions retain bounded storage and deliver all events", {
  x <- termr_stream(history = 64L)
  counts <- numeric(10)
  handles <- lapply(seq_along(counts), function(i) x$subscribe(function(v) counts[[i]] <<- counts[[i]] + v))
  for (i in seq_len(100000L)) x$emit(i)
  expect_identical(counts, rep(100000 * 100001 / 2, 10))
  expect_identical(x$history(), as.list(99937:100000))
  # Inspect storage as a white-box invariant: ring slot count cannot grow.
  storage <- environment(x$emit)$slots
  expect_length(ls(storage, all.names = TRUE), 64L)
  for (h in handles) { h$unsubscribe(); h$unsubscribe() }
  for (i in seq_len(1000L)) x$subscribe(identity)$unsubscribe()
  expect_identical(x$subscriber_count(), 0L)
  expect_length(ls(environment(x$emit)$callbacks), 0L)
})

test_that("interrupts restore dispatch state and unbound streams cause no app work", {
  x <- termr_stream()
  sub <- x$subscribe(function(v) {
    signalCondition(structure(list(message = "interrupted"), class = c("interrupt", "condition")))
  })
  interrupted <- FALSE
  tryCatch(x$emit(1), interrupt = function(e) interrupted <<- TRUE)
  expect_true(interrupted)
  sub$unsubscribe()
  expect_silent(x$emit(2))
  application <- app(label("Ready"))
  pilot <- test_app(application, 30, 5)
  on.exit(pilot$stop(), add = TRUE)
  before <- application$frame_stats
  for (i in 1:100) x$emit(i)
  pilot$step()
  expect_identical(application$frame_stats, before)
  expect_identical(pilot$query_one("Label")$text, "Ready")
})
