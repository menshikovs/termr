# Streaming input adapter for line and scatter charts. This consumes the
# existing termr stream protocol; it adds no scheduler or transport.

chart_stream_empty <- function(x, y) {
  list(x = x[integer()], y = y[integer()], source_id = NULL, sequence = NULL)
}

chart_stream_metadata <- function(event) {
  payload <- event
  source_id <- sequence <- NULL
  gap <- FALSE
  if (inherits(event, "termr_history_record") && is.list(event)) {
    payload <- event$payload
    source_id <- event$source_id
    sequence <- event$sequence
    gap <- isTRUE(event$gap)
  }
  if (is.list(payload)) {
    if (is.null(source_id)) source_id <- payload$source_id
    if (is.null(sequence)) sequence <- payload$sequence
    gap <- gap || isTRUE(payload$gap)
  }
  if (!is.character(source_id) || length(source_id) != 1L || is.na(source_id) || !nzchar(source_id)) {
    source_id <- NULL
  }
  if (!is.numeric(sequence) || length(sequence) != 1L || is.na(sequence) || !is.finite(sequence)) {
    sequence <- NULL
  }
  list(payload = payload, source_id = source_id, sequence = sequence, gap = gap)
}

chart_stream_value <- function(extractor, payload, name) {
  value <- extractor(payload)
  if (length(value) != 1L || !is.atomic(value) || is.object(value) &&
      !inherits(value, c("Date", "POSIXct"))) {
    stop("Stream extractor `", name, "` must return one scalar value.", call. = FALSE)
  }
  if (identical(name, "y") && !is.numeric(value)) {
    stop("Stream extractor `y` must return a numeric value (NA is allowed).", call. = FALSE)
  }
  if (identical(name, "x") &&
      !(is.numeric(value) || inherits(value, "Date") || inherits(value, "POSIXct"))) {
    stop("Stream extractor `x` must return numeric, Date, or POSIXct values.", call. = FALSE)
  }
  value
}

chart_stream_x_kind <- function(x) {
  if (inherits(x, "Date")) return("Date")
  if (inherits(x, "POSIXct")) return("POSIXct")
  if (is.numeric(x)) return("numeric")
  "other"
}

chart_stream_append <- function(x, value, max_points, name = "x") {
  if (!length(x)) {
    out <- value
  } else {
    if (identical(name, "x")) {
      old_kind <- chart_stream_x_kind(x)
      new_kind <- chart_stream_x_kind(value)
      if (!identical(old_kind, new_kind)) {
        stop("Stream extractor `x` changed type within one source.", call. = FALSE)
      }
      if (identical(old_kind, "POSIXct") &&
          !identical(attr(x, "tzone", exact = TRUE), attr(value, "tzone", exact = TRUE))) {
        stop("Stream extractor `x` changed time zone within one source.", call. = FALSE)
      }
    } else if (!is.numeric(x) || !is.numeric(value)) {
      stop("Stream extractor `y` changed from numeric within one source.", call. = FALSE)
    }
    out <- c(x, value)
  }
  if (length(out) > max_points) out <- out[seq.int(length(out) - max_points + 1L, length(out))]
  out
}

chart_stream_next <- function(state, event, x, y, max_points) {
  meta <- chart_stream_metadata(event)
  x_value <- chart_stream_value(x, meta$payload, "x")
  y_value <- chart_stream_value(y, meta$payload, "y")
  source_changed <- !is.null(state$source_id) && !is.null(meta$source_id) &&
    !identical(state$source_id, meta$source_id)
  sequence_restarted <- !is.null(meta$sequence) && !is.null(state$sequence) &&
    meta$sequence < state$sequence
  next_state <- state
  if (source_changed || sequence_restarted) {
    next_state$x <- next_state$x[integer()]
    next_state$y <- next_state$y[integer()]
    next_state$source_id <- NULL
    next_state$sequence <- NULL
  }
  sequence_gap <- !is.null(meta$sequence) && !is.null(next_state$sequence) &&
    meta$sequence > next_state$sequence + 1
  if ((meta$gap || sequence_gap) && length(next_state$x)) {
    next_state$x <- chart_stream_append(next_state$x, x_value, max_points)
    next_state$y <- chart_stream_append(next_state$y, NA_real_, max_points, name = "y")
  }
  next_state$x <- chart_stream_append(next_state$x, x_value, max_points)
  next_state$y <- chart_stream_append(next_state$y, y_value, max_points, name = "y")
  next_state$source_id <- meta$source_id %||% next_state$source_id
  next_state$sequence <- meta$sequence %||% next_state$sequence
  next_state
}

chart_stream_collect <- function(events, x, y, max_points, empty_x, empty_y) {
  state <- chart_stream_empty(empty_x, empty_y)
  for (event in events) state <- chart_stream_next(state, event, x, y, max_points)
  state
}

chart_stream_queue_new <- function(capacity) {
  queue <- new.env(parent = emptyenv())
  queue$capacity <- capacity
  queue$items <- list()
  queue$head <- 1L
  queue$size <- 0L
  queue$dropped <- FALSE
  queue
}

chart_stream_queue_push <- function(queue, event) {
  if (queue$size < queue$capacity) {
    index <- ((queue$head + queue$size - 1L) %% queue$capacity) + 1L
    queue$items[index] <- list(event)
    queue$size <- queue$size + 1L
  } else {
    queue$items[queue$head] <- list(event)
    queue$head <- (queue$head %% queue$capacity) + 1L
    queue$dropped <- TRUE
  }
  invisible(NULL)
}

chart_stream_queue_drain <- function(queue, limit = queue$capacity) {
  if (!queue$size) return(list(events = list(), dropped = FALSE))
  count <- min(queue$size, limit)
  indices <- ((queue$head - 1L + seq_len(count) - 1L) %% queue$capacity) + 1L
  events <- queue$items[indices]
  queue$items[indices] <- rep(list(NULL), length(indices))
  dropped <- queue$dropped
  queue$size <- queue$size - count
  queue$head <- if (queue$size) ((queue$head - 1L + count) %% queue$capacity) + 1L else 1L
  queue$dropped <- FALSE
  list(events = events, dropped = dropped)
}

chart_stream_mark_gap <- function(event) {
  if (inherits(event, "termr_history_record")) {
    event$gap <- TRUE
    return(event)
  }
  structure(list(payload = event, source_id = NULL, sequence = NULL, gap = TRUE),
            class = "termr_history_record")
}
