# Phase E — Asciinema

Four local real-terminal recordings were created with asciinema 2.4.0 in WSL:

| Application | Recording | Exit | Terminal restored |
| --- | --- | --- | --- |
| showcase | final-recordings/recording/showcase.cast | 0 | True |
| analytics | final-recordings/recording/analytics.cast | 0 | True |
| monitor | final-recordings/recording/monitor.cast | 0 | True |
| rtop | final-recordings/recording/rtop.cast | 0 | True |


Final unified recording runner exits0. Recordings demonstrate actual keyboard
actions and redraws, not generated animations or screenshots. The monitor uses
real workers and transport. rtop recording uses deterministic fixture collectors;
live user process/network data is never recorded. The cast headers/output were
scanned for user home paths, User001, Bearer/password/token markers and matched
none of those checks. This bounded deny-list is not a universal secret detector.
Nothing was uploaded or published.

Play locally: `asciinema play audit-results/real-world-apps/final-recordings/recording/showcase.cast`.
The adjacent JSONL markers and PTY logs supply assertions independently of the
recording. One earlier all-app recording hit transient errno61 for rtop; its
failed result remains in `recordings/results.json`. A standalone retry and the
final all-app recording passed; recorder portability remains an H4/tooling risk.
