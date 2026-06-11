# AGENTS.md

## Commands

```bash
flutter pub get                              # install deps
dart run build_runner build --delete-conflicting-outputs  # regenerate Hive adapters
flutter test                                  # unit + widget tests
flutter test integration_test                 # e2e tests
flutter test --coverage                      # tests with coverage
dart analyze --fatal-infos                    # lint (CI uses this)
dart format .                                 # Format codebase
```

Always run codegen **before** analyzing or testing after model changes.

## Architecture

- **MVVM** with Provider (ChangeNotifier) for state management
- **Hive CE** for local NoSQL persistence — models use `@HiveType`/`@HiveField` annotations; generated `.g.dart` files are committed
- **SharedPreferences** for theme settings
- Entrypoint: `lib/main.dart` — initializes Hive, opens `checklists` box, wires `MultiProvider`

### Key paths

| Layer | Directory |
|---|---|
| Models | `lib/data/models/` — `checklist.dart`, `checklist_item.dart` |
| Repositories | `lib/data/repositories/` — abstract interface + Hive impl |
| ViewModels | `lib/viewmodels/` — `*_viewmodel.dart` (ChangeNotifier) |
| Views | `lib/views/screens/`, `lib/views/widgets/` |
| Constants | `lib/core/constants/` — theme, strings, breakpoints |
| Navigation | `lib/core/navigation/route_observer.dart` |
| Hive adapter registry | `lib/hive_registrar.g.dart` |

### Adaptive layout

The app uses `AdaptiveLayoutShell` with a master-detail pattern (`ChecklistMasterDetailScreen`) on wide screens and separate screens on narrow. Route: `/detail` takes a `String` checklist ID as argument.

## Generated files

- `*.g.dart` files are **committed** and must be regenerated when Hive models change
- `HiveType.typeId` values: `Checklist` = 0, `ChecklistItem` = 1

## Testing

- Structure: `test/unit/` (models, repos, viewmodels) and `test/widget/` (screens, widgets, main)
- Mocking: `mocktail`
- **CI enforces ≥95% line coverage** — `flutter test --coverage` + lcov check
- Always write tests for new code added

## Lint rules

Uses `flutter_lints` with strict analysis (`strict-casts`, `strict-inference`, `strict-raw-types`). Key enforced rules: `prefer_single_quotes`, `require_trailing_commas`, `use_super_parameters`, `sort_child_properties_last`, `avoid_dynamic_calls`. Run `dart analyze --fatal-infos` before committing.