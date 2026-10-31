# Known limitations

* POSIXct parsing accepts the documented ISO-style timestamp forms. Locale-
  specific free-form dates and named-zone strings are not accepted.
* A local daylight-saving fold needs a numeric UTC offset to select an instant.
  Availability and exactness of historical zone rules follow the host's R and
  time-zone database.
* Integer64 parsing, exact display and exact profile counts require optional
  `bit64`. Without it, integer64 remains viewable via a safe placeholder and
  read-only.
* hms edit behavior is exercised only on hosts with optional `hms` installed.
* `pillar` changes presentation only. Base fallback formatting remains
  available but may be less compact for special classes.
* List summaries intentionally collapse nested objects to type/size labels;
  editing and range sorting list columns are unsupported.
* Arbitrary S3/S4 vectors are read-only. Their existing base formatter can
  display values, but arbitrary attributes are not guessed or reconstructed.
* Database/lazy sources have their own schema and edit callbacks. Their
  behavior depends on the source's declared column types and backend.
* WSL is currently blocked by the host returning `E_ACCESSDENIED`; a WSL test
  result must not be inferred from the Windows run.
