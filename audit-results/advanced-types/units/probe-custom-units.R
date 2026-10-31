units_lib <- readLines("audit-results/advanced-types/units/windows-units-lib.txt", warn = FALSE)
if (length(units_lib) && dir.exists(units_lib[[1L]])) .libPaths(c(units_lib[[1L]], .libPaths()))
library(units)
symbol <- "termrtestunit"
tryCatch({
  install_unit(symbol = symbol, def = "201.168 m", name = symbol)
  value <- set_units(1, symbol, mode = "standard")
  meters <- set_units(value, "m", mode = "standard")
  stopifnot(identical(class(value), "units"),
            isTRUE(all.equal(as.double(drop_units(meters)), 201.168,
                             tolerance = 1e-12)))
  cat("registered custom unit converted through units APIs\n")
}, finally = remove_unit(symbol = symbol, name = symbol))
