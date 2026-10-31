out <- 'audit-results/real-world-apps'
packages <- c('R6','processx','ps','testthat','pkgload','inkr','mirai','nanonext',
  'jsonlite','shiny','ggplot2','plotly','htmlwidgets','covr','lintr','profvis',
  'bit64','units','haven','vctrs','DBI','RSQLite')
result <- data.frame(package=packages, available=vapply(packages,requireNamespace,TRUE,quietly=TRUE))
result$version <- vapply(packages,function(p) if(requireNamespace(p,quietly=TRUE)) as.character(packageVersion(p)) else NA_character_,'')
result$library <- vapply(packages,function(p) if(requireNamespace(p,quietly=TRUE)) find.package(p) else NA_character_,'')
write.csv(result,file.path(out,paste0('packages-',.Platform$OS.type,'.csv')),row.names=FALSE)
print(result); print(R.home()); print(.libPaths()); sessionInfo()
