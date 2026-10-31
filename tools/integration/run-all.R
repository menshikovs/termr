# Opt-in integration runner; never invoked by R CMD check.
normal_library_paths <- .libPaths()
source('integration-apps/bootstrap.R')
argv <- commandArgs(TRUE)
option <- function(name, default) {
  value <- grep(paste0('^--', name, '='), argv, value = TRUE)
  if (length(value)) sub(paste0('^--', name, '='), '', value[[1L]]) else default
}
selected <- match.arg(option('app', 'all'), c('all', 'showcase', 'analytics', 'monitor', 'rtop'))
modes <- strsplit(option('mode', 'headless'), ',', fixed = TRUE)[[1L]]
allowed <- c('unit','headless','process','pty','expect','tmux','legacy','browser',
  'lifecycle','lint','profile','benchmark','recording','coverage','api','gates')
if (any(!modes %in% allowed)) stop('Modes: ', paste(allowed, collapse = ', '))
timeout <- as.numeric(option('timeout', '180'))
if (!is.finite(timeout) || timeout <= 0) stop('Timeout must be positive seconds.')
out <- normalizePath(option('out', 'audit-results/real-world-apps/runner'), winslash = '/', mustWork = FALSE)
dir.create(out, recursive = TRUE, showWarnings = FALSE)
Sys.setenv(TERMR_E_ARTIFACTS = out, TERMR_PROJECT_ROOT = phase_e_root, TERMR_USE_INSTALLED = '1')
phase_e_require(c('processx','jsonlite'))
rscript <- file.path(R.home('bin'), 'Rscript')
results <- list()
skip <- function(name, reason) {
  results[[length(results)+1L]] <<- list(name = name, status = 'SKIP', reason = reason)
  cat('SKIP', name, ':', reason, '\n')
}
run_task <- function(name, command, arguments = character(), environment = c('current')) {
  cat('RUN', name, '\n')
  started <- proc.time()[['elapsed']]
  result <- tryCatch({
    process <- processx::process$new(command, arguments, wd = phase_e_root, env = environment,
      stdout = file.path(out, paste0(name, '.stdout.log')),
      stderr = file.path(out, paste0(name, '.stderr.log')), cleanup_tree = TRUE)
    on.exit(if (process$is_alive()) process$kill_tree(), add = TRUE)
    process$wait(timeout * 1000)
    timed_out <- process$is_alive()
    if (timed_out) {process$kill_tree(); process$wait(5000)}
    code <- process$get_exit_status()
    list(status = if (!timed_out && identical(code, 0L)) 'PASS' else 'FAIL',
      exit_code = code, timeout = timed_out)
  }, error = function(e) list(status = 'FAIL', error = conditionMessage(e)))
  result <- c(list(name = name, seconds = proc.time()[['elapsed']]-started), result)
  results[[length(results)+1L]] <<- result
  jsonlite::write_json(results, file.path(out,'runner-results.json'), auto_unbox = TRUE, pretty = TRUE, null = 'null')
  cat(result$status, name, '\n')
}
apps <- if (selected == 'all') c('showcase','analytics','monitor') else selected
linux <- identical(Sys.info()[['sysname']], 'Linux')
for (mode in modes) {
  if (mode == 'api') run_task('api-audit',rscript,'integration-apps/automation/api-audit.R')
  if (mode == 'gates') {
    if(selected=='rtop')skip('entrypoint-gates','Use legacy mode for rtop.') else {
      python<-Sys.which(if(.Platform$OS.type=='windows')'python' else 'python3')
      gate_out<-file.path(out,'terminal-gates')
      run_task('terminal-gates',python,c('integration-apps/automation/entrypoint-pty.py',
        paste0('--app=',selected),paste0('--out=',gate_out)))
      if(selected %in% c('all','analytics')) {
        if(.Platform$OS.type=='windows')run_task('browser-gates',rscript,
          'integration-apps/automation/entrypoint-browser.R',
          c('current',TERMR_E_ARTIFACTS=file.path(out,'browser-gates'))) else
          skip('browser-gates','Run entrypoint-browser.R --wsl-server from native Windows R for Chrome against WSL Shiny.')
      }
    }
  }
  if (mode == 'unit') run_task('app-tests', rscript, c('integration-apps/automation/run-app-tests.R', selected))
  if (mode == 'headless') for (app in apps) {
    if (app == 'rtop') skip('headless-rtop', 'Use --mode=legacy on Linux.') else {
      needed <- if (app == 'monitor') c('mirai','nanonext') else character()
      absent <- needed[!vapply(needed, requireNamespace, TRUE, quietly = TRUE)]
      if (length(absent)) skip(paste0('headless-',app), paste('Missing optional packages:',paste(absent,collapse=', '))) else
        run_task(paste0('headless-',app),rscript,c('integration-apps/run.R',paste0('--app=',app),'--mode=headless'))
    }
  }
  if (mode %in% c('process','browser','lifecycle','lint','profile','benchmark')) {
    script <- switch(mode, process='process-tests.R',browser='browser-process.R',lifecycle='lifecycle.R',
      lint='lint.R',profile='profile.R',benchmark='benchmark.R')
    run_task(mode,rscript,c(file.path('integration-apps/automation',script),paste0('--app=',selected)))
  }
  if (mode %in% c('pty','recording','expect','tmux','legacy','coverage')) {
    if (!linux) {skip(mode,'Requires POSIX terminal/tools; run this command in Ubuntu WSL.'); next}
    live_out <- file.path(out,mode)
    dir.create(live_out,recursive=TRUE,showWarnings=FALSE)
    if (mode %in% c('pty','recording')) {
      if (!nzchar(Sys.which('python3'))) {skip(mode,'python3 missing');next}
      if (mode == 'recording' && !nzchar(Sys.which('asciinema'))) {skip(mode,'asciinema missing');next}
      arguments <- c('integration-apps/automation/pty-e2e.py',paste0('--app=',selected),paste0('--out=',live_out))
      if (mode == 'recording') arguments <- c(arguments,'--record')
      run_task(mode,Sys.which('python3'),arguments)
    }
    if (mode == 'expect') {
      if (!nzchar(Sys.which('expect'))) skip(mode,'Expect missing') else for (app in intersect(apps,c('showcase','monitor')))
        run_task(paste0('expect-',app),Sys.which('expect'),c('integration-apps/automation/smoke.exp',app,live_out))
    }
    if (mode == 'tmux') {
      if (!nzchar(Sys.which('tmux'))) skip(mode,'tmux missing') else
        run_task(mode,Sys.which('python3'),c('integration-apps/automation/tmux-e2e.py',paste0('--out=',live_out)))
    }
    if (mode == 'legacy') for (kind in c('baseline','candidate'))
      run_task(paste0('rtop-',kind),rscript,c('integration-apps/legacy-rtop/run.R',paste0('--library=',kind),'--mode=headless'))
    if (mode == 'coverage') {
      normal_lib <- paste(normal_library_paths[!grepl('integration-apps/.deps',normal_library_paths,fixed=TRUE)],collapse=.Platform$path.sep)
      run_task('core-coverage',rscript,'integration-apps/automation/coverage-core.R',
        c('current',R_LIBS_USER=normal_lib,R_LIBS='',NOT_CRAN='false',TERMR_E_NO_PROJECT_LIB='1',TERMR_E_ARTIFACTS=live_out))
      run_task('apps-coverage',rscript,'integration-apps/automation/coverage-apps.R',
        c('current',TERMR_E_ARTIFACTS=live_out))
    }
  }
}
jsonlite::write_json(list(platform=Sys.info(),app=selected,modes=modes,results=results),
  file.path(out,'run-summary.json'),auto_unbox=TRUE,pretty=TRUE,null='null')
quit(status=if (any(vapply(results,function(x) x$status=='FAIL',TRUE))) 1L else 0L)
