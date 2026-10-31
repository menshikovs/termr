# Typed Data Foundation

Resolution order in table_type_handlers is explicit: blob, sfc/sfg/list<sfg>,
raw/list<raw>, integer64, units, haven SPSS/labelled, hms, ordered/factor,
POSIXct, Date, difftime, bare atomic/list, then extension and unsupported.
Therefore generic vctrs capability does not override stricter geometry,
binary or labelled handlers. Metadata uses a zero-length prototype; display
formats slices, not the whole column. Scalar edits cast before assignment,
then verify storage, class and attributes.

| Type | Display / inspect | Edit | Preservation / current evidence |
|---|---|---|---|
| Bare logical/integer/double/character | Native typed formatting and column_info | Strict scalar parser | Windows/WSL typed regressions; injection text rejected without mutation |
| Factor/ordered | Levels and compact type | Existing levels only | Levels/order/class invariant tests |
| Date/POSIXct/difftime/hms | Typed formatting/timezone metadata | Strict date/time and explicit offset contract | DST ambiguity/nonexistent-time tests in full suites where optional hms is present |
| integer64 | Exact decimal path | Requires bit64 | WSL bit64 4.6.0.1 tests; absent on Windows |
| units | Unit metadata and visible formatting | Optional units conversion, round-trip checks | WSL units 1.0.0 tests; class/unit/offset-temperature preservation; Windows absent |
| haven_labelled / spss | Raw/label modes, tagged NA and user-missing metadata | Valid integer/double/character metadata only | WSL haven 2.5.5; absent-mode Windows tests |
| raw / list<raw> / blob | Bounded hex summaries and readonly inspector | Read-only | Raw/control tests on both; WSL blob 1.3.0 and binary PTY |
| sf / sfc / sfg | Geometry/CRS summary and bounded selected-cell inspection | Geometry read-only; ordinary sf attributes can edit | WSL sf 1.0.24 tests; active geometry/CRS/class checked |
| Generic S3/vctrs | Validated pillar/format fallback | Only verified text-to-prototype casts | Class-specific checks and readonly failure; arbitrary methods remain trusted R code |
| Period/Duration/Interval | Generic extension, not dedicated calendar display | Read-only | WSL lubridate 1.9.5: S4 TRUE, extension handler, editable FALSE for all three |

A2.3 is not implemented as a specialized typed handler. No lubridate dependency
or Period/Duration/Interval parser exists in the typed source. The separate A4
value exporter recognizes these S4 classes; the three WSL sample values
round-trip identically through generated methods::new code. That is not proof
of calendar editing, DST semantics or the complete A2.3 test matrix.

Optional absence is guarded; unsafe extension types stay read-only. Scalar
editing may copy the R vector under copy-on-modify, an expected O(n) allocation,
without converting all values. List-type inference samples up to 1000 edges,
so unusual middle-only raw/geometry cells may use the generic safe summary.
Huge single geometries and custom format methods remain H3 profiling targets.
