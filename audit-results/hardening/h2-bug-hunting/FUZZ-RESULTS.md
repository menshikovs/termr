# Fuzz Testing Results

Bounded, fixed-seed fuzz testing was implemented in `tests/testthat/test-h2-adversarial-security.R` to probe parser boundaries and input validation routines.

## 1. Stylesheet Parser Fuzzing (`as_stylesheet`)
- **Generator**: 50 pseudo-random strings composed of CSS tokens, delimiters, brackets, colons, semicolons, quotes, and punctuation.
- **Outcome**: The parser successfully either parsed valid structures or threw catchable errors. No unhandled crashes, segmentation faults, or infinite loops occurred.

## 2. Query Selector Fuzzing (`App$query`)
- **Generator**: 50 pseudo-random selector strings composed of `#`, `.`, `:`, `>`, `*`, `[`, `]`, `=`, quotes, and alphanumeric characters.
- **Outcome**: All malformed selectors either threw clean errors or returned empty matches. No internal state corruption occurred.

## 3. Stability Summary
All fuzz tests ran deterministically under seed `12345` and `54321`, ensuring 100% reproducibility in CI environments.\n