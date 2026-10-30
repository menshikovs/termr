#' Local data streams with bounded history
#'
#' An experimental, synchronous sequence of arbitrary R values, independent of
#' an app or terminal. Unlike [signal()], every emission is an event, including
#' identical values. No background process or scheduler is created.
#'
#' The returned stream has the following methods:
#' * `$emit(value)` stores and delivers a value in registration order.
#' * `$latest()` returns the last value, or `NULL` before the first emission.
#' * `$history()` returns a chronological list of at most `history` values.
#' * `$clear()` releases retained values, including the latest value.
#' * `$subscribe(callback)` returns a handle with an idempotent
#'   `$unsubscribe()` method. The callback receives one event, without replay.
#' * `$close()` disconnects subscribers and prevents emission/subscription.
#'   Repeated close is safe; retained values remain readable.
#' * `$is_closed()` and `$subscriber_count()` report lifecycle state.
#'
#' A subscriber removed during dispatch is skipped; a newly added subscriber
#' starts with the next event. Closing during dispatch stops further delivery.
#' Reentrant `emit()` is an error before storing the nested value. Callback
#' errors are isolated: other subscribers still run, then one warning reports
#' the error count and first message. Interrupts propagate with dispatch state
#' restored. Callbacks run [untracked()] so their reads do not attach to an
#' enclosing reactive observer. Use `$subscribe(function(x) state(x))` to
#' update an existing signal; identical writes keep normal signal semantics.
#'
#' Keep and explicitly unsubscribe handles at owner cleanup. Dropping a handle
#' does not unsubscribe: the stream owns callbacks until unsubscribe or close.
#' Storage uses a bounded ring with constant-time writes. R copy-on-modify
#' applies; reference objects (including environments) are shared, not cloned.
#' Treat emitted values as immutable. `history = 0L` disables history but keeps
#' the latest value. The bound counts events, not their byte size.
#'
#' @param name Optional diagnostic name.
#' @param history Non-negative integer maximum number of retained events.
#' @return A `termr_stream` handle with the methods described above. Mutating
#'   methods return invisibly; `subscribe()` returns a subscription handle.
#' @export
#' @examples
#' events <- termr_stream("metrics", history = 2L)
#' state <- signal(NULL)
#' sub <- events$subscribe(function(event) state(event))
#' events$emit(list(cpu = 42))
#' events$latest()
#' events$history()
#' sub$unsubscribe()
#' events$close()
termr_stream <- function(name = NULL, history = 1000L) {
  check_scalar_character(name, "name", allow_null = TRUE)
  if (!is.numeric(history) || length(history) != 1L || is.na(history) ||
      !is.finite(history) || history < 0 || history > .Machine$integer.max ||
      history != floor(history)) {
    stop("`history` must be a non-negative integer.", call. = FALSE)
  }
  capacity <- as.integer(history)
  # Mutable slots avoid copying a capacity-sized list on every emission.
  slots <- new.env(hash = TRUE, parent = emptyenv())
  callbacks <- new.env(hash = TRUE, parent = emptyenv())
  registry <- new.env(parent = emptyenv())
  registry$ids <- character()
  next_id <- 0
  size <- 0L
  cursor <- 0L
  last <- NULL
  closed <- FALSE
  dispatching <- FALSE
  assert_open <- function() {
    if (closed) stop("Stream is closed.", call. = FALSE)
  }
  clear <- function() {
    rm(list = ls(slots, all.names = TRUE), envir = slots)
    size <<- 0L
    cursor <<- 0L
    last <<- NULL
    invisible(NULL)
  }
  emit <- function(value) {
    assert_open()
    if (dispatching) stop("Reentrant stream emit() is not allowed.", call. = FALSE)
    last <<- value
    if (capacity > 0L) {
      cursor <<- if (cursor == capacity) 1L else cursor + 1L
      assign(as.character(cursor), value, envir = slots)
      size <<- min(size + 1L, capacity)
    }
    dispatching <<- TRUE
    on.exit(dispatching <<- FALSE, add = TRUE)
    errors <- 0L
    first_error <- NULL
    dispatch_ids <- registry$ids
    for (id in dispatch_ids) {
      if (closed) break
      if (!exists(id, envir = callbacks, inherits = FALSE)) next
      callback <- get(id, envir = callbacks, inherits = FALSE)
      tryCatch(untracked(callback(value)), error = function(e) {
        errors <<- errors + 1L
        if (is.null(first_error)) first_error <<- conditionMessage(e)
      })
    }
    if (errors) warning("Stream callback errors (", errors, "): ", first_error,
                        call. = FALSE)
    invisible(NULL)
  }
  subscribe <- function(callback) {
    assert_open()
    check_function(callback, "callback")
    next_id <<- next_id + 1
    id <- as.character(next_id)
    assign(id, callback, envir = callbacks)
    registry$ids <- c(registry$ids, id)
    # A minimal closure: an inactive retained handle must not retain its callback.
    structure(list(unsubscribe = stream_unsubscribe(callbacks, registry, id)),
              class = "termr_subscription")
  }
  close <- function() {
    closed <<- TRUE
    rm(list = ls(callbacks, all.names = TRUE), envir = callbacks)
    registry$ids <- character()
    invisible(NULL)
  }
  structure(list(
    name = name, emit = emit, latest = function() last,
    history = function() {
      if (!size) return(list())
      start <- if (size < capacity || cursor == capacity) 1L else cursor + 1L
      indices <- ((seq_len(size) - 1 + start - 1) %% capacity) + 1
      lapply(indices, function(i) get(as.character(i), envir = slots, inherits = FALSE))
    },
    clear = clear, subscribe = subscribe, close = close,
    is_closed = function() closed, subscriber_count = function() length(registry$ids)
  ), class = "termr_stream")
}

# A subscription's environment must not retain a subscribe() call frame (its
# callback argument) or the stream's retained event values after unsubscribe.
stream_unsubscribe <- function(callbacks, registry, id) {
  force(callbacks)
  force(registry)
  force(id)
  function() {
    if (exists(id, envir = callbacks, inherits = FALSE)) {
      rm(list = id, envir = callbacks)
      registry$ids <- registry$ids[registry$ids != id]
    }
    invisible(NULL)
  }
}
