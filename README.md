# Reusable Checklists

A minimalist Flutter app for creating and managing reusable checklists.

## Features

- Create, delete, and manage multiple named checklists
- Add, remove, check/uncheck, and reorder items via drag-and-drop
- Bulk actions: check all / uncheck all items
- Delete with undo support
- Visual progress indicators (e.g., "1 / 3 checked")
- Light, dark, and system theme modes
- Local-first storage — all data persists across sessions

## Tech Stack

- **Flutter** (Dart 3.11.4+) with Material 3
- **Provider** for state management
- **Hive CE** for local NoSQL storage
- **SharedPreferences** for settings
- **MVVM** architecture

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.11.4+)

### Setup

```bash
# Install dependencies
flutter pub get

# Run code generation (Hive adapters)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

## Project Structure

```
lib/
  data/
    models/          # Hive-serialized data models
    repositories/    # Abstract + concrete persistence layers
  viewmodels/        # ChangeNotifier ViewModels
  views/
    screens/         # Full-page screens
    widgets/         # Reusable UI components
  constants/         # App strings and theme config
  app.dart           # App widget, routing, and theme setup
  main.dart          # Entry point and provider configuration
```

## Testing

```bash
# Run unit and widget tests
flutter test

# Run integration tests
flutter test integration_test

# Run tests with coverage
flutter test --coverage
```

Tests cover models, repositories, viewmodels, widgets, and screens using `mocktail` for mocking. Integration tests exercise full end-to-end workflows.

