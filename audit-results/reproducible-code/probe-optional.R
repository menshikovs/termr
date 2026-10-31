pkgload::load_all(".", quiet = TRUE)
check <- function(name, data) {
  tbl <- data_table(data, cursor = "none")
  if (nrow(data)) tbl$select_range(1L, nrow(data))
  result <- tbl$reproducible_code("value")
  cat(name, "class=", paste(class(data[[1L]]), collapse = "/"),
      "status=", result$status, "reason=", result$reason %||% "", "\n")
}
if (requireNamespace("lubridate", quietly = TRUE)) {
  check("Period", data.frame(value = lubridate::period(month = 1L, day = 2L)))
  check("Duration", data.frame(value = lubridate::duration(3600, units = "seconds")))
  check("Interval", data.frame(value = lubridate::interval(lubridate::ymd("2024-01-01", tz = "UTC"),
                                                             lubridate::ymd("2024-01-03", tz = "UTC"))))
}
if (requireNamespace("hms", quietly = TRUE)) check("hms", data.frame(value = hms::as_hms(c(1.25, NA_real_))))
if (requireNamespace("blob", quietly = TRUE)) check("blob", data.frame(value = blob::blob(as.raw(c(0L, 255L)), raw(), NULL)))
if (requireNamespace("sf", quietly = TRUE)) {
  spatial <- sf::st_as_sf(data.frame(id = 1:2, x = c(0, 1), y = c(1, 2)), coords = c("x", "y"), crs = 4326)
  check("sf", spatial)
}
