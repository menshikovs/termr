# Optional, main-thread-polled telemetry adapter. No native R callbacks.
nano_require <- function() {
  for (package in c("nanonext", "jsonlite")) {
    if (!requireNamespace(package, quietly = TRUE)) {
      stop("Install optional package '", package, "' to use nanonext transport.", call. = FALSE)
    }
  }
  if (utils::packageVersion("nanonext") < "1.10.0") {
    stop("nanonext >= 1.10.0 is required.", call. = FALSE)
  }
}

nano_number <- function(x, lower = 0, upper = Inf, integer = FALSE) {
  is.numeric(x) && length(x) == 1L && !is.na(x) && is.finite(x) &&
    x >= lower && x <= upper && (!integer || x == floor(x))
}

nano_id <- function(x) {
  is.character(x) && length(x) == 1L && !is.na(x) &&
    nchar(x, type = "bytes") <= 128L && grepl("^[A-Za-z0-9_.-]+$", x)
}

nano_endpoints <- function(endpoint, snapshot_endpoint, listen = FALSE) {
  valid <- function(x) {
    is.character(x) && length(x) == 1L && !is.na(x) &&
      grepl("^tcp://127[.]0[.]0[.]1:[0-9]{1,5}$", x) &&
      nano_number(as.numeric(sub(".*:", "", x)), if (listen) 0 else 1, 65535, TRUE)
  }
  if (!valid(endpoint)) stop("`endpoint` must be loopback tcp://127.0.0.1:PORT.", call. = FALSE)
  port <- as.numeric(sub(".*:", "", endpoint))
  if (is.null(snapshot_endpoint)) snapshot_endpoint <- paste0("tcp://127.0.0.1:", if (port == 0) 0 else port + 1)
  if (!valid(snapshot_endpoint) || (endpoint == snapshot_endpoint && port != 0)) {
    stop("Provide a distinct loopback `snapshot_endpoint` (default: next port).", call. = FALSE)
  }
  list(endpoint = endpoint, snapshot_endpoint = snapshot_endpoint)
}

nano_limits <- function(max_bytes, buffer, timeout) {
  if (!nano_number(max_bytes, 256, 16 * 1024^2, TRUE) ||
      !nano_number(buffer, 1, 8192, TRUE) || !nano_number(timeout, 10, 60000, TRUE)) {
    stop("Invalid message size, buffer or request timeout limit.", call. = FALSE)
  }
}

nano_socket <- function(protocol, max_bytes, buffer) {
  socket <- nanonext::socket(protocol)
  success <- FALSE
  on.exit(if (!success) close(socket), add = TRUE)
  nanonext::opt(socket, "recv-size-max") <- as.integer(max_bytes)
  nanonext::opt(socket, "recv-buffer") <- as.integer(buffer)
  nanonext::opt(socket, "send-timeout") <- 0L
  nanonext::opt(socket, "reconnect-time-min") <- 50L
  nanonext::opt(socket, "reconnect-time-max") <- 1000L
  success <- TRUE
  socket
}

nano_listen <- function(socket, endpoint) {
  nanonext::listen(socket, endpoint, fail = "error")
  paste0("tcp://127.0.0.1:", nanonext::opt(socket$listener[[1L]], "tcp-bound-port"))
}

nano_payload <- function(x, depth = 0L) {
  if (depth > 32L) stop("JSON payload exceeds depth 32.", call. = FALSE)
  if (inherits(x, "POSIXt")) return(as.numeric(x))
  if (is.object(x) || !is.null(dim(x)) || is.raw(x) || !(is.null(x) || is.list(x) || is.numeric(x) || is.character(x) || is.logical(x))) {
    stop("Payload must contain JSON values; convert classed/reference objects explicitly.", call. = FALSE)
  }
  if (is.list(x)) {
    if (!is.null(names(x)) && (anyNA(names(x)) || any(!nzchar(names(x))) || anyDuplicated(names(x)))) {
      stop("JSON object names must be unique and nonempty.", call. = FALSE)
    }
    return(lapply(x, nano_payload, depth = depth + 1L))
  }
  if (is.numeric(x) && any(!is.finite(x) & !is.na(x))) stop("Infinite JSON numbers are not supported.", call. = FALSE)
  x
}

nano_encode <- function(message, max_bytes) {
  wire <- charToRaw(enc2utf8(jsonlite::toJSON(message, auto_unbox = TRUE,
    null = "null", na = "null", digits = NA, force = TRUE)))
  if (length(wire) > max_bytes) stop("Encoded message exceeds `max_bytes`.", call. = FALSE)
  wire
}

nano_decode <- function(wire, max_bytes, types = c("snapshot", "event", "heartbeat", "status")) {
  if (!is.raw(wire) || length(wire) > max_bytes || !length(wire) || any(wire == as.raw(0))) {
    stop("Invalid message bytes or size.", call. = FALSE)
  }
  # Bound JSON nesting before parsing, including hostile deeply nested JSON.
  tokens <- which(wire %in% as.raw(c(34, 92, 91, 93, 123, 125)))
  quoted <- FALSE; escape <- 0L; depth <- 0L
  for (position in tokens) {
    if (position == escape) next
    code <- as.integer(wire[[position]])
    if (quoted && code == 92L) { escape <- position + 1L; next }
    if (code == 34L) quoted <- !quoted
    if (!quoted) {
      if (code %in% c(91L, 123L)) depth <- depth + 1L
      if (code %in% c(93L, 125L)) depth <- depth - 1L
      if (depth > 36L || depth < 0L) stop("Invalid JSON nesting.", call. = FALSE)
    }
  }
  value <- jsonlite::fromJSON(rawToChar(wire), simplifyVector = FALSE)
  fields <- c("schema_version", "source_id", "stream_id", "sequence", "timestamp", "message_type", "payload")
  if (!is.list(value) || !all(fields %in% names(value)) || anyDuplicated(names(value)) ||
      !identical(value$schema_version, 1L) || !nano_id(value$source_id) || !nano_id(value$stream_id) ||
      !nano_number(value$sequence, 0, 2^53 - 1, TRUE) || !nano_number(value$timestamp) ||
      !is.character(value$message_type) || length(value$message_type) != 1L ||
      !value$message_type %in% types ||
      (value$message_type %in% c("event", "snapshot") && value$sequence < 1)) {
    stop("Unsupported or malformed telemetry envelope.", call. = FALSE)
  }
  value
}

nano_message <- function(source, stream, sequence, type, payload = NULL) {
  list(schema_version = 1L, source_id = source, stream_id = stream,
       sequence = sequence, timestamp = as.numeric(Sys.time()), message_type = type,
       payload = payload)
}

nano_cancel <- function(operation) {
  if (!is.null(operation)) try(nanonext::stop_aio(operation), silent = TRUE)
  invisible(NULL)
}

#' Publish and receive local telemetry using optional nanonext
#'
#' Experimental loopback-only JSON transport for a [termr_stream()]. A live
#' pub/sub socket and a separate request/reply socket implement latest-value
#' recovery, not a durable queue. Both owners must call `$poll()` regularly
#' on the ordinary R thread, for example from an App timer or Shiny timer.
#' Nothing schedules itself, blocks waiting for network data, or runs user R
#' callbacks on native threads. `latest()` reads cached data; it does not poll.
#'
#' The publisher subscribes to the supplied local stream and retains its last
#' successfully encoded event for snapshot replies. If the local stream already
#' has history, its last retained event seeds the publisher. The publisher
#' handle exposes `$endpoint`, `$snapshot_endpoint`, `$source_id`, `$poll()`,
#' `$status()`, `$is_closed()` and idempotent `$close()`. Closing detaches only
#' its own subscription, cancels pending operations and closes its sockets;
#' it never closes the supplied stream. `$poll()` services at most 32 snapshot
#' requests and sends due heartbeats. A publisher should be explicitly closed
#' before its supplied stream closes.
#'
#' The remote handle exposes `$poll(max_messages = 64L)`, `$latest()`,
#' `$history()`, `$subscribe(callback)`, `$subscriber_count()`, `$status()`,
#' `$is_closed()` and `$close()`. Payload callbacks run only during poll.
#' Callbacks follow local stream semantics, including error warnings and the
#' rejection of reentrant emission. Remote close disconnects all callbacks.
#' Status reports source/sequence, cumulative gaps, invalid messages, resyncs,
#' pending operation count, connection freshness and the last error.
#'
#' Subscribe precedes snapshot request. A snapshot establishes source identity;
#' older/duplicate live messages are discarded. Sequence gaps are counted and
#' trigger resynchronization. Periodic snapshots also recover the last dropped
#' event even when no later event arrives. A new source resets local history;
#' callbacks receive its current snapshot once. NNG reconnect uses exponential
#' backoff from 50 to 1000 ms; snapshot retries have a bounded backoff too.
#' Heartbeats signal transport freshness, not freshness of an application
#' measurement. No complete history replay or guaranteed event delivery.
#'
#' Wire data is UTF-8 JSON schema version 1, with an exact newline-terminated
#' topic prefix on pub/sub. No R serialization is accepted. Payloads support
#' JSON trees; POSIXt values become Unix seconds, NA becomes null, scalar
#' vectors unbox, arrays decode as lists, and classed objects must be converted
#' explicitly. Treat published reference data as immutable. See
#' `docs/nanonext.md` in the source repository for the protocol and examples.
#'
#' Only numeric 127.0.0.1 TCP endpoints are accepted; no wildcard bind, remote
#' control, authentication or encryption. Loopback does not authenticate local
#' peers. A byte limit is enforced in NNG before receipt and again before JSON
#' parsing, with bounded nesting and native receive queues. This adapter needs
#' optional nanonext >= 1.10.0 and jsonlite; ordinary streams do not.
#'
#' @param stream Publisher: a named `termr_stream()`; connector: stream name.
#' @param endpoint Loopback TCP pub/sub endpoint. Publishers may use port 0
#'   to bind an OS-assigned port, returned on the handle.
#' @param snapshot_endpoint Separate loopback snapshot endpoint. Defaults to
#'   the next port, or port 0 when the publisher endpoint uses port 0.
#' @param max_bytes Maximum wire bytes, including topic (256 to 16 MiB).
#' @param buffer Native receive queue depth, 1 to 8192 messages.
#' @param heartbeat Publisher heartbeat interval in seconds.
#' @param request_timeout Snapshot operation timeout in milliseconds.
#' @param resync_interval Periodic latest-state recovery interval in seconds.
#' @param stale_after Seconds without valid peer messages before stale status.
#' @param history Remote local history capacity.
#' @return A publisher or remote stream handle, as described above.
#' @name nanonext_transport
#' @examples
#' # Optional integration; poll both owners from their process event loops.
#' if (interactive() && requireNamespace("nanonext", quietly = TRUE) &&
#'     requireNamespace("jsonlite", quietly = TRUE)) {
#'   events <- termr_stream("metrics")
#'   pub <- termr_nano_publish(events, "tcp://127.0.0.1:0")
#'   remote <- termr_nano_connect(pub$endpoint, "metrics", pub$snapshot_endpoint)
#'   events$emit(list(cpu = 42))
#'   pub$poll()
#'   remote$poll()
#'   remote$close()
#'   pub$close()
#'   events$close()
#' }
NULL

#' @rdname nanonext_transport
#' @export
termr_nano_publish <- function(stream, endpoint = "tcp://127.0.0.1:5555",
                               snapshot_endpoint = NULL, max_bytes = 1048576L,
                               buffer = 64L, heartbeat = 1, request_timeout = 500L) {
  nano_require()
  if (!inherits(stream, "termr_stream") || !nano_id(stream$name) || stream$is_closed()) {
    stop("`stream` must be an open, named termr_stream().", call. = FALSE)
  }
  addresses <- nano_endpoints(endpoint, snapshot_endpoint, TRUE)
  nano_limits(max_bytes, buffer, request_timeout)
  if (!nano_number(heartbeat, 0.01, 3600)) stop("Invalid heartbeat interval.", call. = FALSE)
  pub <- nano_socket("pub", max_bytes, buffer)
  rep <- NULL; incoming <- NULL; outgoing <- NULL; subscription <- NULL
  closed <- FALSE; ready <- FALSE; busy <- FALSE
  close_transport <- function() {
    if (closed) return(invisible(NULL))
    closed <<- TRUE
    if (!is.null(subscription)) subscription$unsubscribe()
    nano_cancel(incoming); nano_cancel(outgoing)
    close(pub)
    if (!is.null(rep)) close(rep)
    pub <<- NULL; rep <<- NULL
    incoming <<- NULL; outgoing <<- NULL
    invisible(NULL)
  }
  on.exit(if (!ready) close_transport(), add = TRUE)
  endpoint <- nano_listen(pub, addresses$endpoint)
  rep <- nano_socket("rep", max_bytes, buffer)
  snapshot_endpoint <- nano_listen(rep, addresses$snapshot_endpoint)
  source <- paste0("p", Sys.getpid(), "-", sprintf("%.0f", as.numeric(Sys.time()) * 1e6), "-", basename(tempfile()))
  sequence <- 0; snapshots <- 0L; sent <- 0; errors <- 0L; last_error <- NULL
  snapshot <- NULL
  topic <- charToRaw(paste0("termr/", stream$name, "\n"))
  last_heartbeat <- -Inf
  publish <- function(value) {
    if (closed) return(invisible(NULL))
    if (sequence >= 2^53 - 1) stop("Sequence exhausted; restart publisher.", call. = FALSE)
    value <- nano_payload(value)
    message <- nano_message(source, stream$name, sequence + 1, "event", value)
    packet <- c(topic, nano_encode(message, max_bytes - length(topic)))
    message$message_type <- "snapshot"
    next_snapshot <- nano_encode(message, max_bytes)
    sequence <<- sequence + 1
    snapshot <<- next_snapshot
    result <- nanonext::send(pub, packet, mode = "raw", block = FALSE)
    if (nanonext::is_error_value(result)) {
      errors <<- errors + 1L; last_error <<- paste("Send failed:", as.integer(result))
    } else sent <<- sent + 1
    invisible(NULL)
  }
  poll <- function() {
    if (closed || busy) return(invisible(0L))
    busy <<- TRUE
    on.exit(busy <<- FALSE, add = TRUE)
    now <- now_seconds()
    if (now - last_heartbeat >= heartbeat) {
      nanonext::send(pub, c(topic, nano_encode(nano_message(source, stream$name, sequence, "heartbeat"),
        max_bytes - length(topic))), mode = "raw", block = FALSE)
      last_heartbeat <<- now
    }
    count <- 0L
    for (i in seq_len(32L)) {
      if (!is.null(outgoing)) {
        if (nanonext::unresolved(outgoing)) break
        result <- outgoing$result
        nano_cancel(outgoing)
        if (nanonext::is_error_value(result)) { errors <<- errors + 1L; last_error <<- "Snapshot send failed." }
        outgoing <<- NULL
      }
      if (is.null(incoming)) incoming <<- nanonext::recv_aio(rep, mode = "raw", timeout = request_timeout)
      if (nanonext::unresolved(incoming)) break
      wire <- incoming$data
      nano_cancel(incoming)
      incoming <<- NULL
      if (nanonext::is_error_value(wire)) next
      request <- tryCatch(nano_decode(wire, max_bytes, "snapshot_request"), error = function(e) NULL)
      valid <- !is.null(request) && identical(request$stream_id, stream$name)
      response <- if (valid && !is.null(snapshot)) snapshot else nano_encode(
        nano_message(source, if (is.null(request)) stream$name else request$stream_id,
          0, "status", list(status = if (valid) "empty" else "unknown_stream")), max_bytes)
      outgoing <<- nanonext::send_aio(rep, response, mode = "raw", timeout = request_timeout)
      snapshots <<- snapshots + 1L
      count <- count + 1L
    }
    invisible(count)
  }
  subscription <- stream$subscribe(publish)
  initial <- stream$latest()
  if (!is.null(initial) || length(stream$history())) publish(initial)
  incoming <- nanonext::recv_aio(rep, mode = "raw", timeout = request_timeout)
  ready <- TRUE
  list(endpoint = endpoint, snapshot_endpoint = snapshot_endpoint, source_id = source,
    poll = poll, close = close_transport, is_closed = function() closed,
    status = function() list(closed = closed, sequence = sequence, sent = sent,
      snapshots = snapshots, errors = errors, last_error = last_error,
      pending = as.integer(!is.null(incoming)) + as.integer(!is.null(outgoing))))
}

#' @rdname nanonext_transport
#' @export
termr_nano_connect <- function(endpoint, stream, snapshot_endpoint = NULL,
                               history = 1000L, max_bytes = 1048576L, buffer = 64L,
                               request_timeout = 500L, resync_interval = 2, stale_after = 5) {
  nano_require()
  if (!nano_id(stream)) stop("`stream` must be a topic name containing letters, digits, _, . or -.", call. = FALSE)
  addresses <- nano_endpoints(endpoint, snapshot_endpoint)
  nano_limits(max_bytes, buffer, request_timeout)
  if (!nano_number(resync_interval, 0.01, 3600) || !nano_number(stale_after, 0.01, 3600)) {
    stop("Invalid resync or stale interval.", call. = FALSE)
  }
  local <- termr_stream(stream, history = history)
  sub <- nano_socket("sub", max_bytes, buffer)
  req <- NULL; live <- NULL; request_send <- NULL; response <- NULL
  closed <- FALSE; ready <- FALSE; busy <- FALSE
  topic <- charToRaw(paste0("termr/", stream, "\n"))
  close_transport <- function() {
    if (closed) return(invisible(NULL))
    closed <<- TRUE
    nano_cancel(live); nano_cancel(request_send); nano_cancel(response)
    try(nanonext::unsubscribe(sub, topic), silent = TRUE)
    close(sub)
    if (!is.null(req)) close(req)
    sub <<- NULL; req <<- NULL
    live <<- NULL; request_send <<- NULL; response <<- NULL
    local$close()
    invisible(NULL)
  }
  on.exit(if (!ready) close_transport(), add = TRUE)
  nanonext::subscribe(sub, topic)
  nanonext::dial(sub, addresses$endpoint, fail = "error")
  req <- nano_socket("req", max_bytes, buffer)
  nanonext::dial(req, addresses$snapshot_endpoint, fail = "error")
  source <- NULL; sequence <- 0; gaps <- 0; invalid <- 0L; resyncs <- 0L
  last_seen <- -Inf; last_sync <- -Inf; retry_at <- -Inf; backoff <- 0.05
  needs_sync <- TRUE; last_error <- NULL
  accept <- function(wire, snapshot = FALSE) {
    message <- tryCatch(nano_decode(wire, max_bytes), error = function(e) {
      last_error <<- conditionMessage(e); NULL
    })
    if (is.null(message) || !identical(message$stream_id, stream) ||
        message$timestamp > as.numeric(Sys.time()) + 5) {
      invalid <<- invalid + 1L
      return(invisible(NULL))
    }
    if (snapshot) {
      if (!message$message_type %in% c("snapshot", "status")) { invalid <<- invalid + 1L; return(invisible(NULL)) }
      if (message$message_type == "status" &&
          (!is.list(message$payload) || !identical(message$payload$status, "empty"))) {
        last_error <<- "Publisher does not serve this stream."; return(invisible(NULL))
      }
      if (!identical(source, message$source_id)) {
        local$clear(); source <<- message$source_id; sequence <<- 0
      }
      needs_sync <<- FALSE; last_sync <<- now_seconds(); resyncs <<- resyncs + 1L
      last_error <<- NULL
      backoff <<- 0.05
    } else if (is.null(source) || !identical(source, message$source_id)) {
      needs_sync <<- TRUE
      return(invisible(NULL))
    }
    last_seen <<- now_seconds()
    if (message$message_type == "heartbeat") {
      if (message$sequence > sequence) needs_sync <<- TRUE
      return(invisible(NULL))
    }
    if (message$message_type == "status" || message$sequence <= sequence) return(invisible(NULL))
    if (sequence > 0 && message$sequence > sequence + 1) {
      gaps <<- gaps + message$sequence - sequence - 1
      needs_sync <<- TRUE
    }
    sequence <<- message$sequence
    local$emit(message$payload)
    invisible(NULL)
  }
  poll <- function(max_messages = 64L) {
    if (!nano_number(max_messages, 1, 8192, TRUE)) stop("Invalid poll message budget.", call. = FALSE)
    if (closed || busy) return(invisible(0L))
    busy <<- TRUE
    on.exit(busy <<- FALSE, add = TRUE)
    count <- 0L
    if (!is.null(request_send) && !nanonext::unresolved(request_send)) {
      result <- request_send$result
      nano_cancel(request_send)
      request_send <<- NULL
      if (!nanonext::is_error_value(result)) response <<- nanonext::recv_aio(req, mode = "raw", timeout = request_timeout)
      else { retry_at <<- now_seconds() + backoff; backoff <<- min(1, backoff * 2) }
    }
    if (!is.null(response) && !nanonext::unresolved(response)) {
      wire <- response$data
      nano_cancel(response)
      response <<- NULL
      retry_at <<- now_seconds() + backoff
      if (!nanonext::is_error_value(wire)) accept(wire, TRUE)
      else { backoff <<- min(1, backoff * 2); last_error <<- "Snapshot timeout; retrying." }
    }
    if (!closed && is.null(live)) live <<- nanonext::recv_aio(sub, mode = "raw", timeout = 1000L)
    if (!closed && !nanonext::unresolved(live)) {
      wire <- live$data
      nano_cancel(live)
      live <<- NULL
      # After the one pending AIO completes, drain already queued packets
      # directly with nonblocking recv. Rearming a fresh AIO for every packet
      # usually yields after only one event and starves a busy Shiny loop.
      for (i in seq_len(max_messages)) {
        if (closed) break
        if (i > 1L) wire <- nanonext::recv(sub, mode = "raw", block = FALSE)
        if (nanonext::is_error_value(wire)) break
        if (length(wire) > length(topic) && identical(wire[seq_along(topic)], topic)) {
          accept(wire[-seq_along(topic)])
        } else invalid <<- invalid + 1L
        count <- count + 1L
      }
    }
    if (!closed && is.null(live)) live <<- nanonext::recv_aio(sub, mode = "raw", timeout = 1000L)
    if (!closed && is.null(request_send) && is.null(response) && now_seconds() >= retry_at &&
        (needs_sync || now_seconds() - last_sync >= resync_interval)) {
      wire <- nano_encode(nano_message("subscriber", stream, 0, "snapshot_request"), max_bytes)
      request_send <<- nanonext::send_aio(req, wire, mode = "raw", timeout = request_timeout)
    }
    invisible(count)
  }
  live <- nanonext::recv_aio(sub, mode = "raw", timeout = 1000L)
  ready <- TRUE
  list(poll = poll, latest = local$latest, history = local$history,
    subscribe = local$subscribe, subscriber_count = local$subscriber_count,
    close = close_transport, is_closed = function() closed,
    status = function() list(state = if (closed) "closed" else if (is.null(source)) "connecting" else
      if (now_seconds() - last_seen > stale_after) "stale" else "live",
      source_id = source, sequence = sequence, gaps = gaps, invalid = invalid,
      resyncs = resyncs, last_error = last_error, needs_sync = needs_sync,
      pending = as.integer(!is.null(live)) + as.integer(!is.null(request_send)) + as.integer(!is.null(response))))
}
