import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:reusable_checklists/core/constants/app_strings.dart';
import 'package:reusable_checklists/data/models/checklist.dart';
import 'package:reusable_checklists/hive_registrar.g.dart';
import 'package:reusable_checklists/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps until [finder] finds at least one widget, or times out.
Future<void> waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 50; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  await tester.pumpAndSettle();
}

/// Starts the app with a clean database.
Future<void> startApp(WidgetTester tester) async {
  // Fresh box for each test so cases stay hermetic.
  final box = Hive.box<Checklist>('checklists');
  await box.clear();

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(MainApp(prefs: prefs));
  await tester.pumpAndSettle();
}

/// Creates a checklist from the list screen via the FAB + dialog.
Future<void> createChecklist(WidgetTester tester, String name) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), name);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
  // Wait for async createChecklist to complete and list to rebuild.
  await waitFor(tester, find.text(name));
}

/// Opens a checklist by name and waits for the detail screen to load.
Future<void> openChecklist(WidgetTester tester, String name) async {
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
  // Wait for async loadChecklist to resolve (spinner disappears, add bar appears).
  await waitFor(tester, find.text(AppStrings.addItem));
}

/// Adds an item on the detail screen using the keyboard submit action.
Future<void> addItem(WidgetTester tester, String text) async {
  // Tap the TextField to ensure it has focus and a text input connection.
  await tester.tap(find.byType(TextField));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
  // Wait for the item to appear in the list.
  await waitFor(tester, find.text(text));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Hive.initFlutter();
    Hive.registerAdapters();
    await Hive.openBox<Checklist>('checklists');
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('Full checklist lifecycle', () {
    testWidgets('create, add items, check, delete', (tester) async {
      await startApp(tester);

      // Verify empty state
      expect(find.text(AppStrings.emptyChecklists), findsOneWidget);

      // Create a checklist
      await createChecklist(tester, 'Groceries');
      expect(find.text('Groceries'), findsOneWidget);

      // Open checklist
      await openChecklist(tester, 'Groceries');

      // Add items
      await addItem(tester, 'Milk');
      await addItem(tester, 'Eggs');
      await addItem(tester, 'Bread');

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Eggs'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);

      // Check an item
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      // Go back
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Verify count badge
      expect(find.text('1 / 3 checked'), findsOneWidget);

      // Long-press checklist to enter selection mode
      await tester.longPress(find.text('Groceries'));
      await tester.pumpAndSettle();

      // Delete selected checklist
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Verify snackbar
      expect(find.text(AppStrings.checklistDeleted), findsOneWidget);
    });
  });

  group('Check All / Uncheck All', () {
    testWidgets('checks and unchecks all items', (tester) async {
      await startApp(tester);

      // Create checklist
      await createChecklist(tester, 'Tasks');

      // Open it
      await openChecklist(tester, 'Tasks');

      // Add items
      await addItem(tester, 'Task 1');
      await addItem(tester, 'Task 2');

      // Check All
      await tester.tap(find.text(AppStrings.checkAll));
      await tester.pumpAndSettle();

      // Verify all checked
      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
      for (final cb in checkboxes) {
        expect(cb.value, true);
      }

      // Uncheck All
      await tester.tap(find.text(AppStrings.uncheckAll));
      await tester.pumpAndSettle();

      // Verify all unchecked
      final uncheckedBoxes =
          tester.widgetList<Checkbox>(find.byType(Checkbox));
      for (final cb in uncheckedBoxes) {
        expect(cb.value, false);
      }
    });
  });
}
