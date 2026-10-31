# Resource ownership and lifecycle

| Resource | Creator/owner | Cleanup and failure boundary | Can outlive App? |
|---|---|---|---|
| Terminal driver/raw console state | App starts supplied driver | run() on.exit → shutdown → driver.stop; steps protected; F05 fixes unreturned Pilot startup | Forced OS termination remains outside guaranteed cleanup |
| POSIX reader process/PTY harness | Driver / Python Session respectively | kill_tree, stty restoration; harness wait/close handles sessions | Not intended |
| processx workers and temporary RDS/progress files | App; optional widget owner | completion/cancel/timeout and dispose-unmount; same-app moves preserve; stdout draining line-bounded | Retained Worker results can remain caller-owned |
| Widget timers/animation | Widget handles / App TimerManager | detach cancels widget timers; App shutdown cancels manager/animator | Inactive handles may remain but do not run |
| Signal effects | Widget reactive handles or caller | Widget disposal or explicit dispose | Yes when caller-owned; App stop is not blanket disposal of arbitrary user graphs |
| Stream listeners/history | Stream callback registry and caller subscription | Explicit unsubscribe/close; close stops further current dispatch | Yes by contract; dropping handle alone does not release callback |
| Chart stream binding | ChartWidget | dispose handle on unmount plus on_app_shutdown, active flag prevents late scheduled work | Stream itself is borrowed |
| Nano sockets/AIO | Publisher/subscriber transport | Explicit idempotent close, unsubscribe/cancel AIO; setup on.exit | Yes if caller intentionally keeps transport |
| Mirai compute profile/pull socket | Explicit pool | close/restart settle tasks and stop owned daemons only | Pool and result handles are caller-owned; runtime untested here |
| Shiny subscription/observer | Receiver; sessions acquire leases | Last session suspends; implicit receiver closes; shared owner explicitly closes | Shared receiver intentionally can |
| DataTable source/pages | Caller supplies source; table owns cache | Table$close explicitly invokes source close; switching does not own borrowed source | Yes, explicit protocol |
| DBI connection wrapper | Caller, ownership flag | disconnect only if owned or force; query source never owns | Borrowed resources must remain open |
| SQLEditor/DatabaseExplorer owned DB | Mounted widget shutdown hook | F08: hook is absent after remove, so later App shutdown misses it | Currently survives unexpectedly after removal |
| Arrow readers | No built-in reader created | User callback's responsibility | No built-in ownership contract exists |
| inkr cache | App | Bounded results; replace/unmount reset; no session/native resource | App object can retain bounded cache until GC |

Reference cycles by themselves are collectable in R. Observable retained roots
are decisive: F05 retained App in termr_env$apps; F08 left a real live owned DBI
connection after its automatic cleanup path disappeared. No native worker/socket
leak is claimed from static suspicion alone.

Close operations are often idempotent by flags and backend validity checks.
Error halfway through external close remains a fault-injection target, especially
mirai shutdown and nano socket/AIO close. Do not “fix” this by closing borrowed
DBI connections or shared Shiny/stream resources.
