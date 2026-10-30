# Reactive state and lifecycle (Phase 3, section 2)

Scripts: `reactive-fuzz.R` (seeded model-based fuzz), `reactive-widgets.R` (widget-bound lifecycle), `p-unmount.R`.

## Model-based fuzz of signal / computed / watch / batch / dispose
- 600 seeds x 40 random operations (writes, 2-signal batches, computed and watch creation with random dependencies, dispose,
  reads). After every operation: every live computed equals the model value, every live watch last saw the final model state
  (glitch-free), and a disposed watch never runs again. **0 violations.**
- An earlier version of the fuzz that added watchers writing derived signals reported "violations"; they came from my model
  (derived signals were not tracked after disposal), not from termr, so that operation was removed from the random mix and
  replaced by a directed chain test.

## Directed cases (all behave as the header comment of `R/signals.R` describes)
| Case | Result |
|---|---|
| computed reading itself | error "Reactive cycle: computed -> computed" |
| two watches writing each other's input | error after a bounded number of runs (100) |
| diamond (a -> b, a -> c, watch reads b + c) | watcher sees only consistent states (4, 7, 10) |
| watch chain s -> t -> u | propagates (u = 11) |
| `dispose()` twice, write after dispose | no error, no run |
| signal written inside a computed | allowed (no error) |
| error thrown in a watch | propagates to the writer; later writes still work |
| watch writing its own dependency | runs once, is not re-triggered by its own write (observed semantics, consistent with "no self-trigger"; not a defect) |

## Widgets and the reactive graph
- A label bound with `label(function() sig())`: removing the label unsubscribes it (subscribers 1 -> 0).
- 200 bound-label mount/remove cycles leave **0** subscribers on the signal.
- Removing an ancestor of the button inside its own `button.pressed` handler, then posting a message: no error, the message is delivered once.
- A failing `unmount` handler on a removed widget propagates its error to the caller; on app exit unmount handlers are not run
  (observed; not treated as a defect).

Unconfirmed / not covered: event delivery to a component destroyed between `post()` and dispatch under heavy interleaving was
covered only by the removal-in-handler case above.
