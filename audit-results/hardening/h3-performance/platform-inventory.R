out <- 'audit-results/hardening/h3-performance'
deps <- c('inkr','mirai','nanonext','DBI','RSQLite','duckdb','dbplyr','arrow','units','haven','sf','lubridate','blob','vctrs','pillar','testthat','processx','roxygen2')
manifest <- data.frame(package = deps, available = vapply(deps, requireNamespace, TRUE, quietly = TRUE))
manifest$version <- vapply(deps, function(p) if (requireNamespace(p, quietly = TRUE)) as.character(packageVersion(p)) else NA_character_, '')
write.csv(manifest, file.path(out, paste0('packages-', .Platform$OS.type, '.csv')), row.names = FALSE)
print(manifest)
sessionInfo()
