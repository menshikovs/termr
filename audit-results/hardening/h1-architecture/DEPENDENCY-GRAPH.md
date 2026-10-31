# Dependency and control graph

~~~mermaid
flowchart TD
  Driver[POSIX / Windows / Headless driver] -->|input| App
  App --> Queue[EventQueue / timers / focus]
  Queue -->|dispatch| Tree[Screen and Widget tree]
  Tree --> Styles[RTCSS + optional inkr + inline]
  Styles --> Layout
  Tree --> Layout
  Layout --> Paint[Compositor and widget paint]
  Paint --> Buffer[ScreenBuffer / dirty rectangles]
  Buffer --> Renderer
  Renderer -->|ANSI writes| Driver
  Signal[Global reactive graph] -->|invalidation| Tree
  Tree --> Table[DataTable]
  Table --> Typed[Typed adapters]
  Table --> Sources[table_source callbacks]
  Sources --> SQLite[DBI / SQLite pagers]
  Table --> Code[Bounded R AST generation]
  Tree --> Charts[ChartWidget / plans / SelectionRegion]
  Stream[termr_stream] --> Charts
  Stream --> Nano[Optional nanonext transport]
  Nano --> Stream
  Mirai[Optional isolated mirai pool] -->|metadata| Stream
  Stream --> Shiny[Optional Shiny receiver]
  Shiny --> Plotly[Example Plotly / ggplot views]
  App --> Worker[processx Worker]
~~~

Runtime Imports are codetools, grDevices, graphics, methods, R6, processx, ps,
stats and utils. inkr, DBI/RSQLite, vctrs/pillar and all telemetry/chart-browser
integrations are optional. Native charts need only existing runtime Imports.
Mirai's optional runtime additionally requires nanonext and jsonlite.

Mutable namespace state: termr_env stores active Apps, style/layout epochs and
profiling state; rx stores the active observer, pending effects and IDs.
size_cache is capped at 512 entries; selector_cache is a global environment
without eviction; per-widget caches are epoch/revision based. inkr's per-App
cache is capped at 4096 entries. Source caches cap at 32 pages of up to 100 rows
each, not a fixed byte budget.

Internal callbacks carry unavoidable reverse edges (Widget → App events,
source fetch → caller code, worker completion → App). Detach and shutdown must
explicitly unlink them. See RESOURCE-LIFECYCLE.md rather than treating all
callback cycles as leaks.
