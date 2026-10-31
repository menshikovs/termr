source('integration-apps/bootstrap.R')
path<-'audit-results/real-world-apps/packages-unix.csv'
initial<-'audit-results/real-world-apps/packages-unix-initial.csv'
if(!file.exists(initial))file.copy(path,initial)
source('audit-results/real-world-apps/inventory.R')
