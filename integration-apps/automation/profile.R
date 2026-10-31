source('integration-apps/bootstrap.R')
phase_e_require(c('profvis','jsonlite','htmlwidgets'))
for(path in c('01-termr-showcase','02-shiny-visual-analytics','03-mirai-nanonext-monitor'))
  source(file.path('integration-apps',path,'app.R'),local=.GlobalEnv,encoding='UTF-8')
out<-Sys.getenv('TERMR_E_ARTIFACTS','audit-results/real-world-apps/profiles')
dir.create(out,recursive=TRUE,showWarnings=FALSE)
cases<-list(
  app_startup=function(){for(i in 1:10){x<-workbench_app(use_inkr=FALSE);p<-termr::test_app(x$app);p$stop();x$close()}},
  table_and_events=function(){x<-workbench_app(use_inkr=FALSE);p<-termr::test_app(x$app)
    tryCatch(for(i in 1:100)p$press('down','up','right','left'),finally={p$stop();x$close()})},
  chart_stream=function(){x<-workbench_app(use_inkr=FALSE);p<-termr::test_app(x$app)
    tryCatch({p$press('alt+c');for(i in 1:100){x$action('sample');p$step()}},finally={p$stop();x$close()})},
  shiny_updates=function(){d<-analytics_dashboard()
    tryCatch(shiny::testServer(d$server,{for(i in 1:30){session$setInputs(next_sample=i);session$flushReact();output$values;output$agreement}}),finally=d$close())},
  mirai_nanonext=function(){m<-distributed_model(1L)
    tryCatch({task<-m$submit();deadline<-proc.time()[['elapsed']]+20
      while(!task$ready()&&proc.time()[['elapsed']]<deadline){m$poll();Sys.sleep(.005)}
      stopifnot(task$info()$status=='completed');for(i in 1:100)m$poll()},finally=m$close())})
timings<-list()
repairs<-list()
summarize_profile<-function(file){
  tryCatch(summaryRprof(file,memory='both'),error=function(e){
    # Shiny debug call labels can contain physical newlines (e.g. Plotly's
    # render label). Rprof writes them literally, which summaryRprof cannot
    # parse. Preserve raw output and join only continuation lines in a copy.
    lines<-readLines(file);records<-character();joined<-0L
    for(line in lines){
      if(grepl('^(memory profiling:|:[0-9]+:[0-9]+:[0-9]+:[0-9]+:)',line))records<-c(records,line) else {
        if(!length(records))stop('Unexpected Rprof header')
        records[[length(records)]]<-paste(records[[length(records)]],line)
        joined<-joined+1L
      }
    }
    normalized<-sub('\\.Rprof$','-normalized.Rprof',file)
    writeLines(records,normalized)
    repairs[[basename(file)]]<<-list(parser_error=conditionMessage(e),continuations_joined=joined,
      derived_file=basename(normalized),samples_dropped=0L)
    summaryRprof(normalized,memory='both')
  })
}
for(name in names(cases)){
  cat('PROFILE',name,'\n');file<-file.path(out,paste0(name,'.Rprof'))
  start<-proc.time()[['elapsed']];Rprof(file,interval=.01,memory.profiling=TRUE)
  tryCatch(cases[[name]](),finally=Rprof(NULL))
  timings[[name]]<-proc.time()[['elapsed']]-start
  summary<-summarize_profile(file)
  saveRDS(summary,file.path(out,paste0(name,'-summary.rds')))
  write.csv(summary$by.total,file.path(out,paste0(name,'-total.csv')))
  write.csv(summary$by.self,file.path(out,paste0(name,'-self.csv')))
}
# profvis performs a separate genuine workload; artifacts can be opened locally.
visual<-profvis::profvis({x<-workbench_app(use_inkr=FALSE);p<-termr::test_app(x$app)
  tryCatch(for(i in 1:50)p$press('down','up'),finally={p$stop();x$close()})},interval=.01)
htmlwidgets::saveWidget(visual,file.path(out,'workbench-profvis.html'),selfcontained=FALSE)
if(Sys.info()[['sysname']]=='Linux'){
  # rtop fixture refresh is a real original UI, using exported run boundary.
  # Separate process profile avoids reusing the already loaded baseline namespace.
  script<-file.path(out,'rtop-profile-run.R')
  writeLines(c("Rprof(Sys.getenv('TERMR_E_RTOP_PROFILE'),interval=.01)",
    "tryCatch(source('integration-apps/legacy-rtop/run.R'),finally=Rprof(NULL))"),script)
  r<-processx::run(file.path(R.home('bin'),'Rscript'),c(script,'--mode=headless','--library=candidate'),
    env=c('current',TERMR_E_RTOP_PROFILE=normalizePath(file.path(out,'rtop-refresh.Rprof'),mustWork=FALSE)),timeout=60,error_on_status=FALSE)
  stopifnot(r$status==0L)
  write.csv(summaryRprof(file.path(out,'rtop-refresh.Rprof'))$by.total,file.path(out,'rtop-refresh-total.csv'))
}
jsonlite::write_json(list(status='PASS',seconds=timings,interval_seconds=.01,parser_repairs=repairs,
  scope='Parent-process sampled CPU/allocations; worker compute is not attributed to controller; timings include setup/cleanup'),
  file.path(out,'profile-summary.json'),auto_unbox=TRUE,pretty=TRUE)
