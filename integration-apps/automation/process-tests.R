source('integration-apps/bootstrap.R')
phase_e_require(c('processx','ps','jsonlite'))
out <- Sys.getenv('TERMR_E_ARTIFACTS','audit-results/real-world-apps/processx')
dir.create(out,recursive=TRUE,showWarnings=FALSE)
rscript <- file.path(R.home('bin'),'Rscript')
checks <- list()
record <- function(name, fn) {
  result <- tryCatch({fn();list(status='PASS')},error=function(e) list(status='FAIL',error=conditionMessage(e)))
  checks[[name]] <<- result;cat(name,result$status,'\n')
}
fixture <- function(mode, timeout=5) processx::run(rscript,
  c('integration-apps/automation/process-fixture.R',mode),timeout=timeout,error_on_status=FALSE)
record('quiet-exit',function() {x<-fixture('quiet');stopifnot(x$status==0L,!nzchar(x$stdout))})
record('stderr-separate',function() {x<-fixture('stderr');stopifnot(x$status==0L,grepl('controlled stderr',x$stderr),!nzchar(x$stdout))})
record('nonzero-exit',function() stopifnot(fixture('exit7')$status==7L))
record('timeout',function() {
  x<-tryCatch(fixture('hang',.2),error=function(e)e)
  stopifnot(inherits(x,'system_command_timeout_error') || (is.list(x)&&isTRUE(x$timeout)))
})
record('owned-child-cleanup',function() {
  p<-processx::process$new(rscript,c('integration-apps/automation/process-fixture.R','child'),stdout='|',stderr='|',cleanup_tree=TRUE)
  on.exit(if(p$is_alive())p$kill_tree())
  deadline<-proc.time()[['elapsed']]+10; text<-''
  repeat {
    p$poll_io(50);text<-paste0(text,p$read_output())
    if(grepl('CHILD [0-9]+',text))break
    if(!p$is_alive()||proc.time()[['elapsed']]>deadline)stop('Child ready timeout: ',text,' | ',p$read_error())
  }
  pid<-as.integer(sub('.*CHILD ([0-9]+).*','\\1',text));handle<-ps::ps_handle(pid)
  p$kill_tree();p$wait(5000)
  deadline<-proc.time()[['elapsed']]+5
  while(ps::ps_is_running(handle)&&proc.time()[['elapsed']]<deadline)Sys.sleep(.02)
  stopifnot(!p$is_alive(),!ps::ps_is_running(handle))
})
for(app in c('showcase','analytics','monitor'))local({
  selected<-app
  record(paste0('real-',selected),function(){
    x<-processx::run(rscript,c('integration-apps/run.R',paste0('--app=',selected),'--mode=headless'),
      env=c('current',TERMR_USE_INSTALLED='1'),timeout=30,error_on_status=FALSE)
    writeLines(x$stdout,file.path(out,paste0(selected,'.stdout.log')))
    writeLines(x$stderr,file.path(out,paste0(selected,'.stderr.log')))
    stopifnot(x$status==0L,grepl(paste('READY',selected),x$stdout),grepl('"closed":true',x$stdout,fixed=TRUE))
  })
})
record('missing-optional-diagnostic',function(){
  # Separate vanilla R library scope, not a global uninstall. Reuse normal
  # dependency libraries; intentionally do not prepend the project library.
  x<-processx::run(rscript,c('-e',"source('integration-apps/bootstrap.R');phase_e_require('phase_e_intentionally_absent_package')"),
    env=c('current',TERMR_E_NO_PROJECT_LIB='1',TERMR_USE_INSTALLED='0'),timeout=15,error_on_status=FALSE)
  stopifnot(x$status!=0L,grepl('Missing optional packages',x$stderr))
})
record('real-monitor-without-native-optionals',function(){
  normal_lib<-if(.Platform$OS.type=='windows')file.path(Sys.getenv('LOCALAPPDATA'),'R/win-library/4.6') else
    file.path(Sys.getenv('HOME'),'R/x86_64-pc-linux-gnu-library/4.5')
  expression<-paste("source('integration-apps/bootstrap.R');",
    "source('integration-apps/03-mirai-nanonext-monitor/app.R');distributed_model(1L)")
  x<-processx::run(rscript,c('-e',expression),env=c('current',TERMR_E_NO_PROJECT_LIB='1',
    TERMR_USE_INSTALLED='0',R_LIBS_USER=normal_lib),timeout=20,error_on_status=FALSE)
  writeLines(x$stderr,file.path(out,'missing-native.stderr.log'))
  stopifnot(x$status!=0L,grepl('Missing optional packages:.*mirai',x$stderr))
})
jsonlite::write_json(checks,file.path(out,'process-results.json'),auto_unbox=TRUE,pretty=TRUE)
if(any(vapply(checks,function(x)x$status=='FAIL',TRUE)))quit(status=1L)
