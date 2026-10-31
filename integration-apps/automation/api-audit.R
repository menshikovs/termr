source('integration-apps/bootstrap.R')
phase_e_require('jsonlite')
out <- Sys.getenv('TERMR_E_ARTIFACTS','audit-results/real-world-apps/e-fix/api')
dir.create(out,recursive=TRUE,showWarnings=FALSE)
files <- c('integration-apps/run.R','integration-apps/bootstrap.R',
  list.files('integration-apps',pattern='\\.R$',recursive=TRUE,full.names=TRUE),
  list.files('tools/integration',pattern='\\.R$',full.names=TRUE))
files <- unique(files[!grepl('/(\\.deps|upstream|compat|runtime)/',files)])
packages <- c('termr','shiny','ggplot2','plotly','mirai','nanonext','inkr')
rows <- list()
inspect <- function(node,file) {
  if (missing(node)) return(invisible())
  if (!is.call(node)) return(invisible())
  head <- node[[1L]]
  if (is.call(head) && as.character(head[[1L]]) %in% c('::',':::') && length(head)==3L) {
    package <- as.character(head[[2L]]);name <- as.character(head[[3L]])
    if (package %in% packages) {
      error <- NULL;signature <- '';status <- 'PASS'
      if (!requireNamespace(package,quietly=TRUE)) status <- 'OPTIONAL_UNAVAILABLE' else {
        error <- tryCatch({
          if (as.character(head[[1L]])!='::' || !name %in% getNamespaceExports(package)) stop('Not an exported public API')
          fn <- getExportedValue(package,name)
          if (!is.function(fn)) stop('Export is not callable')
          matched <- match.call(fn,node,expand.dots=FALSE)
          signature <- paste(names(formals(fn)),collapse=', ')
          required <- names(formals(fn))[vapply(formals(fn),function(x)identical(x,quote(expr=)),TRUE)]
          required <- setdiff(required,'...')
          absent <- setdiff(required,names(as.list(matched))[-1L])
          # on(type, function(event, app) ...) is a documented overload; its
          # implementation moves selector to handler before validating it.
          if(package=='termr' && name=='on' && 'handler' %in% absent &&
             is.call(matched$selector) && identical(matched$selector[[1L]],as.name('function'))) {
            absent <- setdiff(absent,'handler')
          }
          if (length(absent)) stop('Missing required arguments: ',paste(absent,collapse=', '))
          NULL
        },error=function(e)conditionMessage(e))
        if (!is.null(error)) status <- 'FAIL'
      }
      rows[[length(rows)+1L]] <<- data.frame(file=file,api=paste(package,name,sep='::'),
        call=paste(deparse(node,width.cutoff=100L),collapse=' '),signature=signature,
        status=status,error=if(is.null(error))'' else error)
    }
  }
  for (part in as.list(node)[-1L]) inspect(part,file)
}
for (file in files) for (node in parse(file,keep.source=TRUE)) inspect(node,file)
df <- do.call(rbind,rows)
write.csv(df,file.path(out,'namespace-calls.csv'),row.names=FALSE)
for(path in c('01-termr-showcase','02-shiny-visual-analytics','03-mirai-nanonext-monitor'))
  source(file.path('integration-apps',path,'app.R'),local=.GlobalEnv,encoding='UTF-8')
types <- list();methods <- list();method_calls <- list()
for (name in c('showcase','analytics','monitor')) {
  demo <- switch(name,showcase=workbench_app(),analytics=analytics_terminal(),monitor=distributed_monitor(1L))
  tryCatch({
    types[[name]] <- list(app=class(demo$app),table=class(demo$table),
      selected_row_return=class(demo$table$selected_row()),
      row_data_return=class(demo$table$row_data(1L)),
      chart=if(!is.null(demo$chart))class(demo$chart) else class(demo$app$query_one('#live-chart')))
    objects <- list(app=demo$app,view=demo$app,table=demo$table,
      chart=if(!is.null(demo$chart))demo$chart else demo$app$query_one('#live-chart'))
    if(name=='showcase')objects<-c(objects,list(line=objects$chart,
      scatter=demo$app$query_one('#scatter'),bars=demo$app$query_one('#bar'),
      histogram=demo$app$query_one('#histogram'),heatmap=demo$app$query_one('#heatmap'),
      sidebar=demo$app$query_one('#sidebar'),pages=demo$app$query_one('#pages'),
      types=demo$types,stream=demo$stream))
    if(name=='showcase')objects$chart_tabs<-demo$app$query_one('#chart-tabs')
    if(name=='analytics')objects$stream<-demo$model$stream
    if(name=='monitor')objects<-c(objects,list(pool=demo$model$pool,remote=demo$model$remote()))
    inspect_method <- function(node) {
      if(missing(node)||!is.call(node))return(invisible())
      head<-node[[1L]]
      if(is.call(head)&&identical(head[[1L]],as.name('$'))&&is.symbol(head[[2L]])){
        receiver<-as.character(head[[2L]]);field<-as.character(head[[3L]])
        if(receiver %in% names(objects)){
          error<-tryCatch({fn<-objects[[receiver]][[field]]
            if(!is.function(fn))stop('No callable public method')
            match.call(fn,node,expand.dots=FALSE);NULL},error=function(e)conditionMessage(e))
          method_calls[[length(method_calls)+1L]]<<-data.frame(app=name,receiver=receiver,method=field,
            call=paste(deparse(node),collapse=' '),status=if(is.null(error))'PASS' else 'FAIL',
            error=if(is.null(error))'' else error)
        }
      }
      for(part in as.list(node)[-1L])inspect_method(part)
    }
    app_file<-file.path('integration-apps',switch(name,showcase='01-termr-showcase',analytics='02-shiny-visual-analytics',monitor='03-mirai-nanonext-monitor'),'app.R')
    for(node in parse(app_file))inspect_method(node)
    for(key in names(objects)){
      object<-objects[[key]]
      public<-names(object)[vapply(names(object),function(field){
        value<-tryCatch(object[[field]],error=function(e)NULL);is.function(value)},TRUE)]
      methods[[paste(name,key,sep='.')]]<-setNames(lapply(public,function(field)names(formals(object[[field]]))),public)
    }
  },finally=demo$close())
}
method_df<-do.call(rbind,method_calls)
write.csv(method_df,file.path(out,'method-calls.csv'),row.names=FALSE)
jsonlite::write_json(list(calls=nrow(df),invalid=sum(df$status=='FAIL'),
  resolved_method_calls=nrow(method_df),invalid_methods=sum(method_df$status=='FAIL'),
  method_scope='Statically resolvable app/view/table/chart/stream/pool aliases. Dynamic owner callbacks are covered by functional tests.',
  namespace_path=getNamespaceInfo(asNamespace('termr'),'path'),
  source=phase_e_manifest$source,constructor_return_types=types,public_method_signatures=methods),
  file.path(out,'api-summary.json'),auto_unbox=TRUE,pretty=TRUE)
print(df[df$status=='FAIL',c('file','api','error')],row.names=FALSE)
if(any(df$status=='FAIL')||any(method_df$status=='FAIL'))quit(status=1L)
