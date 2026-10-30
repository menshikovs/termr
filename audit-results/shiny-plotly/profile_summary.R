profile <- commandArgs(trailingOnly = TRUE)[[1L]]
result <- summaryRprof(profile)
print(head(result$by.self, 20))
print(head(result$by.total, 20))
