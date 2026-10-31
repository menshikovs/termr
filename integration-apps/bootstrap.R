# Rscript can inherit an unsupported POSIX C.UTF-8 locale on Windows and fall
# back to C. Establish supported UCRT UTF-8 character handling in this process
# before parsing UTF-8 app files; never edit system/user environment settings.
if (.Platform$OS.type == 'windows' && !isTRUE(l10n_info()[['UTF-8']])) {
  phase_e_utf8_locale <- Sys.setlocale('LC_CTYPE', '.UTF-8')
  if (!nzchar(phase_e_utf8_locale) || !isTRUE(l10n_info()[['UTF-8']])) {
    stop('The application requires a UTF-8-capable Windows R session.', call. = FALSE)
  }
}
phase_e_root <- Sys.getenv('TERMR_PROJECT_ROOT', unset = getwd())
phase_e_root <- normalizePath(phase_e_root, winslash = '/', mustWork = TRUE)
if (!file.exists(file.path(phase_e_root, 'DESCRIPTION'))) {
  stop('Run from the termr checkout or set TERMR_PROJECT_ROOT.', call. = FALSE)
}
phase_e_lib <- file.path(phase_e_root, 'integration-apps', '.deps',
  if (.Platform$OS.type == 'windows') 'R-windows' else 'R-linux')
if (dir.exists(phase_e_lib) && !identical(Sys.getenv('TERMR_E_NO_PROJECT_LIB'), '1')) .libPaths(c(phase_e_lib, .libPaths()))
source(file.path(phase_e_root, 'integration-apps/source-manifest.R'))
phase_e_current_lib <- file.path(phase_e_root, 'integration-apps/.deps',
  if (.Platform$OS.type == 'windows') 'current-windows' else 'current-linux')
phase_e_manifest_path <- file.path(phase_e_current_lib, 'termr-source.rds')
phase_e_setup_message <- 'Run Rscript tools/integration/install-current.R from the checkout root to install its current build.'
if (!file.exists(phase_e_manifest_path)) stop(phase_e_setup_message, call. = FALSE)
phase_e_manifest <- readRDS(phase_e_manifest_path)
if (!identical(phase_e_manifest$source, phase_e_source_manifest(phase_e_root))) {
  stop('The isolated termr build is stale or belongs to a different R/platform. ', phase_e_setup_message, call. = FALSE)
}
phase_e_package_path <- file.path(phase_e_current_lib, 'termr')
if (!identical(unname(tools::md5sum(file.path(phase_e_package_path, names(phase_e_manifest$payload)))),
  unname(phase_e_manifest$payload))) stop('Installed termr payload differs from its manifest. ', phase_e_setup_message, call. = FALSE)
.libPaths(c(phase_e_current_lib, .libPaths()))
phase_e_namespace <- loadNamespace('termr', lib.loc = phase_e_current_lib)
if (!identical(normalizePath(getNamespaceInfo(phase_e_namespace, 'path'), winslash = '/'),
  normalizePath(phase_e_package_path, winslash = '/'))) {
  stop('A different termr namespace is already loaded. Start a fresh Rscript process. ', phase_e_setup_message, call. = FALSE)
}

phase_e_require <- function(packages) {
  missing <- packages[!vapply(packages, requireNamespace, TRUE, quietly = TRUE)]
  if (length(missing)) stop('Missing optional packages: ', paste(missing, collapse = ', '),
    '. See integration-apps/README.md for isolated installation.', call. = FALSE)
}

phase_e_mark <- function(event, data = list()) {
  # Opt-in semantic log for automation; never emit debug bytes inside the TUI.
  path <- Sys.getenv('TERMR_E_EVENTS', '')
  if (nzchar(path)) {
    record <- c(list(event = event, at = unname(proc.time()[['elapsed']])), data)
    cat(jsonlite::toJSON(record, auto_unbox = TRUE, null = 'null', digits = NA), '\n', file = path, append = TRUE)
  }
  invisible()
}

phase_e_run <- function(application) {
  outcome <- tryCatch(list(value = termr::run(application$app)),
    error = function(error) list(error = error),
    interrupt = function(error) list(error = error), finally = {
    application$close()
    phase_e_mark('stopped', application$summary())
  })
  if (!is.null(outcome$error)) stop(outcome$error)
  invisible(application)
}
