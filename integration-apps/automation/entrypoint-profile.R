# Diagnostics only: loaded by R_PROFILE_USER in fresh entrypoint processes.
# Never source/bootstrap an application from this profile.
.efix_record_runtime <- function(stage) {
  target <- Sys.getenv('TERMR_E_RUNTIME', '')
  if (!nzchar(target) || !requireNamespace('jsonlite', quietly = TRUE)) return(invisible())
  loaded <- 'termr' %in% loadedNamespaces()
  packages <- c('termr','inkr','mirai','nanonext','shiny','ggplot2','plotly')
  runtime <- list(stage=stage, pid=Sys.getpid(), R=R.version.string,
    locale=Sys.getlocale(), utf8=isTRUE(l10n_info()[['UTF-8']]),
    command=commandArgs(), cwd=getwd(), lib_paths=.libPaths(), termr_loaded=loaded,
    packages=lapply(packages,function(package) list(package=package,
      loaded=package %in% loadedNamespaces(),
      version=if (package %in% loadedNamespaces()) as.character(getNamespaceVersion(package)) else NULL,
      namespace_path=if (package %in% loadedNamespaces()) getNamespaceInfo(asNamespace(package),'path') else NULL)))
  jsonlite::write_json(runtime,target,auto_unbox=TRUE,pretty=TRUE,null='null')
}
.Last <- function() .efix_record_runtime('exit')
options(error=function() {
  target <- Sys.getenv('TERMR_E_RUNTIME', '')
  if (nzchar(target)) writeLines(capture.output(sys.calls()), file.path(dirname(target),'traceback.txt'))
  .efix_record_runtime('error')
  # A returning options(error=...) handler makes Rscript exit 0. Preserve the
  # normal failing-process contract; application finally blocks have run first.
  quit(save='no',status=1L,runLast=FALSE)
})
