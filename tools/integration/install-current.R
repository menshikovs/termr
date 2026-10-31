# Install the current checkout into an isolated, provenance-checked library.
root <- normalizePath(Sys.getenv('TERMR_PROJECT_ROOT', getwd()), winslash = '/', mustWork = TRUE)
stopifnot(file.exists(file.path(root, 'DESCRIPTION')))
source(file.path(root, 'integration-apps/source-manifest.R'))
platform <- if (.Platform$OS.type == 'windows') 'windows' else 'linux'
lib <- file.path(root, 'integration-apps/.deps', paste0('current-', platform))
optional <- file.path(root, 'integration-apps/.deps', paste0('R-', platform))
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(lib, optional, .libPaths()))
Sys.setenv(R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep))
out <- file.path(root, 'audit-results/real-world-apps/e-fix', paste0('install-', platform))
dir.create(out, recursive = TRUE, showWarnings = FALSE)
before <- phase_e_source_manifest(root)
status <- system2(file.path(R.home('bin'), 'R'), c('CMD', 'INSTALL', '--no-multiarch',
  paste0('--library=', shQuote(lib)), shQuote(root)),
  stdout = file.path(out, 'stdout.log'), stderr = file.path(out, 'stderr.log'))
writeLines(as.character(status), file.path(out, 'exit-code.txt'))
if (status != 0L) stop('Current package installation failed; see ', out)
stopifnot(identical(before, phase_e_source_manifest(root)))
package <- file.path(lib, 'termr')
payload <- c('DESCRIPTION', 'NAMESPACE', 'R/termr.rdb', 'R/termr.rdx')
manifest <- list(source = before, installed_at = format(Sys.time(), tz = 'UTC'),
  payload = setNames(unname(tools::md5sum(file.path(package, payload))), payload))
stopifnot(!anyNA(manifest$payload))
saveRDS(manifest, file.path(lib, 'termr-source.rds'))
namespace <- loadNamespace('termr', lib.loc = lib)
stopifnot(identical(normalizePath(getNamespaceInfo(namespace, 'path'), winslash = '/'),
  normalizePath(package, winslash = '/')))
stopifnot(all(c('app', 'data_table', 'line_chart', 'termr_mirai_pool') %in% getNamespaceExports(namespace)))
cat('Installed current checkout:', normalizePath(package, winslash = '/'), '\n')
