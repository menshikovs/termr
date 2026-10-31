library_path <- Sys.getenv("TERMR_UNITS_LIB", unset = "")
if (nzchar(library_path) && dir.exists(library_path)) {
  .libPaths(c(library_path, .libPaths()))
}

for (package in c("units", "pillar", "vctrs")) {
  installed <- requireNamespace(package, quietly = TRUE)
  cat(package, ": ", installed,
      if (installed) paste0(" ", as.character(packageVersion(package))) else "",
      "\n", sep = "")
}

if (requireNamespace("units", quietly = TRUE)) {
  exports <- getNamespaceExports("units")
  public <- intersect(c("units", "set_units", "as_units", "deparse_unit",
                        "drop_units", "ud_are_convertible", "ud_convert",
                        "install_unit", "remove_unit"), exports)
  cat("public functions: ", paste(public, collapse = ", "), "\n", sep = "")
  for (name in c("units", "set_units", "as_units", "deparse_unit",
                 "ud_are_convertible", "ud_convert", "install_unit", "remove_unit")) {
    if (name %in% exports) {
      cat(name, " formals: ", paste(capture.output(print(formals(getExportedValue("units", name)))),
                                  collapse = " "), "\n", sep = "")
    }
  }
  cat("units exported: ", "units" %in% exports, "\n", sep = "")
  cat("units lookup: ", paste(find("units"), collapse = ", "), "\n", sep = "")
  cat("Ops.units registered: ",
      !is.null(utils::getS3method("Ops", "units", optional = TRUE)), "\n", sep = "")
  cat("Math.units registered: ",
      !is.null(utils::getS3method("Math", "units", optional = TRUE)), "\n", sep = "")
  cat("SystemRequirements: ",
      packageDescription("units", fields = "SystemRequirements"), "\n", sep = "")
  measures <- list(
    length = c("m", "km", "cm"), mass = c("kg", "g"),
    speed = c("m/s", "km/h"), area = c("m^2", "km^2"),
    volume = c("m^3", "L"), temperature = c("degC", "degF", "K"),
    dimensionless = c("1", "%")
  )
  for (group in names(measures)) {
    result <- tryCatch({
      original <- units::set_units(1, measures[[group]][[1L]], mode = "standard")
      converted <- units::set_units(1, measures[[group]][[2L]], mode = "standard")
      back <- units::set_units(converted, base::units(original), mode = "standard")
      c(label = units::deparse_unit(original), value = as.numeric(back))
    }, error = function(e) paste("ERROR:", conditionMessage(e)))
    cat(group, ": ", paste(result, collapse = " "), "\n", sep = "")
  }
}
