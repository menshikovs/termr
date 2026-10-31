library(units)
cat("ud_convert args:\n")
print(args(ud_convert))
for (case in list(
  list(value = 1e308, from = "km", to = "m"),
  list(value = 5e-324, from = "m", to = "km"),
  list(value = 32, from = "degF", to = "degC")
)) {
  source <- set_units(case$value, case$from, mode = "standard")
  warnings <- character()
  converted <- tryCatch(withCallingHandlers(
    set_units(source, case$to, mode = "standard"),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  ), error = function(e) e)
  cat(case$from, "to", case$to, "=", if (inherits(converted, "error")) conditionMessage(converted) else as.double(drop_units(converted)),
      "warnings:", paste(warnings, collapse = ";"), "\n")
  print(tryCatch(ud_convert(case$value, case$from, case$to), error = function(e) conditionMessage(e)))
}
