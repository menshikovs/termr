# A2.5 Architecture

Spatial handling is integrated into the existing typed-data adapter and DataTable rendering/editing paths. `sf` remains optional; the registry recognizes `sfc`, `sfg`, and sampled list-columns containing `sfg` without making `sf` a hard dependency.

Formatting is on demand for requested visible values. POINT cells use a bounded single-feature WKT representation; other geometry cells use structural summaries (coordinate, ring, line, polygon, or geometry-collection counts) rather than serializing full geometry. The inspector is generated when a row is activated and caps its WKT preview at 64 coordinates and 120 characters.

Geometry adapters are read-only and do not participate in sorting. Attribute edits use a dedicated row-preserving replacement path: a local copy is modified, original top-level `sf` attributes are restored, and geometry column identity, row count, names, and class are checked. This avoids `[[<-` changing the `agr` metadata while preserving the active geometry and row alignment.

No public exports were added. `NAMESPACE` is unchanged. `sf` was added to `Suggests` and documentation was regenerated from roxygen source.
