# termr: modern reactive terminal applications for R

Build modern terminal applications with first-class support for data
workflows: composable widgets and layouts, reactive state, events,
keyboard and mouse input, themes, and background R workers.

## Details

A virtual framebuffer and incremental rendering send changed cells to
the terminal.
[`test_app()`](https://menshikovs.github.io/termr/reference/test_app.md)
drives the same event loop and renderer headlessly.
[`data_table()`](https://menshikovs.github.io/termr/reference/data_table.md)
and
[`data_browser()`](https://menshikovs.github.io/termr/reference/browse_data.md)
support data inspection;
[`table_source()`](https://menshikovs.github.io/termr/reference/table_source.md)
adds lazy paging. Optional DBI integrations provide SQL and database
workflows, and
[`render_text()`](https://menshikovs.github.io/termr/reference/render_text.md),
[`render_html()`](https://menshikovs.github.io/termr/reference/render_html.md)
and related helpers export static output without a terminal.

Start with
[`app()`](https://menshikovs.github.io/termr/reference/app.md), the
widget constructors
([`vertical()`](https://menshikovs.github.io/termr/reference/vertical.md),
[`horizontal()`](https://menshikovs.github.io/termr/reference/vertical.md),
[`label()`](https://menshikovs.github.io/termr/reference/label.md),
[`button()`](https://menshikovs.github.io/termr/reference/button.md),
[`input()`](https://menshikovs.github.io/termr/reference/input.md)) and
[`run()`](https://menshikovs.github.io/termr/reference/run.md). Advanced
applications can use
[`signal()`](https://menshikovs.github.io/termr/reference/signals.md),
[`run_worker()`](https://menshikovs.github.io/termr/reference/run_worker.md),
[`sql_editor()`](https://menshikovs.github.io/termr/reference/sql_editor.md)
and
[`db_explorer()`](https://menshikovs.github.io/termr/reference/db_explorer.md).
These APIs, lazy sources, static export and custom extensions remain
experimental; see the repository's API stability guide for the complete
classification.

## See also

Useful links:

- <https://github.com/41929424/termr>

- Report bugs at <https://github.com/41929424/termr/issues>

## Author

**Maintainer**: Akims Mensikovs <akimm7926@gmail.com> \[copyright
holder\]

Authors:

- Akims Mensikovs <akimm7926@gmail.com> \[copyright holder\]
