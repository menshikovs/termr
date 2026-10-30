stream_point_limit <- function(x, name = "max_points", zero = FALSE) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || !is.finite(x) ||
      x < (if (zero) 0 else 1) || x > 1000000 || x != floor(x)) {
    stop("`", name, "` must be an integer between ", if (zero) 0 else 1,
         " and 1000000.", call. = FALSE)
  }
  as.integer(x)
}

stream_scalar_number <- function(x) {
  if (is.numeric(x) && length(x) == 1L && !is.na(x) && is.finite(x)) as.numeric(x) else NA_real_
}

stream_time <- function(x) {
  if (inherits(x, "POSIXt")) x <- as.numeric(x)
  stream_scalar_number(x)
}

stream_scalar_text <- function(x) {
  if (is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x)) x else NA_character_
}

#' Convert stream observations to an ordinary data frame
#'
#' Select numeric fields explicitly; missing, nonnumeric and nonfinite values
#' become `NA_real_`, never zero. Timestamps accept POSIXt or finite Unix
#' seconds and return POSIXct in UTC. Strings require explicit parsing in an
#' extractor. Observation order is retained, without sorting or invented rows.
#'
#' Additional columns are `source_id` (character), `sequence` (double), `gap`
#' (logical), `segment` (integer), and `received_at` (POSIXct). Unknown metadata
#' is missing. A new segment begins at a source change, a known sequence gap
#' or rollback, a backwards/invalid timestamp, or a missing selected metric.
#' Grouping plotted lines by segment displays discontinuities honestly.
#'
#' A shared Shiny receiver supplies observation records with transport metadata.
#' A raw stream/remote supplies payload history, whose source/sequence metadata
#' is used only when present in the payload. No replay or lost-point recovery
#' is performed. An extractor receives each payload and returns a flat named
#' list containing timestamp and the selected numeric fields. It is never
#' evaluated as code received from a transport.
#'
#' @param source A local/remote stream, `termr_shiny_receiver()`, or a list of
#'   observations/receiver history records. Pass a Shiny history as `history()`.
#' @param fields Unique numeric field names, excluding reserved metadata names.
#' @param max_points Maximum rows to return, from 0 to 1000000.
#' @param extractor Optional function mapping one payload to a flat named list.
#' @return A data.frame with stable column types, including when empty.
#' @export
#' @examples
#' events <- termr_stream("metrics")
#' events$emit(list(timestamp = Sys.time(), cpu = 42, ram = NA_real_))
#' termr_stream_data(events, c("cpu", "ram"))
#' events$close()
termr_stream_data <- function(source, fields = c("cpu", "ram"), max_points = 600L,
                              extractor = NULL) {
  max_points <- stream_point_limit(max_points, zero = TRUE)
  reserved <- c("timestamp", "source_id", "sequence", "gap", "segment", "received_at")
  if (!is.character(fields) || !length(fields) || anyNA(fields) ||
      any(!nzchar(fields)) || anyDuplicated(fields) || any(fields %in% reserved)) {
    stop("`fields` must be unique nonempty names excluding metadata columns.", call. = FALSE)
  }
  check_function(extractor, "extractor", allow_null = TRUE)
  observations <- if (is.list(source) && is.function(source$history)) source$history() else source
  if (!is.list(observations)) stop("`source` must supply a list history.", call. = FALSE)
  observations <- utils::tail(observations, max_points)
  n <- length(observations)
  timestamp <- received <- rep(NA_real_, n)
  ids <- rep(NA_character_, n)
  sequences <- rep(NA_real_, n)
  gaps <- rep(FALSE, n)
  values <- lapply(fields, function(field) rep(NA_real_, n))
  names(values) <- fields
  for (i in seq_len(n)) {
    record <- observations[[i]]
    structured <- inherits(record, "termr_history_record")
    payload <- if (structured) record$payload else record
    flat <- if (is.null(extractor)) {if (is.null(payload)) list() else payload} else extractor(payload)
    if (!is.list(flat) || (length(flat) && (is.null(names(flat)) || anyDuplicated(names(flat))))) {
      stop("Each observation/extractor result must be a named list.", call. = FALSE)
    }
    timestamp[[i]] <- stream_time(flat$timestamp)
    ids[[i]] <- stream_scalar_text(if (structured) record$source_id else flat$source_id)
    sequences[[i]] <- stream_scalar_number(if (structured) record$sequence else flat$sequence)
    if (structured) {
      received[[i]] <- stream_time(record$received_at)
      gaps[[i]] <- isTRUE(record$gap)
      if (is.null(flat$timestamp)) timestamp[[i]] <- stream_time(record$timestamp)
    }
    for (field in fields) values[[field]][[i]] <- stream_scalar_number(flat[[field]])
    if (i > 1L) {
      same <- !is.na(ids[[i]]) && !is.na(ids[[i - 1L]]) && ids[[i]] == ids[[i - 1L]]
      if (same && !is.na(sequences[[i]]) && !is.na(sequences[[i - 1L]])) {
        gaps[[i]] <- gaps[[i]] || sequences[[i]] != sequences[[i - 1L]] + 1
      }
    }
  }
  segment <- integer(n)
  for (i in seq_len(n)) {
    missing <- is.na(timestamp[[i]]) || any(vapply(values, function(x) is.na(x[[i]]), logical(1)))
    boundary <- i == 1L || gaps[[i]] || missing
    if (i > 1L) {
      previous_missing <- is.na(timestamp[[i - 1L]]) || any(vapply(values, function(x) is.na(x[[i - 1L]]), logical(1)))
      source_changed <- !is.na(ids[[i]]) && !is.na(ids[[i - 1L]]) && ids[[i]] != ids[[i - 1L]]
      backwards <- !is.na(timestamp[[i]]) && !is.na(timestamp[[i - 1L]]) && timestamp[[i]] < timestamp[[i - 1L]]
      boundary <- boundary || previous_missing || source_changed || backwards
    }
    segment[[i]] <- if (i == 1L) 1L else segment[[i - 1L]] + as.integer(boundary)
  }
  time <- function(x) as.POSIXct(x, origin = "1970-01-01", tz = "UTC")
  result <- c(list(timestamp = time(timestamp)), values,
    list(source_id = ids, sequence = sequences, gap = gaps, segment = segment, received_at = time(received)))
  as.data.frame(result, stringsAsFactors = FALSE, optional = TRUE)
}
