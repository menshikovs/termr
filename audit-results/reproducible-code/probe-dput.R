packages <- c("bit64", "units", "haven", "lubridate", "blob", "sf", "hms", "vctrs")
for (package in packages) {
  if (!requireNamespace(package, quietly = TRUE)) stop("missing probe package: ", package)
}

objects <- list(
  logical = c(TRUE, FALSE, NA),
  integer = c(1L, NA_integer_, .Machine$integer.max),
  double = c(1 / 3, NA_real_, NaN, Inf, -Inf),
  character = c("quote\"", "backtick`", "line\nbreak", "µ", NA_character_),
  factor = factor(c("low", NA, "high"), levels = c("low", "mid", "high"), ordered = TRUE),
  date = as.Date(c("2024-02-29", NA)),
  posixct = structure(c(1700000000.123456, NA_real_), class = c("POSIXct", "POSIXt"), tzone = "UTC"),
  difftime = structure(c(1.25, NA_real_), units = "secs", class = "difftime"),
  hms = hms::as_hms(c(1.25, NA_real_)),
  integer64 = bit64::as.integer64(c("9223372036854775807", "-9007199254740993", NA)),
  units = units::set_units(c(1.25, NA_real_), "m"),
  labelled = haven::labelled(c(1L, haven::tagged_na("a"), NA_integer_),
                             c(Unknown = -1, Male = 1), label = "Participant sex"),
  labelled_spss = haven::labelled_spss(c(1, 9, 99, NA_real_),
                                       c(No = 1, Yes = 2), label = "Answer",
                                       na_values = 99, na_range = c(90, 99)),
  period = lubridate::period(month = 1, day = 2, hour = 3),
  duration = lubridate::duration(num = 1.25, units = "hours"),
  interval = lubridate::interval(lubridate::ymd_hms("2024-01-01 00:00:00", tz = "UTC"),
                                 lubridate::ymd_hms("2024-01-02 12:00:00", tz = "UTC")),
  raw = as.raw(c(0, 27, 255)),
  raw_list = list(as.raw(c(0, 255)), raw(), NULL),
  blob = blob::blob(as.raw(c(0, 255)), raw(), NULL),
  nested = list(a = c(1L, NA_integer_), b = list("µ", as.raw(27))),
  sf = sf::st_as_sf(data.frame(id = 1:2, x = c(0, 1), y = c(1, 2)),
                    coords = c("x", "y"), crs = 4326)
)

dump_text <- function(x) {
  old <- options(digits = 17)
  on.exit(options(old), add = TRUE)
  con <- textConnection("out", open = "w", local = TRUE)
  on.exit(close(con), add = TRUE)
  dput(x, file = con, control = c("keepNA", "keepInteger", "niceNames", "showAttributes"))
  paste(out, collapse = "\n")
}

results <- lapply(names(objects), function(name) {
  text <- dump_text(objects[[name]])
  parsed <- tryCatch(parse(text = text), error = identity)
  value <- if (inherits(parsed, "error")) parsed else
    tryCatch(eval(parsed, envir = new.env(parent = globalenv())), error = identity)
  data.frame(type = name, parse_ok = !inherits(parsed, "error"),
             eval_ok = !inherits(value, "error"), identical =
               !inherits(value, "error") && identical(value, objects[[name]]),
             code_bytes = nchar(text, type = "bytes"),
             preview = substr(gsub("\\s+", " ", text), 1, 180),
             stringsAsFactors = FALSE)
})
results <- do.call(rbind, results)
print(results, row.names = FALSE)
write.csv(results, "audit-results/reproducible-code/dput-probe.csv", row.names = FALSE)
