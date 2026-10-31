# Known limitations

- One inkr stylesheet is active per app. Replace it to switch stylesheets;
  compiled stylesheet merging is not provided by inkr's public API.
- Only inkr's eight built-in properties are mapped. Custom registry properties
  remain available to inkr but have no termr meaning.
- Alpha colors are rejected. The termr framebuffer stores opaque terminal
  colors and has no compositing contract.
- Inkr width/height support is fixed cells or `auto`; termr-only `fr`, percent
  and min/max sizing are not expressible in inkr.
- Inkr compile-time variables are not linked to termr semantic theme tokens.
  Switch paired themes by replacing both the termr theme and inkr sheet.
- The cache is bounded to 4096 selector-path signatures. Very large trees with
  unique IDs can evict entries and recompute styles on later global style
  invalidations; behavior remains correct.
- The checked inkr API source is version 0.1.0. Future inkr API or performance
  changes require compatibility review and updated tests.
