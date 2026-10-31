pkgload::load_all(".", quiet = TRUE)

if (!requireNamespace("vctrs", quietly = TRUE) || !requireNamespace("pillar", quietly = TRUE)) {
  stop("This benchmark needs the optional vctrs and pillar packages.", call. = FALSE)
}

new_termr_a26_vctr <- function(x = double()) {
  vctrs::new_vctr(as.double(x), class = "termr_a26_vctr")
}

format.termr_a26_vctr <- function(x, ...) {
  format(vctrs::vec_data(x), trim = TRUE)
}

pillar_shaft.termr_a26_vctr <- function(x, ...) {
  pillar::new_pillar_shaft_simple(format(x), align = "right")
}

vec_cast.termr_a26_vctr.character <- function(x, to, ...) {
  if (!length(x)) return(new_termr_a26_vctr())
  if (anyNA(x) || any(!grepl("^[+-]?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?$", x))) {
    stop("invalid benchmark value", call. = FALSE)
  }
  value <- as.double(x)
  if (any(!is.finite(value))) stop("invalid benchmark value", call. = FALSE)
  new_termr_a26_vctr(value)
}

new_termr_a26_s3 <- function(x = double()) {
  structure(as.double(x), unit = "u", class = "termr_a26_s3")
}

`[.termr_a26_s3` <- function(x, i, ...) {
  structure(unclass(x)[i], unit = attr(x, "unit", exact = TRUE), class = class(x))
}

format.termr_a26_s3 <- function(x, ...) {
  paste0(format(unclass(x), trim = TRUE), " ", attr(x, "unit", exact = TRUE))
}

measure_ms <- function(fn, repetitions = 5L) {
  fn()
  times <- replicate(repetitions, {
    gc()
    unname(system.time(fn())[["elapsed"]])
  })
  stats::median(times) * 1000
}

allocation_bytes <- function(fn) {
  path <- tempfile("termr-a26-rprofmem-")
  on.exit(unlink(path), add = TRUE)
  utils::Rprofmem(path, threshold = 1024)
  tryCatch(fn(), finally = utils::Rprofmem(NULL))
  lines <- readLines(path, warn = FALSE)
  bytes <- suppressWarnings(as.numeric(sub(" .*", "", lines)))
  sum(bytes[is.finite(bytes)], na.rm = TRUE)
}

make_column <- function(type, n) {
  values <- seq_len(n) / 10
  switch(type,
    double = values,
    Date = as.Date("2000-01-01") + seq_len(n),
    s3 = new_termr_a26_s3(values),
    vctrs = new_termr_a26_vctr(values)
  )
}

rows <- c(100L, 1000L, 100000L)
types <- c("double", "Date", "s3", "vctrs")
slice <- getFromNamespace("table_slice", "termr")
format_values <- getFromNamespace("table_format_values", "termr")

results <- lapply(rows, function(n) lapply(types, function(type) {
  data <- data.frame(value = make_column(type, n))
  build <- function() termr::data_table(data, cursor = "none", editable = TRUE)
  alloc <- allocation_bytes(build)
  table <- build()
  first_render <- measure_ms(function() termr::render_widget(table, 80L, 24L))
  flip <- FALSE
  scroll <- measure_ms(function() {
    flip <<- !flip
    table$scroll_to_row(if (flip) n else 1L)
  })
  visible_rows <- seq_len(min(20L, n))
  visible_format <- measure_ms(function() {
    format_values(slice(data$value, visible_rows), width = 24L)
  })
  edit <- if (type == "s3") {
    NA_real_
  } else {
    text <- switch(type, Date = "2024-02-01", vctrs = "42.125", double = "42.125")
    measure_ms(function() table$set_cell(1L, "value", text))
  }
  data.frame(
    rows = n, type = type,
    build_ms = measure_ms(build),
    first_render_ms = first_render,
    scrolling_ms = scroll,
    visible_20_format_ms = visible_format,
    edit_ms = edit,
    build_alloc_ge_1kb = alloc,
    data_bytes = as.numeric(object.size(data)),
    table_data_bytes = as.numeric(object.size(table$data)),
    stringsAsFactors = FALSE
  )
}))

results <- do.call(rbind, unlist(results, recursive = FALSE))
output <- Sys.getenv(
  "TERMR_A26_PERF_OUT",
  unset = "audit-results/advanced-types/custom-classes/performance-results.csv"
)
write.csv(results, output, row.names = FALSE)
print(results, row.names = FALSE)
