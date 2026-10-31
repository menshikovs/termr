# Development launcher provenance; base R only, outside the package API.
phase_e_source_manifest <- function(root) {
  files <- c('DESCRIPTION', 'NAMESPACE', sort(list.files(file.path(root, 'R'),
    pattern = '\\.R$', full.names = FALSE)))
  files[-c(1L, 2L)] <- paste0('R/', files[-c(1L, 2L)])
  list(version = unname(read.dcf(file.path(root, 'DESCRIPTION'))[1L, 'Version']),
    files = setNames(unname(tools::md5sum(file.path(root, files))), files),
    platform = R.version$platform, r_minor = paste(R.version$major,
      strsplit(R.version$minor, '.', fixed = TRUE)[[1L]][[1L]], sep = '.'))
}
