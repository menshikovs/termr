# inkr integration and focused profiling

The sibling official checkout is inkr 0.1.0, HEAD 3a19331. termr calls exported
ink_parse/read/compile/element/compute/explain via guarded getExportedValue.
It does not reimplement inkr selector resolution or import private inkr code.
Existing RTCSS is a separate older language; the inkr result enters one
documented layer above RTCSS and below inline/state style. Explicit provenance
filters registry defaults so an empty sheet does not reset termr themes.

Focus/classes/parents/states form the path key. The per-App FIFO holds at most
4096 signature results, no Widget objects. The probe inserted 4100 unique
keys and observed exactly 4096. Replacement and unmount reset it; focused
tests cover class/id assignment, reparent, states, clear, transparency and
chart/DataTable paths.

Colors pass through idempotent termr normalization in the adapter/style
parser and capability downgrade in the renderer. This repeats validation,
not RGB-to-palette downgrade. Explicit transparent background is a named NULL
clearing a lower fill. L03: alpha declarations compile and replace the sheet,
then error when a matching widget is computed. Atomicity currently means
parse/compile/probe validation, not prevalidation of every termr mapping.

Profile evidence is in inkr-profile-summary.csv, inkr-micro-profile.csv and
the sampled profile-*-total/self.csv files. For 2000 widgets, one profiled
run took 0.83 s without inkr, 1.77 s with repeated paths (3 entries, 6096 bytes),
and 6.67 s with unique IDs (2002 entries, 4850088 bytes). Profiling overhead,
startup and scheduling mean these are diagnostic measurements, not a fresh
replacement for the previous 10000-widget benchmark.

For 1000 direct operations: element path construction 0.81 s; public compute
on a prebuilt element 0.97 s; bridge cache hit 0.26 s. A 100-widget tree walk
repeated 100 times took 0.06 s. In sampled unique-path CPU, bridge total was
77.34%, exported-call wrapper 57.91%, element construction 27.52%, color mapping
3.24%. These totals overlap: never add them. Mapping/bookkeeping remains in
bridge self time and is not independently measured as an entire stage.

Avoiding ink_session_* in 0.1.0 is supported by fresh evidence: sibling
insertion allocates 4.10 MB at 1000 nodes and 16.19 MB at 2000. The public
implementation's link_child in R/session-state.R:196 appends c(existing,key).
The bounded stateless path cache therefore avoids a measured quadratic cost.

L04: unmount code resets inkr caches even with no sheet. Removing 1000 siblings
without inkr allocated 33,096,000 bytes specifically below
inkr_reset_style_cache, out of 45,888,552 gross bytes. It is not a retention
leak, but it contradicts a performance reading of “unchanged optional-free
path.” H3 should guard unused cache work and separate state paint/layout
signatures before revisiting the external session API.
