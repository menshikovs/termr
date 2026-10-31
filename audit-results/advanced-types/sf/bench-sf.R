pkgload::load_all(".", quiet = TRUE)

if (!requireNamespace("sf", quietly = TRUE)) {
  stop("The sf performance benchmark requires the optional sf package.")
}

elapsed_ms <- function(fn) {
  unname(system.time(fn())[["elapsed"]]) * 1000
}

profile_allocated_bytes <- function(fn) {
  path <- tempfile("termr-sf-alloc-")
  on.exit(unlink(path), add = TRUE)
  utils::Rprofmem(path, threshold = 1024)
  on.exit(utils::Rprofmem(NULL), add = TRUE)
  value <- fn()
  utils::Rprofmem(NULL)
  lines <- if (file.exists(path)) readLines(path, warn = FALSE) else character()
  sizes <- suppressWarnings(as.numeric(sub(" .*", "", lines)))
  list(value = value, bytes_at_least_1k = sum(sizes, na.rm = TRUE),
       allocation_count_at_least_1k = sum(!is.na(sizes)))
}

make_spatial_frame <- function(n) {
  coords <- cbind(as.double(seq_len(n)), as.double(seq_len(n) %% 997L))
  geometry <- sf::st_sfc(lapply(seq_len(n), function(i) sf::st_point(coords[i, ])),
                         crs = 4326)
  sf::st_sf(
    id = seq_len(n),
    measure = sample.int(n, n, replace = FALSE) / 10,
    group = factor(rep(letters[1:4], length.out = n)),
    geometry = geometry
  )
}

results <- list()
# Warm up R6, sf conversion and the terminal renderer outside timed trials.
warm_data <- make_spatial_frame(10L)
warm_table <- data_table(warm_data, editable = TRUE, show_types = TRUE, row_names = FALSE)
warm_pilot <- test_app(app(warm_table), width = 100L, height = 28L)
warm_pilot$stop()
rm(warm_data, warm_table, warm_pilot)
invisible(gc())

for (n in c(100L, 10000L, 100000L)) {
  set.seed(20261030 + n)
  data <- make_spatial_frame(n)
  before_bytes <- as.numeric(object.size(data))
  allocation <- profile_allocated_bytes(function() {
    data_table(data, editable = TRUE, show_types = TRUE, row_names = FALSE)
  })
  table <- allocation$value
  creation_bytes <- allocation$bytes_at_least_1k
  table_bytes <- as.numeric(object.size(table$data))

  first_render_ms <- elapsed_ms(function() {
    pilot <- test_app(app(table), width = 100L, height = 28L)
    pilot$stop()
  })
  pilot <- test_app(app(table), width = 100L, height = 28L)
  scroll_ms <- elapsed_ms(function() table$move_cursor(n))
  selection_ms <- elapsed_ms(function() table$select_range(max(1L, n - 1L), n))
  format_ms <- elapsed_ms(function() {
    rows <- seq_len(min(20L, n))
    table_format_values(table_slice(data$geometry, rows), width = 24L)
  })
  sort_ms <- elapsed_ms(function() table$sort("measure"))
  edit_ms <- elapsed_ms(function() table$set_cell(1L, "measure", "-1"))
  pilot$stop()

  results[[length(results) + 1L]] <- data.frame(
    rows = n,
    create_ms = elapsed_ms(function() {
      invisible(data_table(data, editable = TRUE, show_types = TRUE, row_names = FALSE))
    }),
    first_render_ms = first_render_ms,
    scroll_to_end_ms = scroll_ms,
    selection_ms = selection_ms,
    format_20_visible_ms = format_ms,
    sort_ms = sort_ms,
    edit_one_attribute_ms = edit_ms,
    source_object_bytes = before_bytes,
    table_data_bytes = table_bytes,
    create_allocated_bytes_ge_1k = creation_bytes,
    create_alloc_count_ge_1k = allocation$allocation_count_at_least_1k
  )
  rm(data, table, allocation, pilot)
  invisible(gc())
}

results <- do.call(rbind, results)
utils::write.csv(results, "audit-results/advanced-types/sf/performance-results.csv",
                 row.names = FALSE)
print(results, row.names = FALSE)
