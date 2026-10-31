# Optional dependency

`inkr (>= 0.1.0)` is in `Suggests`; it is not loaded or imported when an app
does not specify `inkr_stylesheet`. Runtime calls resolve only exported
functions through `getExportedValue()`. Requesting a stylesheet without inkr
installed fails with an actionable install message. Existing styles, tests and
examples that do not opt into inkr do not require it.

Enabled tests used a temporary Windows library installed from the local
official inkr checkout and a temporary WSL library installed from the same
checkout. Optional-free focused tests were separately run with default
libraries where inkr is absent. The inkr checkout was not modified. No
C/C++/Rust code or system library was added to termr.
