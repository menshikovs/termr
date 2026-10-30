# Known limitations

- API and demo transport are experimental. The core is synchronous: slow
  callbacks delay the publisher. Reentrant emit on the same stream is rejected.
  Callback errors become one warning after dispatch, not a retained error log.
- Event count, not payload bytes, bounds history. Reference objects are shared;
  callers must treat published values as immutable. Subscribe handles require
  explicit cleanup. Close preserves retained events until clear or collection.
- The transport is local latest state, single writer, no durable event log,
  replay, fsync/power-loss guarantee, authentication or remote endpoints.
  Consumers can miss observations; sequence gaps after the first sample are
  counted. A consumer restart loses its own in-memory history.
- Old snapshot versions are pruned before publication. If file access prevents
  pruning, publication reports an error and waits for access recovery, keeping
  the file count bounded. This can make consumers stale until the cause clears.
- Publication relies on same-filesystem rename to a fresh name. Temporary
  files are never selected; cleanup races retry. Network shares, synchronized
  folders, arbitrary Windows/WSL shared mounts and crash/power-loss behavior
  were not certified. Hard kills may leave a lock/pending file requiring manual
  cleanup after confirming the writer is dead. Normal stop/interrupt closes.
- The first CPU observation is unavailable; subsequent observations are
  cumulative system CPU deltas. Linux/WSL values describe that environment,
  not necessarily the entire Windows host. Permission-denied process fields
  are null; collection is synchronous and process lists are capped at 100.
- Staleness uses wall-clock timestamps and assumes agreement among local
  processes. Future timestamps beyond five seconds are rejected. There is no
  network clock synchronization or source liveness heartbeat beyond samples.
- Windows lacks optional DBI, RSQLite and Shiny in the available R library.
  Their tests skip there. WSL has these integrations available and exercises
  Shiny server logic, independent Shiny child sessions and actual loopback HTTP.
- TUI tests use the real termr headless loop/renderer. No new interactive
  Windows console, manual browser session or manual SSH/terminal-host
  certification is claimed. No system software was installed for validation.
- R CMD check runs without PDF manual generation (--no-manual). This does not
  establish TeX/manual rendering or CRAN incoming/network validation.
