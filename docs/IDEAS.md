# Improvement Ideas

Backlog of suggestions from a code review. Rename checklist, edit item, error surfacing, undo on item delete, reorder checklists, and JSON export/import are already shipped — everything below is open.

## Closest to MVP gaps

- **Duplicate a checklist.** Core value prop of "reusable" is running a known-good list again. Today the reuse story is just "uncheck all" — cloning lets you keep a canonical template untouched while running a copy.

## UX polish

- **Swipe-to-delete or swipe-to-check on item tiles.** Faster than hunting for the trash icon; complements (doesn't replace) the explicit buttons.
- **Empty-state CTAs that actually trigger the action** rather than just describing it ("Tap + to create one" → tappable button).

## Features that fit the "reusable" identity

- **Templates / categories.** Tag a checklist as "Travel" etc., browse/clone from a templates view.
- **Item quantity or notes.** Optional subtitle on items, or `2×` prefix — makes it viable as a shopping/grocery list.
- **Reset-on-open or "start new run"** — a more intentional workflow than "uncheck all," optionally archiving the completed run.

## Technical

- **Possible reorder bug in `checklist_detail_screen.dart`** — `ReorderableDragStartListener` uses `item.sortIndex` (global across checked + unchecked), but `SliverReorderableList` expects the index within its own `itemCount` (unchecked only). When any item is checked, those indices diverge and drags will misbehave. Worth a focused test with a mixed list.
- **Full-checklist write per toggle.** `toggleItem` / `addItem` rewrite the whole `Checklist` via `saveChecklist`. Fine now; won't scale to 500-item lists.
- **`sortedItems` recomputes every access** (sort + new list). Detail screen calls it several times per build via `uncheckedItems` / `checkedItems`. Cheap memoization on the VM would help.
- **No crash reporting / analytics.** Sentry or Firebase Crashlytics in 20 minutes pays for itself the first time a user hits an edge case.
