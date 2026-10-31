source('integration-apps/bootstrap.R')
phase_e_require(c('processx','jsonlite'))
out<-normalizePath(Sys.getenv('TERMR_E_ARTIFACTS','audit-results/real-world-apps/browser-final'),winslash='/',mustWork=FALSE)
dir.create(out,recursive=TRUE,showWarnings=FALSE)
run_browser<-function(){
  ready<-file.path(out,'server-ready.json');stopper<-file.path(out,'server-stop');events<-file.path(out,'server-events.jsonl')
  for(path in c(ready,stopper,events))if(file.exists(path))unlink(path)
  server<-processx::process$new(file.path(R.home('bin'),'Rscript'),
    c('integration-apps/run.R','--app=analytics','--mode=web'),
    env=c('current',TERMR_USE_INSTALLED='1',TERMR_E_SERVER_READY=ready,TERMR_E_STOP=stopper,TERMR_E_EVENTS=events),
    stdout=file.path(out,'server.stdout.log'),stderr=file.path(out,'server.stderr.log'),cleanup_tree=TRUE)
  on.exit({
    file.create(stopper);server$wait(10000)
    if(server$is_alive())server$kill_tree()
  },add=TRUE)
  deadline<-proc.time()[['elapsed']]+30
  while(!file.exists(ready)&&server$is_alive()&&proc.time()[['elapsed']]<deadline)Sys.sleep(.05)
  if(!file.exists(ready))stop('Server ready timeout; see server.stderr.log')
  port<-jsonlite::read_json(ready)$port
  # Client retries cover the interval between assigned port and HTTP listener.
  python<-Sys.which(if(.Platform$OS.type=='windows')'python' else 'python3')
  if(!nzchar(python))stop('Python/Playwright missing')
  Sys.sleep(.5)
  result<-processx::run(python,c('integration-apps/automation/browser-e2e.py',
    paste0('--url=http://127.0.0.1:',port),paste0('--out=',out)),timeout=120,error_on_status=FALSE)
  writeLines(result$stdout,file.path(out,'client.stdout.log'));writeLines(result$stderr,file.path(out,'client.stderr.log'))
  file.create(stopper);server$wait(10000)
  if(result$status!=0L)stop('Browser scenario failed; see client.stderr.log')
  stopifnot(!server$is_alive(),server$get_exit_status()==0L)
  records<-lapply(readLines(events),jsonlite::fromJSON)
  final<-utils::tail(records,1)[[1L]]
  stopifnot(final$event=='web-stopped',final$sessions==0L,final$observers==0L,final$producer_observers==0L)
  jsonlite::write_json(final,file.path(out,'browser-lifecycle.json'),auto_unbox=TRUE,pretty=TRUE)
}
run_browser()
