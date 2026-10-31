# Security Probes & Fault Injection

Phase H2 conducted focused security audits against potential injection vectors:

## 1. R Code Injection via Table Column Names
- Probed: Data frame with column name `col`; system('touch /tmp/termr_pwned'); `.
- Result: Code generation safely enclosed the column name in `[["col\`; system("touch /tmp/termr_pwned"); \`"]]`. Evaluation of the generated expression in a clean environment executed safely with zero shell command execution.

## 2. Terminal Escape Sequence Injection
- Probed: Cell values containing `\033[2J` (clear screen), `\033[H` (cursor home), `\033]0;title\007` (OSC set title).
- Result: `table_parse_cell()` sanitizes raw control characters, stripping escape bytes and preventing terminal corruption.

## 3. Exploding S3 Class Fault Injection
- Probed: Custom S3 class whose `format()` method throws an error.
- Result: Caught gracefully by display formatters; table rendering displays fallback representation without crashing the event loop.\n