haven_lib <- Sys.getenv("TERMR_HAVEN_LIB", unset = "")
if (nzchar(haven_lib) && dir.exists(haven_lib)) .libPaths(c(haven_lib, .libPaths()))
cat("R: ", R.version.string, "\n", sep = "")
cat("haven installed: ", requireNamespace("haven", quietly = TRUE), "\n", sep = "")
if (requireNamespace("haven", quietly = TRUE)) {
  cat("haven version: ", as.character(utils::packageVersion("haven")), "\n", sep = "")
  public <- c("labelled", "labelled_spss", "tagged_na", "is_tagged_na", "na_tag", "as_factor")
  cat("requested exports: ", paste(public %in% getNamespaceExports("haven"), collapse = ","), "\n", sep = "")
  for (name in public) {
    cat("\n-- haven::", name, " --\n", sep = "")
    print(args(getExportedValue("haven", name)))
  }
  x <- haven::labelled(c(1L, 2L, NA_integer_), c(Male = 1L, Female = 2L), label = "Sex")
  spss <- haven::labelled_spss(c(1, 9, 99), c(Male = 1, Refused = 99),
                               na_values = 99, label = "Answer")
  spss_range <- haven::labelled_spss(c(1, 90, 95), c(Male = 1),
                                     na_range = c(90, 95), label = "Answer")
  tagged <- c(1, haven::tagged_na("a"), haven::tagged_na("z"), NA_real_, NaN)
  cat("labelled class/type/attributes:\n")
  print(list(class = class(x), typeof = typeof(x), attributes = attributes(x)))
  cat("SPSS class/type/attributes/is.na:\n")
  print(list(class = class(spss), typeof = typeof(spss), attributes = attributes(spss), is_na = is.na(spss)))
  cat("SPSS range attributes/is.na:\n")
  print(list(attributes = attributes(spss_range), is_na = is.na(spss_range)))
  cat("tagged missing probes:\n")
  print(list(value = haven::format_tagged_na(tagged), is_tagged = haven::is_tagged_na(tagged),
             tag = haven::na_tag(tagged), is_nan = is.nan(tagged)))
  cat("as_factor modes:\n")
  for (level in c("default", "labels", "values", "both")) {
    cat(level, ": ")
    print(haven::as_factor(x, levels = level))
  }
}
