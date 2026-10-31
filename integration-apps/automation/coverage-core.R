out <- Sys.getenv('TERMR_E_ARTIFACTS','audit-results/real-world-apps/coverage')
dir.create(out, recursive = TRUE, showWarnings = FALSE)
# Deliberately use the normal Linux libraries for this instrumented core run.
# Native mirai worker wrappers cannot carry another process's coverage counters.
# Real native runtime coverage is validated separately without instrumentation.
result <- covr::package_coverage('audit-results/real-world-apps/package-source', type = 'tests',
  quiet = FALSE, clean = FALSE)
saveRDS(result, file.path(out, 'core.rds'))
write.csv(as.data.frame(result), file.path(out, 'core-lines.csv'), row.names = FALSE)
jsonlite::write_json(list(line_percent = covr::percent_coverage(result),
  optional_scope = 'normal Linux libraries: excludes project-only inkr/mirai/nanonext',
  branch_coverage = 'not measured by covr line instrumentation'), file.path(out, 'core-summary.json'),
  auto_unbox = TRUE, pretty = TRUE)
covr::to_cobertura(result, filename = file.path(out, 'core-cobertura.xml'))
tryCatch(covr::report(result, file = file.path(out, 'core.html'), browse = FALSE),
  error = function(e) writeLines(conditionMessage(e), file.path(out, 'core-html-limitation.txt')))
print(covr::percent_coverage(result))
