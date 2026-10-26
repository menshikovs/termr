# Axis scales (private). An axis has one of four types:
#
#   linear    numeric values, mapped as they are (the original behaviour)
#   log10     numeric values > 0, mapped through log10()
#   date      Date, mapped as days since 1970-01-01
#   datetime  POSIXct, mapped as seconds since the epoch, with its time zone
#
# Everything downstream works in the *transformed* coordinate: charts map
# transformed values to [0, 1] (see `unit_values()`), reduce and hit-test in
# that space, and ask the scale for ticks and labels. Source values are never
# replaced: events carry the original values (`data$x_orig` keeps a Date or
# POSIXct x with its class and time zone). There is no public scale object.

axis_scale <- function(type = "linear", tz = NULL) list(type = type, tz = tz)

scale_linear <- axis_scale("linear")

scale_is_linear <- function(scale) is.null(scale) || identical(scale$type, "linear")

# Original value -> transformed coordinate.
scale_forward <- function(scale, v) {
  if (!is.null(scale) && identical(scale$type, "log10")) log10(v) else as.double(v)
}

# Transformed coordinate -> original numeric value.
scale_inverse <- function(scale, t) {
  if (!is.null(scale) && identical(scale$type, "log10")) 10^t else as.double(t)
}

# Ticks inside the transformed domain [lo, hi]: list(value, label), `value` in
# the transformed coordinate. `max_n` bounds the count; `width` is the widest
# label a linear axis may use.
scale_ticks <- function(scale, lo, hi, max_n, width = 8L) {
  type <- if (is.null(scale)) "linear" else scale$type
  switch(type,
    log10 = log_ticks(lo, hi, max_n),
    date = date_ticks(lo, hi, max_n),
    datetime = datetime_ticks(lo, hi, max_n, scale$tz),
    {
      value <- tick_values(lo, hi, max_n)
      list(value = value, label = format_tick_labels(value, width))
    })
}

# Label for one selected/original value, in the scale's own format.
scale_format <- function(scale, v) {
  type <- if (is.null(scale)) "linear" else scale$type
  switch(type,
    log10 = log_labels(v),
    date = format_date_full(as.double(v)),
    datetime = format_datetime_full(as.double(v), scale$tz),
    format_tick_labels(v, 10L))
}

# Validate an `x_scale`/`y_scale` argument.
check_scale_arg <- function(x, name) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !x %in% c("linear", "log10")) {
    stop(sprintf("`%s` must be \"linear\" or \"log10\".", name), call. = FALSE)
  }
  x
}

# Read one axis of the input: numeric (linear or log10), Date or POSIXct.
# Returns list(num, orig, scale); `orig` is the input itself for Date and
# POSIXct (class and time zone preserved) and NULL for plain numbers.
axis_input <- function(v, name, scale_arg, allow_time) {
  scale_arg <- check_scale_arg(scale_arg, paste0(name, "_scale"))
  if (inherits(v, "POSIXlt")) v <- as.POSIXct(v)
  if (allow_time && inherits(v, "Date")) {
    if (!identical(scale_arg, "linear")) {
      stop(sprintf("`%s` is a Date, which has its own calendar axis; `%s_scale` must be \"linear\".",
                   name, name), call. = FALSE)
    }
    return(list(num = as.double(unclass(v)), orig = v, scale = axis_scale("date")))
  }
  if (allow_time && inherits(v, "POSIXct")) {
    if (!identical(scale_arg, "linear")) {
      stop(sprintf("`%s` is a POSIXct, which has its own time axis; `%s_scale` must be \"linear\".",
                   name, name), call. = FALSE)
    }
    tz <- attr(v, "tzone")
    return(list(num = as.double(unclass(v)), orig = v,
                scale = axis_scale("datetime", if (length(tz) && !is.na(tz[[1L]])) tz[[1L]] else "")))
  }
  if (allow_time && !is.numeric(v)) {
    stop(sprintf("`%s` must be a numeric vector, a Date or a POSIXct.", name), call. = FALSE)
  }
  num <- validate_numeric(v, name)
  if (identical(scale_arg, "log10")) {
    bad <- is.finite(num) & num <= 0
    if (any(bad)) {
      stop(sprintf("`%s` must be positive for `%s_scale = \"log10\"`; %d value%s %s not (the smallest is %s). Non-finite values are dropped as usual.",
                   name, name, sum(bad), if (sum(bad) == 1L) "" else "s",
                   if (sum(bad) == 1L) "is" else "are", format(min(num[bad]))), call. = FALSE)
    }
  }
  list(num = num, orig = NULL, scale = axis_scale(scale_arg))
}

# ---- log10 ticks -----------------------------------------------------------------

# Compact label for a positive value: plain decimals for 0.001 up to 10000,
# otherwise `<mantissa>e<exponent>` (1e6, 2e-7). No floating-point artifacts.
log_labels <- function(v) {
  vapply(v, function(x) {
    if (!is.finite(x) || x <= 0) return("NA")
    x <- signif(x, 12)
    e <- floor(log10(x) + 1e-12)
    if (e >= -3 && e <= 4) return(format(x, scientific = FALSE, digits = 12, trim = TRUE))
    m <- signif(x / 10^e, 6)
    paste0(format(m, scientific = FALSE, trim = TRUE), "e", e)
  }, "")
}

# Ticks at powers of ten inside the log10 domain [lo, hi]. A domain with fewer
# than two powers uses 1-2-5 steps, then 1-9, then round numbers; a domain of
# many decades keeps every k-th power so at most `max_n` remain.
log_ticks <- function(lo, hi, max_n) {
  empty <- list(value = numeric(), label = character())
  if (!is.finite(lo) || !is.finite(hi) || max_n < 1L) return(empty)
  if (lo == hi) return(list(value = lo, label = log_labels(10^lo)))
  slack <- 1e-9
  inside <- function(t) t >= lo - slack & t <= hi + slack
  ex <- seq.int(floor(lo - slack), ceiling(hi + slack))
  powers <- ex[inside(ex)]
  if (length(powers) > max_n) {
    stride <- ceiling(length(powers) / max_n)
    powers <- powers[powers %% stride == 0L]
  }
  if (length(powers) >= 2L && length(powers) <= max_n) {
    return(list(value = as.double(powers), label = log_labels(10^powers)))
  }
  for (mult in list(c(1, 2, 5), 1:9)) {
    vals <- sort(as.vector(outer(mult, 10^ex)))
    vals <- signif(vals, 12)
    t <- log10(vals)
    keep <- inside(t)
    if (sum(keep) >= 2L && sum(keep) <= max_n) {
      return(list(value = t[keep], label = log_labels(vals[keep])))
    }
  }
  vals <- tick_values(10^lo, 10^hi, max_n)
  vals <- vals[vals > 0]
  if (length(vals) >= 1L) return(list(value = log10(vals), label = format_tick_labels(vals, 10L)))
  if (length(powers)) return(list(value = as.double(powers), label = log_labels(10^powers)))
  empty
}

# ---- Date ticks ------------------------------------------------------------------

# Month names are fixed English abbreviations: labels do not depend on the locale.
month_abb <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")

# Calendar fields of day numbers (days since 1970-01-01, UTC).
day_fields <- function(days) {
  lt <- as.POSIXlt(as.Date(days, origin = "1970-01-01"))
  list(year = lt$year + 1900L, mon = lt$mon, mday = lt$mday)
}

format_date_full <- function(days) {
  f <- day_fields(days)
  sprintf("%04d-%02d-%02d", f$year, f$mon + 1L, f$mday)
}

# Candidate tick steps, finest first.
date_steps <- list(
  list(unit = "day", n = 1L), list(unit = "day", n = 2L), list(unit = "day", n = 5L),
  list(unit = "week", n = 1L), list(unit = "week", n = 2L),
  list(unit = "month", n = 1L), list(unit = "month", n = 2L), list(unit = "month", n = 3L),
  list(unit = "month", n = 6L),
  list(unit = "year", n = 1L), list(unit = "year", n = 2L), list(unit = "year", n = 5L),
  list(unit = "year", n = 10L), list(unit = "year", n = 20L), list(unit = "year", n = 50L),
  list(unit = "year", n = 100L), list(unit = "year", n = 1000L))

# Day numbers of the ticks of one step inside [lo, hi] (day numbers).
# A step that would give more than `max_ticks` ticks returns max_ticks + 1 NAs
# instead of building the sequence.
date_step_ticks <- function(step, lo, hi, max_ticks = Inf) {
  n <- step$n
  switch(step$unit,
    day = {
      first <- ceiling(lo / n) * n
      if (first > hi) numeric() else if (floor((hi - first) / n) + 1 > max_ticks) rep(NA_real_, max_ticks + 1L)
      else seq(first, floor(hi / n) * n, by = n)
    },
    week = {
      # Weeks start on Monday (1970-01-05 is day 4 of the epoch week).
      period <- 7L * n
      first <- ceiling((lo - 4) / period) * period + 4
      if (first > hi) numeric() else if (floor((hi - first) / period) + 1 > max_ticks) rep(NA_real_, max_ticks + 1L)
      else seq(first, hi, by = period)
    },
    month = {
      f <- day_fields(c(lo, hi))
      i0 <- f$year[[1L]] * 12L + f$mon[[1L]]
      i1 <- f$year[[2L]] * 12L + f$mon[[2L]]
      start <- ceiling(i0 / n) * n
      if (start > i1) return(numeric())
      i <- seq.int(start, i1, by = n)
      days <- as.double(as.Date(sprintf("%04d-%02d-01", i %/% 12L, i %% 12L + 1L)))
      days[days >= lo & days <= hi]
    },
    year = {
      f <- day_fields(c(lo, hi))
      y <- seq.int(f$year[[1L]], f$year[[2L]])
      y <- y[y %% n == 0L]
      days <- as.double(as.Date(sprintf("%04d-01-01", y)))
      days[days >= lo & days <= hi]
    })
}

# Label day-number ticks for a step; `lo`/`hi` give the context (is the span
# within one calendar year?).
date_labels <- function(days, step, lo, hi) {
  f <- day_fields(days)
  one_year <- day_fields(lo)$year == day_fields(hi)$year
  switch(step$unit,
    year = as.character(f$year),
    month = if (one_year) month_abb[f$mon + 1L] else paste(month_abb[f$mon + 1L], f$year),
    if (one_year) sprintf("%s %02d", month_abb[f$mon + 1L], f$mday)
    else sprintf("%04d-%02d-%02d", f$year, f$mon + 1L, f$mday))
}

# Calendar ticks: the finest step with at most `max_n` ticks.
date_ticks <- function(lo, hi, max_n) {
  empty <- list(value = numeric(), label = character())
  if (!is.finite(lo) || !is.finite(hi) || max_n < 1L) return(empty)
  if (lo == hi) return(list(value = lo, label = format_date_full(lo)))
  chosen <- NULL; ticks <- numeric()
  for (step in date_steps) {
    ticks <- date_step_ticks(step, lo, hi, max_n)
    if (length(ticks) <= max_n) { chosen <- step; break }
  }
  if (is.null(chosen)) {                       # absurdly long span: thin the coarsest step
    chosen <- date_steps[[length(date_steps)]]
    ticks <- date_step_ticks(chosen, lo, hi)
    if (length(ticks) > max_n) ticks <- ticks[unique(round(seq(1, length(ticks), length.out = max_n)))]
  }
  if (!length(ticks)) return(list(value = lo, label = format_date_full(lo)))
  list(value = ticks, label = date_labels(ticks, chosen, lo, hi))
}

# ---- POSIXct ticks ---------------------------------------------------------------

tz_or_local <- function(tz) if (is.null(tz)) "" else tz

# Local-time fields of seconds since the epoch in `tz`.
time_fields <- function(secs, tz) {
  lt <- as.POSIXlt(.POSIXct(secs, tz = tz_or_local(tz)))
  list(year = lt$year + 1900L, mon = lt$mon, mday = lt$mday, hour = lt$hour, min = lt$min,
       sec = floor(lt$sec), off = ifelse(is.na(lt$gmtoff), 0, lt$gmtoff))
}

format_datetime_full <- function(secs, tz) {
  f <- time_fields(secs, tz)
  sprintf("%04d-%02d-%02d %02d:%02d:%02d", f$year, f$mon + 1L, f$mday, f$hour, f$min, f$sec)
}

# Sub-day steps in seconds, finest first.
time_steps <- c(1, 5, 10, 15, 30, 60, 120, 300, 600, 900, 1800, 3600, 7200, 10800, 21600, 43200)

datetime_ticks <- function(lo, hi, max_n, tz) {
  empty <- list(value = numeric(), label = character())
  if (!is.finite(lo) || !is.finite(hi) || max_n < 1L) return(empty)
  if (lo == hi) return(list(value = lo, label = format_datetime_full(lo, tz)))
  off <- time_fields(lo, tz)$off
  for (step in time_steps) {
    first <- ceiling((lo + off) / step) * step - off
    if (first > hi) next
    if (floor((hi - first) / step) + 1 > max_n) next      # count first: never build a long sequence
    ticks <- seq(first, hi, by = step)
    f <- time_fields(ticks, tz)
    ends <- time_fields(c(lo, hi), tz)
    day_key <- ends$year * 10000L + ends$mon * 100L + ends$mday
    label <- if (step < 60) sprintf("%02d:%02d:%02d", f$hour, f$min, f$sec) else sprintf("%02d:%02d", f$hour, f$min)
    # The date is shown when the axis crosses local midnight, so a time of day is never ambiguous.
    if (day_key[[1L]] != day_key[[2L]]) label <- paste(sprintf("%s %02d", month_abb[f$mon + 1L], f$mday), label)
    return(list(value = ticks, label = label))
  }
  # A day or more: calendar ticks on the local date, at local midnight.
  flo <- time_fields(lo, tz); fhi <- time_fields(hi, tz)
  day_lo <- as.double(as.Date(sprintf("%04d-%02d-%02d", flo$year, flo$mon + 1L, flo$mday)))
  day_hi <- as.double(as.Date(sprintf("%04d-%02d-%02d", fhi$year, fhi$mon + 1L, fhi$mday)))
  cal <- date_ticks(day_lo, day_hi, max_n)
  midnight <- as.double(as.POSIXct(paste(format_date_full(cal$value), "00:00:00"), tz = tz_or_local(tz)))
  keep <- !is.na(midnight) & midnight >= lo & midnight <= hi
  if (!any(keep)) return(list(value = lo, label = format_datetime_full(lo, tz)))
  list(value = midnight[keep], label = cal$label[keep])
}
