library_path <- Sys.getenv("TERMR_UNITS_LIB", unset = "")
if (nzchar(library_path) && dir.exists(library_path)) {
  .libPaths(c(library_path, .libPaths()))
}
library(units)
x <- units::set_units(1, "m", mode = "standard")
print(x)
print(class(x))
print(attributes(x))
u <- base::units(x)
print(u)
y <- units::set_units(100, "cm", mode = "standard")
print(y)
z <- units::set_units(y, u, mode = "standard")
print(z)
print(units::deparse_unit(x))
prototype <- vctrs::vec_ptype(x)
cat("vctrs ptype class: ", paste(class(prototype), collapse = "/"),
    "; typeof: ", typeof(prototype), "\n", sep = "")
candidate <- units::set_units(125, "cm", mode = "standard")
converted <- units::set_units(candidate, base::units(x), mode = "standard")
cast <- tryCatch(vctrs::vec_cast(converted, prototype), error = function(e) e)
print(cast)
cat("cast class: ", paste(class(cast), collapse = "/"),
    "; typeof: ", typeof(cast), "; attrs identical: ",
    identical(attributes(cast), attributes(prototype)), "\n", sep = "")
na <- units::set_units(NA_real_, base::units(x), mode = "standard")
cat("NA: ", is.na(na), "; class: ", paste(class(na), collapse = "/"),
    "; attrs identical: ", identical(attributes(na), attributes(x)), "\n", sep = "")
integer_x <- units::set_units(1:2, "m", mode = "standard")
integer_ptype <- vctrs::vec_ptype(integer_x)
cat("integer-backed typeof: ", typeof(integer_x), "\n", sep = "")
for (number in c(3, 3.5)) {
  quantity <- units::set_units(number, base::units(integer_ptype), mode = "standard")
  result <- tryCatch(vctrs::vec_cast(quantity, integer_ptype), error = function(e) e)
  cat(number, " cast result class: ", paste(class(result), collapse = "/"),
      "; typeof: ", typeof(result), "\n", sep = "")
  if (inherits(result, "error")) cat("cast error: ", conditionMessage(result), "\n", sep = "")
}
