# Isolate native resource trends from UI allocations in a fresh R process.
source('integration-apps/bootstrap.R')
phase_e_require(c('ps','mirai','nanonext','jsonlite'))
Sys.setenv(R_LIBS=paste(.libPaths(),collapse=.Platform$path.sep))
source('integration-apps/03-mirai-nanonext-monitor/app.R')
kind<-sub('^--kind=','',commandArgs(TRUE)[[1L]])
stopifnot(kind %in% c('mirai','pool','model'))
out<-Sys.getenv('TERMR_E_ARTIFACTS','audit-results/real-world-apps/resource-probes')
dir.create(out,recursive=TRUE,showWarnings=FALSE)
samples<-list();self<-ps::ps_handle()
measure<-function(cycle){gc();Sys.sleep(.1);gc()
  samples[[length(samples)+1L]]<<-data.frame(cycle=cycle,handles_or_fds=ps::ps_num_fds(self),
    rss=unname(ps::ps_memory_info(self)[['rss']]),children=length(ps::ps_children(self)))
}
measure(0L)
for(i in seq_len(15)){
  if(kind=='mirai'){
    profile<-paste0('phase-e-probe-',i)
    mirai::daemons(1L,.compute=profile)
    deadline<-proc.time()[['elapsed']]+10
    while(mirai::status(.compute=profile)$connections<1L){
      if(proc.time()[['elapsed']]>deadline)stop('Daemon startup timeout');Sys.sleep(.005)
    }
    # Same public graceful quit order as termr, without termr pool/UI/transport.
    requests<-mirai::everywhere(quit(save='no',status=0L),.min=1L,.compute=profile)
    deadline<-proc.time()[['elapsed']]+10
    while(mirai::status(.compute=profile)$connections>0L){
      if(proc.time()[['elapsed']]>deadline)stop('Daemon shutdown timeout');Sys.sleep(.005)
    }
    mirai::daemons(0L,.compute=profile);rm(requests)
  } else if(kind=='pool'){
    pool<-termr::termr_mirai_pool(1L);pool$close();rm(pool)
  } else {
    model<-distributed_model(1L);model$poll();model$close();rm(model)
  }
  measure(i)
  write.csv(do.call(rbind,samples),file.path(out,paste0(kind,'-',.Platform$OS.type,'.csv')),row.names=FALSE)
}
cat(kind,'probe complete\n')
