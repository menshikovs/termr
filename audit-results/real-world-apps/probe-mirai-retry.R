source('integration-apps/bootstrap.R')
x<-processx::run(file.path(R.home('bin'),'Rscript'),
  c('integration-apps/automation/resource-probe.R','--kind=mirai'),
  env=c('current',TERMR_USE_INSTALLED='1'),timeout=60,error_on_status=FALSE)
writeLines(x$stdout,'audit-results/real-world-apps/resource-probe-mirai-final.stdout.log')
writeLines(x$stderr,'audit-results/real-world-apps/resource-probe-mirai-final.stderr.log')
writeLines(as.character(x$status),'audit-results/real-world-apps/resource-probe-mirai-final.exit')
if(x$status!=0L)quit(status=1L)
