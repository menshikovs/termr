# Memory and resource lifecycle

The fixed workload creates, starts, mounts, streams once, unbinds and closes
1,000 Apps. Every cycle asserts zero subscribers and a stopped App. Every 100
cycles a full gc() samples live Ncells/Vcells and open R connections. The same
script runs before and after; its observer retains one small result row per
sample, so tiny linear observer growth must not be called a product leak.

| Workload | Sample | Ncells used | Vcells used | R connections |
|---|---:|---:|---:|---:|
| before | 100 | 1445039 | 4104281 | 3 |
| before | 200 | 1445404 | 4105088 | 3 |
| before | 300 | 1445414 | 4105102 | 3 |
| before | 400 | 1445424 | 4105117 | 3 |
| before | 500 | 1445434 | 4105130 | 3 |
| before | 600 | 1445444 | 4105147 | 3 |
| before | 700 | 1445454 | 4105160 | 3 |
| before | 800 | 1445464 | 4105173 | 3 |
| before | 900 | 1445474 | 4105186 | 3 |
| before | 1000 | 1445484 | 4105207 | 3 |
| after | 100 | 1475742 | 4120634 | 3 |
| after | 200 | 1476107 | 4121441 | 3 |
| after | 300 | 1476117 | 4121455 | 3 |
| after | 400 | 1476127 | 4121470 | 3 |
| after | 500 | 1476137 | 4121483 | 3 |
| after | 600 | 1476147 | 4121500 | 3 |
| after | 700 | 1476157 | 4121513 | 3 |
| after | 800 | 1476167 | 4121526 | 3 |
| after | 900 | 1476177 | 4121539 | 3 |
| after | 1000 | 1476187 | 4121560 | 3 |

resource-cycles-windows.csv and resource-cycles-unix.csv add RSS snapshots (when optional ps is available), live
heap and connection counts during 100 repeated source/style cycles. Each cycle
performs five lazy-source switches and stylesheet apply/clear operations,
asserting source cache <=32 and a cleared App bridge cache. On WSL the same
resource runner also connects/closes 100 owned SQLite sources. DBI absence on
Windows is explicitly skipped. H2 tests verify borrowed/owned widget cleanup.

The new widget-local cache stores immutable inkr data rather than Widget/App
references and clears on unmount/sheet changes. The revised queue removes
event references on pop/clear and drops large empty hash storage. Gross
allocation reductions do not imply identical RSS savings: R's allocator may
retain a high-water mark. RSS samples are not peaks or leak proofs.

These finite runs establish bounded subscriber/cache/connection observations
in the tested workloads. They do not prove absence of every retained R6 cycle,
foreign allocation, OS handle, socket or worker-process leak. Dedicated
process/socket/handle census and long async/network soaks were not performed;
mirai/nanonext are unavailable. See H4-HANDOFF.md for explicit follow-ups.

## Rejected intermediate queue and final lifetime test

The first environment candidate used monotonically increasing binding names.
At 50,000 push/pop operations with only one pending item it retained 152,001
additional Ncells and used live key 50,001. This was introduced during H3 and
rejected before completion; it is not a claim about the initial H2 list queue.
The final growable ring reuses names within capacity. The same test stays
within 64 slots and records 2,263 additional Ncells at 50,000 operations;
from 10,000 onward almost all small growth is the retained observer rows.
queue-lifetime-before-ring.csv and queue-lifetime-after-ring.csv preserve all
ten samples. A regression keeps the queue non-empty for 10,000 operations and
also checks growth while the FIFO wraps across the end of its storage.

R environment bindings use symbols and hashed storage; this explains why
bounding live queue length alone was insufficient for the first candidate.
See the primary [R Internals manual, environments/hash tables](https://stat.ethz.ch/CRAN/doc/manuals/r-release/R-ints.html#Environments-and-variable-lookup).
Our retained-memory finding comes from the observed current-R experiment;
it is not inferred solely from RSS or the manual.
