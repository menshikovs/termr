# Typed column support matrix

Support applies to in-memory `data.frame` and tibble columns. The optional
packages remain in `Suggests`.

| Column | Display | Edit | Sort/filter | Notes |
|---|---|---|---|---|
| logical | TRUE/FALSE/NA | strict logical tokens | supported | Base R |
| integer | decimal integer/NA | exact whole number in R integer range | supported | R reserves `-2147483648` as `NA_integer_` |
| double | fixed decimal; NA, NaN, +/-Inf distinct | strict decimal and special values | supported | Base R |
| character | text, empty string distinct from NA | text, explicit NA | supported | Base R |
| factor | level labels | existing levels only | supported | Factor level order preserved |
| ordered | level labels | existing levels only | supported | Ordered class and levels preserved |
| Date | ISO date | strict `YYYY-MM-DD` | supported | Invalid calendar dates rejected |
| POSIXct | pillar or base date-time format | local timestamp or explicit UTC offset | supported | Preserves `tzone`; DST gap/fold checks |
| difftime | duration | numeric text in source units | supported | Units attribute preserved |
| hms | pillar or base time | `HH:MM:SS[.fraction]` | supported | Requires optional `hms` to construct ordinary hms objects |
| bit64 integer64 | exact decimal text with `bit64` | exact integer text with `bit64` | supported | Never converts through double; read-only without `bit64` |
| list column | bounded scalar/type summary | no | equality, text and missing filters; no range sort | Nested values are not expanded |
| unsupported S3/S4 | base formatter if available | no | subject to base R methods | Read-only; no generic class restoration |

`pillar` is an optional formatter. Without it, the built-in types use bounded
base-R fallback formatting. `tibble`, `dplyr`, `vctrs`, `hms` and `bit64` add
class-specific behavior without becoming Imports.
