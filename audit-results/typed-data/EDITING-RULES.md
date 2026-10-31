# Cell editing rules

1. Parse the input according to the column's adapter. A parser either produces
   one scalar of the target class or a user-readable error.
2. For factors, accept only existing labels. For integers, reject fractions
   and out-of-range values. For dates, validate both syntax and calendar date.
3. For local POSIXct text, use the column time zone. Reject nonexistent local
   times and require an explicit offset for ambiguous daylight-saving folds.
   Explicit offsets identify an instant; the result retains the column's
   `tzone` attribute.
4. Parse integer64 directly from decimal text through `bit64`; do not round-trip
   through an R double. Without `bit64`, keep integer64 columns read-only.
5. Cast to the zero-length prototype with public `vctrs::vec_cast()` when
   available, otherwise validate the supported scalar class in base R.
6. Build the candidate column with `vec_assign()` or base `[<-`. Before the
   table is updated, verify the candidate still has the original `typeof`,
   class and attributes. If parsing, validation, casting, or assignment fails,
   leave the original column unchanged.
7. Invoke `on_edit` before assignment. Return its accepted typed value through
   the existing change event only after the table commit succeeds.

List and unsupported object columns are read-only. List `NULL` and scalar NA
are recognized as missing for filtering while their display summaries remain
distinct.
