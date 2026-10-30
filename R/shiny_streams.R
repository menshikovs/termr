shiny_stream_require <- function() {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("Install optional package 'shiny' to use reactive stream adapters.", call. = FALSE)
  }
}

shiny_receiver_state <- function(receiver) attr(receiver, "termr_receiver", exact = TRUE)

#' Share a bounded telemetry receiver with Shiny sessions
#'
#' Experimental, explicit process-local sharing. Create one receiver outside
#' `server`, then give it to [termr_shiny_reactive()], [termr_shiny_history()]
#' and [termr_shiny_status()] in each session. It owns one source subscription,
#' one bounded observation ring and at most one Shiny poll observer. No
#' collectors, sockets or OS processes are started by this constructor.
#'
#' Each session acquires one lease regardless of the number of dependent
#' reactives/charts. The shared observer resumes for the first lease and is
#' suspended after the last session closes. A session cannot close a receiver
#' used by other sessions. The explicit owner calls `$close()` at app shutdown.
#' The source remains caller-owned unless `close_source = TRUE`. Unshared
#' adapters created implicitly for a session are destroyed at session end.
#'
#' `$poll()` performs one nonblocking source poll, if available, then publishes
#' at most one reactive latest/history revision. Bursts retain at most
#' `max_points` records while coalescing reactive invalidations. All callbacks
#' and graph updates run on the normal R thread. The source poll must itself
#' be bounded/nonblocking; slow source/validator callbacks delay their owner.
#' Status changes alone do not invalidate the data reactives when idle.
#'
#' History contains `termr_history_record` lists: payload, source_id, sequence,
#' timestamp, received_at and gap. It begins with the current latest snapshot,
#' if known, then observations seen by this receiver. It does not replay a
#' publisher's complete past. Known duplicate/older sequences are discarded;
#' source changes clear retained history. Missing metadata uses local receipt
#' identity and sequence. Missing timestamps use receipt time; malformed
#' explicitly supplied timestamps/failed validation preserve the last good
#' value and expose invalid status. Staleness uses receipt and measurement
#' timestamps independently. Transport schema errors are surfaced in status.
#'
#' Handles expose plain cached `$latest()`, `$history()`, `$status()`,
#' `$diagnostics()`, `$poll()`, `$close()` and `$is_closed()` methods.
#' Use the exported Shiny wrappers for reactive reads. No registry shares
#' objects across OS processes; create one receiver per Shiny R process.
#'
#' @param source An open local or remote stream handle with latest, subscribe
#'   and history methods; optional poll/status methods must be nonblocking.
#' @param interval Poll interval in milliseconds, from 10 to 60000.
#' @param max_points Bounded receiver history capacity, from 1 to 1000000.
#' @param stale_after Seconds before receipt/measurement is stale.
#' @param validate Optional payload validator returning exactly TRUE.
#' @param close_source Whether this receiver owns and closes its source.
#' @return A process-local receiver handle. Requires optional Shiny only.
#' @export
#' @examples
#' if (interactive() && requireNamespace("shiny", quietly = TRUE)) {
#'   events <- termr_stream("metrics")
#'   shared <- termr_shiny_receiver(events)
#'   # In server: metrics <- termr_shiny_reactive(shared, session)
#'   shared$close()
#'   events$close()
#' }
termr_shiny_receiver <- function(source, interval = 50L, max_points = 600L,
                                 stale_after = 5, validate = NULL, close_source = FALSE) {
  shiny_stream_require()
  max_points <- stream_point_limit(max_points)
  interval <- stream_point_limit(interval, "interval")
  if (interval < 10L || interval > 60000L) stop("`interval` must be 10..60000 ms.", call. = FALSE)
  if (!is.numeric(stale_after) || length(stale_after) != 1L || is.na(stale_after) ||
      !is.finite(stale_after) || stale_after <= 0) stop("Invalid `stale_after`.", call. = FALSE)
  check_flag(close_source, "close_source")
  check_function(validate, "validate", allow_null = TRUE)
  if (!is.list(source) || !all(vapply(c("latest", "history", "subscribe"), function(key) is.function(source[[key]]), logical(1)))) {
    stop("`source` must be a stream handle.", call. = FALSE)
  }
  if (is.function(source$is_closed) && source$is_closed()) stop("Source is closed.", call. = FALSE)
  state <- new.env(parent = emptyenv())
  state$closed <- FALSE; state$busy <- FALSE; state$refs <- 0L
  state$driver <- NULL; state$subscription <- NULL
  state$latest <- NULL; state$source <- NULL; state$sequence <- 0; state$has_value <- FALSE
  state$last_received <- -Inf; state$timestamp <- NA_real_
  state$invalid <- FALSE; state$error <- NULL; state$dirty <- FALSE
  state$generation <- 0L; state$processed <- 0; state$duplicates <- 0
  state$out_of_order <- 0; state$gaps <- 0; state$coalesced <- 0
  state$since_flush <- 0L; state$polls <- 0; state$poll_errors <- 0L
  state$remote_invalid <- 0; state$remote_resyncs <- 0
  state$history <- termr_stream("shiny.history", history = max_points)
  state$value <- shiny::reactiveVal(NULL, label = "termr.latest")
  state$revision <- shiny::reactiveVal(0, label = "termr.history")
  state$status_value <- shiny::reactiveVal(NULL, label = "termr.status")
  state$revision_number <- 0; state$status_cache <- NULL
  source_status <- function() if (is.function(source$status)) source$status() else list()
  receive <- function(payload) {
    if (state$closed) return(invisible(NULL))
    valid <- tryCatch(is.null(validate) || identical(validate(payload), TRUE), error = function(e) {
      state$error <- conditionMessage(e); FALSE
    })
    timestamp <- if (is.list(payload)) payload$timestamp else NULL
    seconds <- stream_time(timestamp)
    if (!valid || (!is.null(timestamp) && (is.na(seconds) || seconds > as.numeric(Sys.time()) + 5))) {
      state$invalid <- TRUE
      if (is.null(state$error)) state$error <- "Payload validation or timestamp failed."
      return(invisible(NULL))
    }
    remote <- source_status()
    id <- stream_scalar_text(remote$source_id)
    seq <- stream_scalar_number(remote$sequence)
    if (is.na(id) && is.list(payload)) id <- stream_scalar_text(payload$source_id)
    if (is.na(seq) && is.list(payload)) seq <- stream_scalar_number(payload$sequence)
    if (is.na(id)) id <- "local"
    if (is.na(seq)) seq <- if (identical(id, state$source)) state$sequence + 1 else 1
    if (seq < 0 || seq != floor(seq)) {
      state$invalid <- TRUE; state$error <- "Invalid observation sequence."; return(invisible(NULL))
    }
    if (!identical(id, state$source)) {
      state$history$clear(); state$source <- id; state$sequence <- 0
      state$generation <- state$generation + 1L
    } else if (seq <= state$sequence) {
      if (seq == state$sequence) state$duplicates <- state$duplicates + 1
      else state$out_of_order <- state$out_of_order + 1
      return(invisible(NULL))
    }
    gap <- state$sequence > 0 && seq > state$sequence + 1
    if (gap) state$gaps <- state$gaps + seq - state$sequence - 1
    received <- as.numeric(Sys.time())
    state$history$emit(structure(list(payload = payload, source_id = id, sequence = seq,
      timestamp = if (is.na(seconds)) received else seconds, received_at = received, gap = gap),
      class = "termr_history_record"))
    state$latest <- payload; state$has_value <- TRUE; state$sequence <- seq; state$timestamp <- seconds
    state$last_received <- now_seconds(); state$processed <- state$processed + 1
    state$since_flush <- state$since_flush + 1L; state$dirty <- TRUE
    state$invalid <- FALSE; state$error <- NULL
    invisible(NULL)
  }
  status <- function() {
    remote <- tryCatch(source_status(), error = function(e) list(state = "invalid"))
    source_closed <- is.function(source$is_closed) && isTRUE(source$is_closed())
    mode <- if (state$closed || source_closed || identical(remote$state, "closed")) "closed" else if (state$invalid || identical(remote$state, "invalid")) "invalid" else
      if (!state$has_value) "unavailable" else if (identical(remote$state, "stale") ||
        now_seconds() - state$last_received > stale_after ||
        (!is.na(state$timestamp) && as.numeric(Sys.time()) - state$timestamp > stale_after)) "stale" else "live"
    list(state = mode, source_id = state$source, sequence = state$sequence,
      timestamp = as.POSIXct(state$timestamp, origin = "1970-01-01", tz = "UTC"),
      generation = state$generation, gaps = max(state$gaps, if (is.null(remote$gaps)) 0 else remote$gaps),
      invalid = state$invalid, message = if (!is.null(state$error)) state$error else remote$last_error,
      reconnecting = identical(remote$state, "connecting") || identical(remote$state, "stale") || isTRUE(remote$needs_sync))
  }
  poll <- function() {
    if (state$closed || state$busy) return(invisible(NULL))
    state$busy <- TRUE
    on.exit(state$busy <- FALSE, add = TRUE)
    state$polls <- state$polls + 1
    if (is.function(source$poll)) tryCatch(source$poll(), error = function(e) {
      state$poll_errors <- state$poll_errors + 1L; state$invalid <- TRUE; state$error <- conditionMessage(e)
    })
    remote <- tryCatch(source_status(), error = function(e) list())
    remote_id <- stream_scalar_text(remote$source_id)
    # A restarted publisher may have an empty snapshot and emit no payload
    # callback. Do not present the previous publisher's cached value as current.
    if (!is.na(remote_id) && !identical(remote_id, state$source) &&
        identical(stream_scalar_number(remote$sequence), 0) && is.null(source$latest())) {
      state$history$clear(); state$latest <- NULL; state$has_value <- FALSE
      state$source <- remote_id; state$sequence <- 0; state$timestamp <- NA_real_
      state$last_received <- -Inf; state$generation <- state$generation + 1L
      state$dirty <- TRUE
    }
    invalid <- if (is.null(remote$invalid)) 0 else remote$invalid
    resyncs <- if (is.null(remote$resyncs)) 0 else remote$resyncs
    if (is.numeric(invalid) && invalid > state$remote_invalid) {
      state$invalid <- TRUE; state$error <- remote$last_error
    } else if (resyncs > state$remote_resyncs && is.null(remote$last_error)) {
      state$invalid <- FALSE; state$error <- NULL
    }
    state$remote_invalid <- invalid; state$remote_resyncs <- resyncs
    if (state$dirty) {
      state$coalesced <- state$coalesced + max(0L, state$since_flush - 1L)
      state$since_flush <- 0L; state$dirty <- FALSE
      state$value(state$latest)
      state$revision_number <- state$revision_number + 1
      state$revision(state$revision_number)
    }
    current <- status()
    if (!identical(current, state$status_cache)) {
      state$status_cache <- current; state$status_value(current)
    }
    invisible(NULL)
  }
  close_receiver <- function() {
    if (state$closed) return(invisible(NULL))
    state$closed <- TRUE
    if (!is.null(state$driver)) state$driver$destroy()
    if (!is.null(state$subscription)) state$subscription$unsubscribe()
    state$driver <- NULL; state$subscription <- NULL
    state$history$close()
    if (close_source && is.function(source$close)) source$close()
    state$status_value(status())
    invisible(NULL)
  }
  state$acquire <- function() {
    if (state$closed) stop("Receiver is closed.", call. = FALSE)
    state$refs <- state$refs + 1L
    if (is.null(state$driver)) state$driver <- shiny::observe({
      shiny::invalidateLater(interval, session = NULL)
      poll()
    }, domain = NULL, suspended = TRUE, label = "termr.shared.poll")
    if (state$refs == 1L) state$driver$resume()
    active <- TRUE
    function() {
      if (!active) return(invisible(NULL))
      active <<- FALSE
      state$refs <- max(0L, state$refs - 1L)
      if (state$refs == 0L && !is.null(state$driver)) state$driver$suspend()
      invisible(NULL)
    }
  }
  state$capacity <- max_points
  state$subscription <- source$subscribe(receive)
  ready <- FALSE
  on.exit(if (!ready) close_receiver(), add = TRUE)
  initial <- source$latest()
  if (!is.null(initial) || length(source$history())) receive(initial)
  poll()
  ready <- TRUE
  structure(list(latest = function() state$latest, history = state$history$history,
    status = status, poll = poll, close = close_receiver, is_closed = function() state$closed,
    diagnostics = function() list(sessions = state$refs, observers = as.integer(!is.null(state$driver)),
      polls = state$polls, processed = state$processed, coalesced = state$coalesced,
      duplicates = state$duplicates, out_of_order = state$out_of_order,
      poll_errors = state$poll_errors, history = length(state$history$history()))),
    class = "termr_shiny_receiver", termr_receiver = state)
}

shiny_stream_binding <- function(source, session, max_points = 600L) {
  shiny_stream_require()
  if (is.null(session) || !is.function(session$onSessionEnded) || is.null(session$userData)) {
    stop("A live Shiny session is required.", call. = FALSE)
  }
  if (is.function(session$isClosed) && session$isClosed()) stop("Shiny session is closed.", call. = FALSE)
  cache <- session$userData$termr_stream_bindings
  if (is.null(cache)) cache <- list()
  for (item in cache) if (identical(item$source, source)) {
    return(item)
  }
  implicit <- !inherits(source, "termr_shiny_receiver")
  receiver <- if (implicit) termr_shiny_receiver(source, max_points = max_points) else source
  release <- shiny_receiver_state(receiver)$acquire()
  session$onSessionEnded(function() {
    release()
    if (implicit) receiver$close()
    session$userData$termr_stream_bindings <- NULL
  })
  item <- list(source = source, receiver = receiver)
  session$userData$termr_stream_bindings <- c(cache, list(item))
  item
}

#' Reactive latest value, history and status from a termr stream
#'
#' Session-aware wrappers share one binding per source in a session. For
#' multiple sessions, explicitly create [termr_shiny_receiver()] outside the
#' server and pass it to all wrappers. A direct source creates an implicit
#' session-owned receiver, without taking ownership of the source itself.
#' Latest returns the unchanged last valid payload; history returns bounded
#' observation records; status exposes stale/invalid/reconnect/gap information.
#' Consumers must inspect status before presenting cached metrics as current.
#'
#' @param source A local/remote stream or explicit shared receiver.
#' @param session Current Shiny session.
#' @param max_points Maximum retained/requested history. Configure a larger
#'   shared receiver explicitly before requesting a larger history window.
#' @return A Shiny reactive expression of no arguments.
#' @name shiny_streams
#' @examples
#' if (interactive() && requireNamespace("shiny", quietly = TRUE)) {
#'   # In server(input, output, session):
#'   # value <- termr_shiny_reactive(shared, session)
#'   # history <- termr_shiny_history(shared, session)
#'   # status <- termr_shiny_status(shared, session)
#' }
NULL

#' @rdname shiny_streams
#' @export
termr_shiny_reactive <- function(source, session = shiny::getDefaultReactiveDomain(), max_points = 600L) {
  max_points <- stream_point_limit(max_points)
  binding <- shiny_stream_binding(source, session, max_points)
  state <- shiny_receiver_state(binding$receiver)
  shiny::reactive(state$value(), domain = session)
}

#' @rdname shiny_streams
#' @export
termr_shiny_history <- function(source, session = shiny::getDefaultReactiveDomain(), max_points = 600L) {
  max_points <- stream_point_limit(max_points)
  binding <- shiny_stream_binding(source, session, max_points)
  state <- shiny_receiver_state(binding$receiver)
  if (max_points > state$capacity) stop("Create a receiver with a larger `max_points` first.", call. = FALSE)
  shiny::reactive({ state$revision(); utils::tail(binding$receiver$history(), max_points) }, domain = session)
}

#' @rdname shiny_streams
#' @export
termr_shiny_status <- function(source, session = shiny::getDefaultReactiveDomain()) {
  binding <- shiny_stream_binding(source, session)
  state <- shiny_receiver_state(binding$receiver)
  shiny::reactive(state$status_value(), domain = session)
}
