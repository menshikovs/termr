test_that("event bursts avoid quadratic list copies and preserve FIFO", {
  skip_if_not(capabilities("profmem"))
  q <- EventQueue$new()
  path <- tempfile()
  on.exit({Rprofmem(NULL); unlink(path)}, add = TRUE)
  values <- as.list(seq_len(1000L))
  Rprofmem(path)
  for (value in values) q$push(value)
  Rprofmem(NULL)
  bytes <- suppressWarnings(as.numeric(sub(":.*$", "", readLines(path, warn = FALSE))))
  expect_lt(sum(bytes, na.rm = TRUE), 2000000)
  for (i in 1:500) expect_identical(q$pop(), i)
  for (i in 1001:1100) q$push(i)
  expect_identical(q$size(), 600L)
  for (i in 501:1100) expect_identical(q$pop(), i)
  expect_true(q$is_empty())
  expect_null(q$pop())
  q$push(NULL)
  expect_true(q$is_empty())
  q$push(1L); q$clear()
  expect_null(q$pop())
  q$push(2L)
  expect_identical(q$pop(), 2L)
  expect_true(EventQueue$new()$is_empty())
  # Environment binding names intern R symbols. Reuse slots during sustained
  # non-empty traffic rather than retaining a new symbol for every event.
  q$push(0L)
  received <- integer(10000L)
  for (i in 1:10000) {q$push(i); received[[i]] <- q$pop()}
  expect_identical(received, 0:9999)
  expect_lte(q$.__enclos_env__$private$head, 64L)
  expect_lte(q$.__enclos_env__$private$tail, 64L)
  expect_identical(q$pop(), 10000L)
  # Grow while the logical FIFO is split across the end of the ring.
  for (i in 1:50) q$push(i)
  expect_identical(vapply(1:40, function(i) q$pop(), 1L), 1:40)
  for (i in 51:200) q$push(i)
  expect_identical(vapply(41:200, function(i) q$pop(), 1L), 41:200)
})

test_that("unmount without an inkr sheet leaves the unused bridge cache alone", {
  root <- vertical(label("a"), label("b"))
  a <- app(root)
  cache <- a$.__enclos_env__$private$.inkr_cache
  root$remove_children()
  expect_true(identical(a$.__enclos_env__$private$.inkr_cache, cache))
  expect_length(root$children, 0L)
})

test_that("public inkr elements share parent construction within an epoch", {
  skip_if_not_installed("inkr")
  root <- vertical(label("a"), label("b"))
  a <- app(root, inkr_stylesheet = "Label { color: cyan; }")
  original <- inkr_call
  calls <- 0L
  local_mocked_bindings(inkr_call = function(name, ...) {
    if (name == "ink_element") calls <<- calls + 1L
    original(name, ...)
  })
  first <- inkr_element_for_widget(root$children[[1L]])
  second <- inkr_element_for_widget(root$children[[2L]])
  expect_lte(calls, 4L) # screen, parent, two children
  before <- calls
  expect_identical(inkr_element_for_widget(root$children[[1L]]), first)
  expect_identical(calls, before)
  root$add_class("changed")
  updated <- inkr_element_for_widget(root$children[[1L]])
  expect_gt(calls, before)
  expect_false(identical(first, updated))
  override <- inkr_element_for_widget(root$children[[1L]], "focus")
  expect_false(identical(override, updated))
  expect_identical(inkr_element_for_widget(root$children[[1L]]), updated)
})

test_that("continuously backlogged charts publish at a bounded cadence", {
  s <- termr_stream(history = 0L)
  chart <- line_chart(numeric(), numeric(), interactive = FALSE)
  p <- test_app(app(chart))
  on.exit({p$stop(); s$close()})
  chart$bind_stream(s, function(v) v$x, function(v) v$y, max_points = 100L)
  paints_before <- sum(p$app$frame_stats[c("full", "incremental")])
  counter <- 0L
  emit <- function(n) for (i in seq_len(n)) {
    counter <<- counter + 1L
    s$emit(list(x = counter, y = counter))
  }
  emit(64L); p$step()
  previous <- 0
  for (i in 1:40) {
    emit(16L); p$advance(.001)
    state <- chart$.__enclos_env__$private
    expect_gt(state$.stream_state$queue$size, 0L)
    expect_lte(length(state$.spec$data$x), 100L)
    latest <- tail(state$.spec$data$x, 1L)
    expect_length(latest, 1L)
    if (length(latest) && i %% 20L == 0L) {
      expect_gt(latest, previous)
      previous <- latest
    }
    if (!state$.stream_state$pending_render) expect_equal(state$.spec$data$x, state$.stream_state$x)
  }
  expect_lte(sum(p$app$frame_stats[c("full", "incremental")]) - paints_before, 4L)
  chart$remove()
  expect_identical(s$subscriber_count(), 0L)
  emit(20L); p$advance(1)
  expect_null(chart$.__enclos_env__$private$.stream_state)
})

test_that("inkr path caches invalidate across sheets, ancestors and reparenting", {
  skip_if_not_installed("inkr")
  w <- label("one", classes = "item")
  root <- vertical(w, classes = "red")
  a <- app(root, inkr_stylesheet = ".red .item { color: red; } .blue .item { color: blue; }")
  get_style <- function() inkr_style_for_widget(a, w)$props$foreground
  red <- get_style()
  root$classes <- "blue"
  blue <- get_style()
  expect_false(identical(red, blue))
  a$set_inkr_stylesheet(".item { color: green; }")
  expect_false(identical(blue, get_style()))
  other <- vertical(classes = "red")
  root$mount(other)
  w$remove(); other$mount(w)
  expect_identical(inkr_element_for_widget(w), inkr::ink_element(type = w$type, id = w$id,
    classes = w$classes, states = w$pseudo_states() %||% character(), parent = inkr_element_for_widget(other)))
  a$clear_inkr_stylesheet()
  expect_null(inkr_style_for_widget(a, w))
})
