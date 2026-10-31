# Adversarial State Machine Testing

## 1. DataTable State Machine

A state machine test harness was constructed in `tests/testthat/test-h2-state-machine.R`. The test subjects a `DataTable` widget to a randomized sequence of 40 state-mutating actions:
- `sort_asc`: Sort by numeric column ascending.
- `sort_desc`: Sort by numeric column descending.
- `filter_rows`: Apply random subset row index filter.
- `filter_clear`: Reset filter to full view.
- `edit_cell`: Update text cell at cursor position.
- `scroll_row`: Scroll viewport to random row index.
- `goto_row`: Move cursor and scroll to random row index.
- `select_row`: Set active selection range.
- `fail_source_switch`: Attempt replacement with a failing backend source.
- `ok_source_switch`: Replace with a valid new schema source.
- `repro_export`: Export reproducible pipeline code.

### Invariants Enforced After Every Transition
1. **Data Frame Integrity**: `dt$data` remains a non-empty `data.frame`.
2. **Cursor Bounds**: Cursor row is within $[1, \max(1, \text{total\_rows})]$; cursor column is within $[0, \text{ncol}]$.
3. **Selection Bounds**: Selection positions reference valid row indices within the active view.
4. **Render Stability**: `dt$render()` evaluates without throwing an error.

---

## 2. App & Widget Tree Lifecycle State Machine

Transitions evaluated:
1. **Dynamic Mounting & Removal**: Removing a widget detaches its parent reference, clears its app reference, and removes it from descendants.
2. **Focus Hand-off on Removal**: Removing the currently focused widget causes `FocusManager` to mark focus lost and automatically transfer focus to the next eligible neighbour in tree order during the next event loop tick.
3. **Reparenting**: Moving a widget to another container within the same app updates parent references without stranding event bindings.
4. **Disabled Subtree Traversal**: Disabling a container dynamically disables all descendant widgets. Keyboard tab navigation automatically skips disabled widgets and wraps correctly.
5. **Timer Cleanup**: Widget timers (`set_timeout`) registered on a widget are cancelled when the widget is unmounted, preventing memory leaks and orphaned callbacks.\n