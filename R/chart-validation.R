validate_numeric <- function(x, name, allow_empty = TRUE) {
  if (!is.numeric(x) || inherits(x, c("Date", "POSIXt")) || is.object(x) && !is.numeric(x)) {
    stop(sprintf("`%s` must be a plain numeric or integer vector.", name), call. = FALSE)
  }
  if (!allow_empty && !length(x)) stop(sprintf("`%s` must not be empty.", name), call. = FALSE)
  as.double(x)
}

# Category labels: a character vector, one per value, without NA.
check_labels <- function(labels, n, what = "") {
  if (!is.character(labels)) stop("`labels` must be a character vector.", call. = FALSE)
  if (length(labels) != n) {
    stop(sprintf("`labels` must have one label per value%s: %d given, %d needed.", what, length(labels), n), call. = FALSE)
  }
  if (anyNA(labels)) stop("`labels` must not contain NA.", call. = FALSE)
  invisible(labels)
}

chart_check_choice <- function(x, choices, name) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !x %in% choices) {
    stop(sprintf("`%s` must be one of %s.", name, paste0("\"", choices, "\"", collapse = ", ")), call. = FALSE)
  }
  x
}

validate_optional_text <- function(x, name) {
  if (is.null(x)) return(NULL)
  if (!is.character(x) || length(x) != 1L || is.na(x)) {
    stop(sprintf("`%s` must be NULL or one non-missing string.", name), call. = FALSE)
  }
  x
}

validate_common <- function(title, x_label, y_label, mode, id, classes, style, interactive) {
  validate_optional_text(title, "title")
  validate_optional_text(x_label, "x_label")
  validate_optional_text(y_label, "y_label")
  if (!is.character(mode) || length(mode) != 1L || is.na(mode) ||
      !mode %in% mode_choices) {
    stop("`mode` must be one of \"auto\", \"block\", \"braille\", or \"ascii\".", call. = FALSE)
  }
  if (!is.null(id) && (!is.character(id) || length(id) != 1L || is.na(id))) {
    stop("`id` must be NULL or one string.", call. = FALSE)
  }
  if (!is.null(classes) && !is.character(classes)) stop("`classes` must be NULL or character.", call. = FALSE)
  if (!is.null(style) && !inherits(style, "termr_style")) stop("`style` must be NULL or a termr style.", call. = FALSE)
  check_flag(interactive, "interactive")
}

normalize_xy <- function(x, y, size = NULL, x_scale = "linear", y_scale = "linear", point_labels = NULL) {
  xa <- axis_input(x, "x", x_scale, allow_time = TRUE)
  ya <- axis_input(y, "y", y_scale, allow_time = FALSE)
  x <- xa$num; y <- ya$num
  if (length(x) != length(y)) stop("`x` and `y` must have equal lengths.", call. = FALSE)
  valid <- is.finite(x) & is.finite(y)
  if (!is.null(size)) {
    size <- validate_numeric(size, "size")
    if (length(size) != length(x)) stop("`size` must have the same length as `x` and `y`.", call. = FALSE)
    if (any(size < 0, na.rm = TRUE)) stop("`size` must not contain negative values.", call. = FALSE)
    valid <- valid & is.finite(size)
  }
  source <- which(valid)
  out <- list(x = x[valid], y = y[valid], source = source,
              run = cumsum(c(1L, as.integer(diff(source) != 1L))),
              gaps = !valid,
              n_input = length(x),
              xscale = xa$scale, yscale = ya$scale)
  # A Date or POSIXct x keeps its class and time zone for events.
  if (!is.null(xa$orig)) out$x_orig <- xa$orig[valid]
  # Optional per-point text, kept only for the finite observations.
  labels <- validate_point_labels(point_labels, length(x))
  if (!is.null(labels)) out$point_labels <- labels[valid]
  if (!is.null(size)) out$size <- size[valid]
  out
}

histogram_data <- function(x, breaks) {
  x <- validate_numeric(x, "x")
  x <- x[is.finite(x)]
  if (!length(x)) return(list(labels = character(), values = numeric(),
                              breaks = numeric(), n_input = 0L))
  h <- tryCatch(graphics::hist(x, breaks = breaks, plot = FALSE, include.lowest = TRUE),
                error = function(e) stop("Invalid histogram `breaks`: ", conditionMessage(e), call. = FALSE))
  labels <- vapply(seq_along(h$counts), function(i) {
    paste0(format(h$breaks[[i]], trim = TRUE, scientific = FALSE,
                  decimal.mark = ".", big.mark = ""), "-",
           format(h$breaks[[i + 1L]], trim = TRUE, scientific = FALSE,
                  decimal.mark = ".", big.mark = ""))
  }, character(1))
  list(labels = labels, values = h$counts, breaks = h$breaks,
       n_input = length(x))
}

normalize_bar_data <- function(labels, values, position, position_supplied) {
  position <- chart_check_choice(position, c("single", "grouped", "stacked"), "position")
  if (is.data.frame(values)) stop("`values` must be a numeric vector or a numeric matrix.", call. = FALSE)
  if (is.matrix(values)) {
    if (!is.numeric(values)) stop("`values` must be a numeric vector or a numeric matrix.", call. = FALSE)
    if (!ncol(values)) stop("`values` must have at least one column.", call. = FALSE)
    check_labels(labels, nrow(values), " (one per row of `values`)")
    if (!position_supplied) position <- "grouped"
    if (identical(position, "single")) {
      if (ncol(values) != 1L) {
        stop("`position = \"single\"` needs one series; use \"grouped\" or \"stacked\" for a matrix with several columns.",
             call. = FALSE)
      }
      values <- as.double(values[, 1L])
    }
  } else if (!identical(position, "single")) {
    stop("`position` must be \"single\" for a numeric vector; give a matrix (rows = categories, columns = series) for grouped or stacked bars.",
         call. = FALSE)
  }
  if (is.matrix(values)) {
    series <- colnames(values)
    if (is.null(series)) series <- rep(NA_character_, ncol(values))
    blank <- is.na(series) | !nzchar(series)
    series[blank] <- paste("series", seq_len(ncol(values)))[blank]
    mat <- matrix(as.double(values), nrow(values), ncol(values))
    data <- list(labels = clean_text(labels), matrix = mat, series = clean_text(series), multi = TRUE)
  } else {
    values <- validate_numeric(values, "values")
    check_labels(labels, length(values))
    data <- list(labels = labels, values = values)
  }
  list(data = data, position = position)
}

replace_chart_data <- function(spec, args) {
  names_args <- names(args)
  if (length(args) && (is.null(names_args) || anyNA(names_args) || any(!nzchar(names_args)) || anyDuplicated(names_args))) {
    stop("Chart update arguments must be uniquely named.", call. = FALSE)
  }
  type <- spec$type
  allowed <- switch(type,
    line = , scatter = c("x", "y", "x_scale", "y_scale", "point_labels"),
    bar = c("labels", "values", "orientation", "position"),
    histogram = c("x", "breaks"),
    heatmap = "z")
  required <- switch(type,
    line = , scatter = c("x", "y"),
    bar = c("labels", "values"),
    histogram = "x",
    heatmap = "z")
  missing <- setdiff(required, names_args)
  if (length(missing)) {
    stop("`update_data()` requires: ", paste(missing, collapse = " and "), ".", call. = FALSE)
  }
  unexpected <- setdiff(names_args, allowed)
  if (length(unexpected)) {
    stop("Unsupported chart update argument(s): ", paste(unexpected, collapse = ", "), ".", call. = FALSE)
  }

  if (type %in% c("line", "scatter")) {
    old <- spec$data
    x_scale <- if ("x_scale" %in% names_args) args$x_scale else
      if (identical(old$xscale$type, "log10")) "log10" else "linear"
    y_scale <- if ("y_scale" %in% names_args) args$y_scale else
      if (identical(old$yscale$type, "log10")) "log10" else "linear"
    spec$data <- normalize_xy(args$x, args$y, x_scale = x_scale, y_scale = y_scale,
                              point_labels = args$point_labels)
  } else if (identical(type, "bar")) {
    position <- if ("position" %in% names_args) args$position else spec$position
    orientation <- if ("orientation" %in% names_args) args$orientation else spec$orientation
    spec$orientation <- chart_check_choice(orientation, c("vertical", "horizontal"), "orientation")
    normalized <- normalize_bar_data(args$labels, args$values, position, position_supplied = TRUE)
    spec$position <- normalized$position
    spec$data <- normalized$data
  } else if (identical(type, "histogram")) {
    breaks <- if ("breaks" %in% names_args) args$breaks else spec$breaks
    spec$data <- histogram_data(args$x, breaks)
    spec$breaks <- breaks
  } else {
    spec$data <- normalize_matrix(args$z)
  }
  spec
}
