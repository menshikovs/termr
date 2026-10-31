# Fresh documented web entrypoint + real browser; no parent application source().
root <- normalizePath(getwd(), winslash = '/')
.libPaths(c(file.path(root,'integration-apps/.deps',if(.Platform$OS.type=='windows')'R-windows' else 'R-linux'),.libPaths()))
out <- normalizePath(Sys.getenv('TERMR_E_ARTIFACTS'),winslash='/',mustWork=FALSE)
dir.create(out,recursive=TRUE,showWarnings=FALSE)
Sys.unsetenv('TERMR_USE_INSTALLED')
use_wsl <- '--wsl-server' %in% commandArgs(TRUE)
run <- function() {
  ready<-file.path(out,'ready.json');stopper<-file.path(out,'STOP');events<-file.path(out,'events.jsonl')
  for(path in c(ready,stopper,events))if(file.exists(path))unlink(path)
  server<-if(use_wsl) {
    linux_path<-function(path)paste0('/mnt/',tolower(substr(path,1L,1L)),substring(path,3L))
    processx::process$new('wsl.exe',c('-d','Ubuntu','bash',
      paste0(linux_path(root),'/integration-apps/automation/entrypoint-web-wsl.sh'),linux_path(out)),
      stdout=file.path(out,'wsl.stdout.log'),stderr=file.path(out,'wsl.stderr.log'),cleanup_tree=TRUE)
  } else processx::process$new(file.path(R.home('bin'),'Rscript'),
    c('integration-apps/run.R','--app=analytics','--mode=web'),
    env=c('current',TERMR_E_SERVER_READY=ready,TERMR_E_STOP=stopper,TERMR_E_EVENTS=events,
      R_PROFILE_USER=file.path(root,'integration-apps/automation/entrypoint-profile.R'),
      TERMR_E_RUNTIME=file.path(out,'runtime.json')),
    stdout=file.path(out,'stdout.log'),stderr=file.path(out,'stderr.log'),cleanup_tree=TRUE)
  on.exit({file.create(stopper);server$wait(10000);if(server$is_alive())server$kill_tree()},add=TRUE)
  deadline<-proc.time()[['elapsed']]+30
  repeat {
    if(!server$is_alive())stop('Web entrypoint exited before first HTTP response.')
    if(file.exists(ready)){
      port<-jsonlite::read_json(ready)$port
      online<-tryCatch({connection<-url(paste0('http://127.0.0.1:',port));on.exit(close(connection));
        length(readLines(connection,n=1L,warn=FALSE))>0L},error=function(e)FALSE)
      if(online)break
    }
    if(proc.time()[['elapsed']]>deadline)stop('Web first-response timeout.')
    Sys.sleep(.05)
  }
  python<-Sys.which(if(.Platform$OS.type=='windows')'python' else 'python3')
  client<-processx::run(python,c('integration-apps/automation/browser-e2e.py',
    paste0('--url=http://127.0.0.1:',port),paste0('--out=',out)),timeout=120,error_on_status=FALSE)
  writeLines(client$stdout,file.path(out,'browser.stdout.log'));writeLines(client$stderr,file.path(out,'browser.stderr.log'))
  file.create(stopper);server$wait(10000)
  writeLines(as.character(server$get_exit_status()),file.path(out,'exit-code.txt'))
  stopifnot(client$status==0L,!server$is_alive(),server$get_exit_status()==0L)
  rows<-lapply(readLines(events),jsonlite::fromJSON);last<-tail(rows,1L)[[1L]]
  stopifnot(last$event=='web-stopped',last$sessions==0L,last$observers==0L,last$producer_observers==0L)
  jsonlite::write_json(list(app='Analytics Web',start='PASS',render='PASS',interact='PASS',
    integration='PASS',shutdown='PASS',exit_code=0L,final=last),file.path(out,'gates.json'),auto_unbox=TRUE,pretty=TRUE)
}
run()
