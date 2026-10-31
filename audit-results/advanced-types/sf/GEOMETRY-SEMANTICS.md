# Geometry Semantics

| Input | Display | Editing | Missing / empty behavior |
|---|---|---|---|
| `sfc_POINT` | Bounded coordinate text | Read-only | Missing feature remains missing; empty is shown as empty |
| Other `sfc` geometry families | Type and structural counts | Read-only | `sfc` `is.na()` semantics; empty geometry is not missing |
| `sfg` in list-column | Bounded geometry summary | Read-only | `NULL` is displayed separately from empty geometry |
| `sf` attribute columns | Existing typed formatter | Existing type-specific edit rules | Row-aligned; geometry and metadata are retained |
| CRS | Compact EPSG/custom/NA label | Metadata only | No CRS is invented or assigned |

Supported geometry families are POINT, MULTIPOINT, LINESTRING, POLYGON, MULTILINESTRING, MULTIPOLYGON, and GEOMETRYCOLLECTION. Coordinate dimensions (XY, XYZ, XYM, XYZM), bbox, precision, and active geometry are surfaced as metadata. Geometry serialization is intentionally bounded; the table does not create full-column WKT strings.
