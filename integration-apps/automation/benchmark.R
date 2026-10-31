source('integration-apps/bootstrap.R')
phase_e_require(c('processx','jsonlite'))
out<-Sys.getenv('TERMR_E_ARTIFACTS','audit-results/real-world-apps/benchmark')
dir.create(out,recursive=TRUE,showWarnings=FALSE)
tool<-Sys.which('hyperfine');if(!nzchar(tool))stop('hyperfine missing')
rscript<-file.path(R.home('bin'),'Rscript')
commands<-vapply(c('showcase','analytics','monitor'),function(app)paste(shQuote(rscript),
  'integration-apps/run.R',paste0('--app=',app),'--mode=headless --steps=0'),character(1))
if(Sys.info()[['sysname']]=='Linux')for(kind in c('baseline','candidate'))
  commands[[paste0('rtop-',kind)]]<-paste(shQuote(rscript),'integration-apps/legacy-rtop/run.R',
    '--mode=headless',paste0('--library=',kind))
args<-c('--warmup','1','--runs','5','--export-json',file.path(out,'hyperfine.json'))
for(name in names(commands))args<-c(args,'--command-name',name,commands[[name]])
r<-processx::run(tool,args,env=c('current',TERMR_USE_INSTALLED='1'),timeout=180,error_on_status=FALSE)
writeLines(r$stdout,file.path(out,'hyperfine.stdout.log'));writeLines(r$stderr,file.path(out,'hyperfine.stderr.log'))
if(r$status!=0L)stop('hyperfine failed: ',r$stderr)
jsonlite::write_json(list(status='PASS',warmup=1,runs=5,commands=as.list(commands),
  scope='Whole-process headless startup, initial frame, shutdown. rtop additionally executes eleven scripted scenarios. No terminal I/O latency claim.'),
  file.path(out,'benchmark-scope.json'),auto_unbox=TRUE,pretty=TRUE)
