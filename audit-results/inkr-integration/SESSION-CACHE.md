# Cache design and inkr sessions

Each app owns a bounded FIFO cache of at most 4096 distinct selector-path
results. The key includes the active sheet generation and the root-to-widget
type, id, class and state values. The value contains the mapped partial
`termr_style` and compact per-property declaration flags. Widgets with the
same path signature reuse one entry; the cache does not retain widget objects.

The public inkr `ink_session_*` API was evaluated and intentionally not used in
version 0.1.0. Its session state stores child keys by repeatedly assigning
`c(existing_children, new_key)` in `ink_session_set()`. For a wide parent this
copies a growing vector on each sibling insertion and has quadratic allocation
cost. The public stateless `ink_compute()` API is used on cache misses instead.
Termr's widget style cache plus selector-path cache avoids recomputing
unchanged widgets on subsequent focus or class transitions.

Cache misses build the public `ink_element()` path. Cache capacity is bounded;
stylesheet replacement and widget unmount reset the cache. A per-property
provenance vector is cached in termr's existing style-epoch cache so inherited
values can be distinguished from inkr registry defaults.
