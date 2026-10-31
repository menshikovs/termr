# Security and input validation

No confirmed exploit/security P0 was found; this is not a proof of absence.
Only local non-destructive probes were performed, with no network attacks.

| Reachable input | Current boundary / evidence |
|---|---|
| Cell edit text | Strict type parsers/casts; stop('must not execute') rejected as integer text and data unchanged |
| Generated R source | Whitelisted values, language-object AST, escaped names, bounded source; tests evaluate generated output separately |
| SQL identifiers/filter values | DBI quoting and bound values in SQLite pagers; full SQL editor intentionally executes caller SQL |
| Worker command/closure | processx executes command/args without a shell; minimized closure capture rejects unsupported references/active bindings |
| Nano wire | Bounded raw JSON, schema/topic/version/depth checks; no R unserialize on network telemetry |
| Mirai job | Trusted local serialized R closure/args; not a sandbox for hostile code |
| Stylesheet | Local file/text/AST/compiled object; HTTP(S) URL input rejected; URLs in comments remain inert text |
| Binary cells | Eight-byte hex summary and bounded readonly inspector; raw bytes are never interpreted as UTF-8/ANSI |
| Visible text/labels | sanitize_text removes C0/C1 terminal controls; charts clean text; ScreenBuffer/ANSI output is centralized |
| Clipboard | OSC52 payload is encoded, not raw control text; exporter has source-size limits |

F06 demonstrates that legal control characters in column names also matter
to internal encodings, even though terminal text is sanitized. Its cache key
now uses lengths rather than an ambiguous separator. F09 shows a non-finite
count validation gap; this is malformed-input correctness, not an asserted
security vulnerability.

Remaining limits: arbitrary trusted callback/format/extractor R code can block
or have side effects; record-count limits do not bound arbitrary local payload
bytes; one very long subprocess line can exceed a line-count budget; selector
cache has no eviction. H2/H4 should use bounded adversarial fixtures before
classifying these as denial-of-service defects.
