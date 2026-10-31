# Safe collector fixtures for reproducible comparisons and recordings.
# The rtop UI, state, formatting, controls and refresh loop are unchanged.
rtop_fixture_collectors <- function(env, root) {
  fixture <- file.path(root, 'tests/fixtures')
  sample <- env$read_proc_stat(file.path(fixture, 'proc-stat.txt'))
  env$collect_cpu <- function(...) list(sample = sample,
    usage = list(total = 40, cores = c(cpu0 = 20, cpu1 = 60)),
    load = c(.2, .3, .4), frequency_mhz = 2400, temperature_c = 45)
  memory <- env$collect_memory(file.path(fixture, 'meminfo.txt'))
  env$collect_memory <- function(...) memory
  counters <- env$read_net_dev(file.path(fixture, 'net-dev.txt'))
  env$collect_network <- function(...) list(counters = counters, interfaces = 'eth0',
    rates = list(eth0 = c(rx_rate = 1024, tx_rate = 2048, rx_total = 4096, tx_total = 8192)))
  env$collect_disks <- function(...) list(devices = list(), counters = list(), rates = list(),
    filesystems = data.frame(device = '/dev/demo', total = 1e9, used = 4e8, free = 6e8, percent = 40, mount = '/'))
  processes <- data.frame(pid = c(101, 102, 103), user = 'demo', name = c('alpha', 'beta', '東京'),
    cpu = c(10, 30, 5), mem = c(4, 2, 8), rss = c(1e6, 2e6, 3e6),
    state = c('S', 'R', 'S'), user_ticks = 1:3, system_ticks = 1:3)
  env$collect_processes <- function(...) list(data = processes,
    counters = processes[c('pid', 'user_ticks', 'system_ticks')])
  invisible()
}
