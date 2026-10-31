source('integration-apps/bootstrap.R')
phase_e_require(c('lintr','jsonlite'))
out<-Sys.getenv('TERMR_E_ARTIFACTS','audit-results/real-world-apps/lint')
dir.create(out,recursive=TRUE,showWarnings=FALSE)
new_files<-c(list.files('integration-apps',pattern='\\.R$',recursive=TRUE,full.names=TRUE),
  list.files('tools/integration',pattern='\\.R$',full.names=TRUE))
new_files<-new_files[!grepl('/(\\.deps|upstream|compat|runtime)/',new_files)]
core<-file.path('R',c('app.R','widget-datatable.R','chart-widget.R','chart-stream.R','tasks_mirai.R',
  'nano_transport.R','inkr-integration.R','shiny.R','datatable-typed.R'))
core<-core[file.exists(core)]
results<-list()
for(file in c(new_files,core)){
  lints<-lintr::lint(file,cache=FALSE)
  for(x in lints)results[[length(results)+1L]]<-data.frame(file=file,line=x$line_number,
    column=x$column_number,type=x$type,linter=x$linter,message=x$message,
    scope=if(file %in% core)'pre-existing core (unchanged)' else 'Phase E application/tool')
}
df<-if(length(results))do.call(rbind,results) else data.frame()
write.csv(df,file.path(out,'lintr-findings.csv'),row.names=FALSE)
jsonlite::write_json(list(files=length(c(new_files,core)),findings=nrow(df),
  by_linter=if(nrow(df))as.list(table(df$linter)) else list(),
  by_scope=if(nrow(df))as.list(table(df$scope)) else list(),
  errors=if(nrow(df))sum(df$type=='error') else 0L,
  policy='Default lintr style findings retained; no mass-formatting of prior user changes.'),
  file.path(out,'lint-summary.json'),auto_unbox=TRUE,pretty=TRUE)
if(nrow(df)&&any(df$type=='error'))quit(status=1L)
