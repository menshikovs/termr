.libPaths(c('integration-apps/.deps/R-windows',.libPaths()))
for (fn in list(covr::package_coverage,covr::file_coverage,covr::tally_coverage)) print(formals(fn))
print(formals(testthat::test_dir)); print(formals(profvis::profvis))
