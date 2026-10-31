source('integration-apps/bootstrap.R')
paths <- file.path('integration-apps', c('01-termr-showcase/app.R','02-shiny-visual-analytics/app.R','03-mirai-nanonext-monitor/app.R'))
# Parent copy only for the native worker body, with the identical real code.
sys.source(paths[[3L]], envir = .GlobalEnv)
out <- Sys.getenv('TERMR_E_ARTIFACTS','audit-results/real-world-apps/coverage')
dir.create(out, recursive = TRUE, showWarnings = FALSE)
result <- covr::file_coverage(paths, 'integration-apps/automation/coverage-apps-tests.R')
saveRDS(result, file.path(out,'apps.rds'))
write.csv(as.data.frame(result),file.path(out,'apps-lines.csv'),row.names=FALSE)
jsonlite::write_json(list(line_percent=covr::percent_coverage(result),
  files=paths, native_workload='real uninstrumented body; worker lines remain uncovered', branch_coverage='not measured'),
  file.path(out,'apps-summary.json'),auto_unbox=TRUE,pretty=TRUE)
covr::to_cobertura(result,filename=file.path(out,'apps-cobertura.xml'))
tryCatch(covr::report(result,file=file.path(out,'apps.html'),browse=FALSE),
  error=function(e) writeLines(conditionMessage(e),file.path(out,'apps-html-limitation.txt')))
print(covr::percent_coverage(result))
