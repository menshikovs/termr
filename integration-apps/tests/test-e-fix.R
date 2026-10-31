test_that('documented entrypoint locates the checkout outside its working directory', {
  entry<-file.path(phase_e_root,'integration-apps/run.R')
  result<-processx::run(file.path(R.home('bin'),'Rscript'),c(entry,'--app=showcase','--mode=headless'),
    wd=tempdir(),env=c('current',TERMR_USE_INSTALLED='',TERMR_PROJECT_ROOT=phase_e_root),
    timeout=30,error_on_status=FALSE)
  expect_identical(result$status,0L,info=result$stderr)
  expect_match(result$stdout,'READY showcase')
})

test_that('empty analytics view clears the chart as well as its table', {
  demo<-analytics_terminal();p<-termr::test_app(demo$app)
  on.exit({p$stop();demo$close()},add=TRUE)
  expect_match(demo$model$stream$latest()$label,'\u6771\u4eac')
  p$press('f2','f2');p$advance(.05)
  expect_false(is.na(demo$chart$selected_index))
  p$press('f4');p$advance(.05)
  expect_identical(demo$table$row_count,0L)
  expect_true(is.na(demo$chart$selected_index))
  p$press('f4');p$advance(.05)
  expect_gt(demo$table$row_count,0L)
  expect_false(is.na(demo$chart$selected_index))
})

test_that('Enter on a task shows its actual worker result', {
  skip_if_not_installed('mirai');skip_if_not_installed('nanonext')
  demo<-distributed_monitor(1L);p<-termr::test_app(demo$app,width=110,height=32)
  on.exit({p$stop();demo$close()},add=TRUE)
  p$press('n')
  wait_real(function() any(demo$model$rows()$status=='completed'),step=function()p$advance(.05))
  p$focus('#tasks');p$press('enter')
  expect_length(demo$app$screens,2L)
  expect_match(paste(p$screen_text(),collapse='\n'),'Task details')
  expect_match(paste(p$screen_text(),collapse='\n'),'chunks')
})

test_that('launcher refuses missing, stale and modified installed builds', {
  for (problem in c('missing','stale','payload')) {
    root<-tempfile('termr-loader-');dir.create(root)
    dir.create(file.path(root,'integration-apps'),recursive=TRUE)
    for (file in c('DESCRIPTION','NAMESPACE','integration-apps/bootstrap.R','integration-apps/source-manifest.R'))
      file.copy(file.path(phase_e_root,file),file.path(root,file))
    lib<-file.path(root,'integration-apps/.deps',if(.Platform$OS.type=='windows')'current-windows' else 'current-linux')
    dir.create(lib,recursive=TRUE)
    if(problem!='missing')saveRDS(phase_e_manifest,file.path(lib,'termr-source.rds'))
    if(problem=='payload') {
      dir.create(file.path(root,'R'))
      files<-list.files(file.path(phase_e_root,'R'),pattern='\\.R$',full.names=TRUE)
      file.copy(files,file.path(root,'R'))
      dir.create(file.path(lib,'termr'))
    }
    result<-processx::run(file.path(R.home('bin'),'Rscript'),
      c(file.path(phase_e_root,'integration-apps/run.R'),'--app=showcase','--mode=headless'),
      env=c('current',TERMR_PROJECT_ROOT=root),timeout=20,error_on_status=FALSE)
    expect_identical(result$status,1L)
    expected<-switch(problem,missing='install its current build',stale='build is stale',payload='payload differs')
    expect_match(result$stderr,expected)
  }
})

test_that('portable keyboard bindings perform operations and sort changes actual rows', {
  demo<-workbench_app(use_inkr=requireNamespace('inkr',quietly=TRUE))
  p<-termr::test_app(demo$app,width=110,height=32)
  on.exit({p$stop();demo$close()},add=TRUE)
  p$press('f11');expect_identical(demo$table$row_count,10000L)
  p$press('f11','f5');expect_lt(demo$table$row_count,32L)
  press_button(p,'sort')
  values<-demo$table$visible_data()$value
  expect_true(all(diff(values)<=0))
  p$press('f12');expect_identical(p$query_one('#pages')$active,2L)
  ids<-c('live-chart','scatter','bar','histogram','heatmap');bodies<-character()
  for(i in 1:5){
    p$query_one('#chart-tabs')$activate(i);p$step()
    region<-p$query_one(paste0('#',ids[[i]]))$region
    lines<-p$screen_text()[seq.int(region$y, length.out=region$height)]
    body<-substring(lines,region$x,region$x+region$width-1L)
    expect_true(any(grepl('[0-9]',body)))
    expect_gt(sum(nzchar(trimws(body))),2L)
    bodies[[i]]<-paste(body,collapse='\n')
  }
  expect_length(unique(bodies),5L)
})
