# A2.5 Known Limitations

- Geometry editing is intentionally read-only. Attribute editing is supported subject to each attribute type's existing typed-editing rules.
- Non-POINT geometry cells use structural summaries. Full WKT is available only as a bounded inspector preview, not an export mechanism.
- `sf` is optional. The Windows environment used for validation did not have it installed, so Windows sf-specific tests were skipped; WSL ran them with sf 1.0.24.
- CRS is presented as compact metadata. The DataTable does not transform coordinates, infer missing CRS, or edit CRS/precision.
- Performance figures are observational single runs. The PTY suite retains two failures in its unrelated combined Tab+Enter smoke case; all other exercised PTY checks passed.
