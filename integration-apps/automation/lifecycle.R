source('integration-apps/bootstrap.R')
phase_e_require(c('ps','jsonlite'))
for(path in c('01-termr-showcase','02-shiny-visual-analytics','03-mirai-nanonext-monitor'))
  source(file.path('integration-apps',path,'app.R'),local=.GlobalEnv,encoding='UTF-8')
out<-Sys.getenv('TERMR_E_ARTIFACTS','audit-results/real-world-apps/lifecycle')
dir.create(out,recursive=TRUE,showWarnings=FALSE)
samples<-list();self<-ps::ps_handle()
measure<-function(label){
  heap<-gc()
  sample<-list(label=label,at=proc.time()[['elapsed']],rss=unname(ps::ps_memory_info(self)[['rss']]),
    live_heap_mb=sum(heap[,2]),children=length(ps::ps_children(self)),r_connections=nrow(showConnections(all=TRUE)))
  # OS descriptor count includes sockets; never count unrelated system processes.
  sample$descriptors<-tryCatch(ps::ps_num_fds(self),error=function(e)NA_integer_)
  samples[[length(samples)+1L]]<<-sample
}
measure('cold')
for(i in seq_len(100)){
  demo<-workbench_app(use_inkr=FALSE,chart_mode='ascii');p<-termr::test_app(demo$app,width=80,height=24)
  p$press('down','q');p$stop();demo$close()
  stopifnot(demo$summary()$subscribers==0L,demo$summary()$closed)
  rm(demo,p)
  if(i%%10L==0L)measure(paste0('startup-',i))
}
demo<-workbench_app(use_inkr=requireNamespace('inkr',quietly=TRUE),chart_mode='ascii')
p<-termr::test_app(demo$app,width=100,height=30)
latency<-numeric(1000)
tryCatch({
  for(i in seq_len(1000)){
    start<-proc.time()[['elapsed']];p$press(if(i%%2L)'down' else 'up')
    latency[[i]]<-proc.time()[['elapsed']]-start
  }
  for(i in seq_len(100)){demo$action('source');p$step()}
  stopifnot(!demo$state$lazy)
  for(i in seq_len(100)){demo$action('theme');p$step()}
  for(i in seq_len(100)){demo$action('sample');p$step()}
  stopifnot(length(demo$stream$history())<=64L)
  measure('1000-actions-100-sources-themes-charts')
},finally={p$stop();demo$close()})
rm(demo,p);measure('workbench-closed')
worker_cycles<-list()
for(i in seq_len(5)){
  model<-distributed_model(1L);task<-model$submit()
  deadline<-proc.time()[['elapsed']]+20
  while(!task$ready()&&proc.time()[['elapsed']]<deadline){model$poll();Sys.sleep(.005)}
  stopifnot(task$info()$status=='completed')
  for(j in seq_len(4)){
    model$disconnect();model$reconnect()
    deadline<-proc.time()[['elapsed']]+10
    repeat{
      model$poll();if(model$remote()$status()$state=='live')break
      if(proc.time()[['elapsed']]>deadline)stop('Reconnect timeout')
      Sys.sleep(.005)
    }
  }
  model$close();model$close()
  stopifnot(model$diagnostics()$subscriptions==0L)
  worker_cycles[[i]]<-model$diagnostics()
  rm(model,task);Sys.sleep(.05);measure(paste0('worker-cycle-',i))
}
measure('final')
baseline_children<-samples[[1L]]$children
stopifnot(samples[[length(samples)]]$children<=baseline_children)
write.csv(do.call(rbind,lapply(samples,as.data.frame)),file.path(out,'resource-samples.csv'),row.names=FALSE)
jsonlite::write_json(list(status='PASS',startup_shutdown=100,ui_actions=1000,source_changes=100,
  theme_changes=100,chart_updates=100,worker_cycles=5,reconnects=20,
  render_action_seconds=as.list(quantile(latency,c(.5,.95,.99))),samples=samples,worker_final=worker_cycles,
  limits=c('Short controlled run, not an H4 soak test','App private timers/cache/callback registry not inspected',
    'No database connections created; R connection/OS descriptor counts are observable proxies')),
  file.path(out,'lifecycle-results.json'),auto_unbox=TRUE,pretty=TRUE,null='null')
cat('LIFECYCLE PASS\n')
