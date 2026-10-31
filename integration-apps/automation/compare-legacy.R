out<-'audit-results/real-world-apps'
baseline<-readRDS(file.path(out,'rtop-baseline.rds'))
candidate<-readRDS(file.path(out,'rtop-candidate.rds'))
stopifnot(identical(names(baseline),names(candidate)))
rows<-lapply(names(baseline),function(name){
  x<-baseline[[name]];y<-candidate[[name]]
  data.frame(scenario=name,values_equal=identical(x$rows,y$rows),
    screen_equal=identical(x$text,y$text),state_equal=identical(x,y))
})
result<-do.call(rbind,rows)
write.csv(result,file.path(out,'rtop-comparison.csv'),row.names=FALSE)
jsonlite::write_json(list(scenarios=result,status=if(all(result$state_equal))'PASS' else 'DIFFERENCES',
  normalization='Only wall-clock HH:MM:SS replaced with <CLOCK>; original UI and fixture data retained'),
  file.path(out,'rtop-comparison.json'),auto_unbox=TRUE,pretty=TRUE)
print(result)
if(!all(result$values_equal))quit(status=1L)
