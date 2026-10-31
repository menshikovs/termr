# Phase H2 Hardening Findings Matrix

| Finding ID | Severity | Subsystem | Description | Root Cause | Status |
|---|---|---|---|---|---|
| **H1-F01** | P1 | DataTable | Source switch failure leaves invalid active source | Sequential in-place mutation without rollback | **FIXED** |
| **H1-F02** | P1 | Reproducible Code | `pipeline` export differs from visual order after local edits | Unchecked assumption of sort/filter order invariance | **FIXED** |
| **H1-F08** | P1 | DBI / SQL | Owned DBI connection survives widget removal and App shutdown | Missing unmounting lifecycle disposal hook | **FIXED** |
| **H1-F09** | P2 | Core / Styles | `check_count(Inf)` accepted, corrupting runtime logging state | `check_count` lacked `is.finite()` and integer checks | **FIXED** |
| **H1-F04** | P2 | Event Dispatch | Detached ancestor receives ordinary bubbled messages mid-dispatch | Ancestor loop lacked active app boundary check | **FIXED** |
| **H1-F03** | P2 | Native Charts | Documented stream drain policy vs continuous burst starvation | Cooperative chunking yields to timer for drainage | **VERIFIED** |
| **H2-F05** | P3 | DataTable | Filter argument non-vector type produces unhelpful coercion warning | `DataTable$filter()` coerced character via `as.integer()` | **FIXED** |
| **H2-F06** | P3 | Focus Engine | Combined PTY write (`Tab + Enter`) requires dispatch-time focus resolution | Key events queued before focus change dispatch | **FIXED** |
| **H2-F07** | P3 | Security | ANSI escape codes in cell values could disrupt terminal driver | Sanitization in `table_parse_cell` strips escapes | **VERIFIED** |\n