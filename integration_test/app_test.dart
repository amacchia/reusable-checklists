import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:reusable_checklists/core/constants/app_strings.dart';
import 'package:reusable_checklists/data/models/checklist.dart';
import 'package:reusable_checklists/hive_registrar.g.dart';
import 'package:reusable_checklists/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await Hive.initFlutter();
    Hive.registerAdapters();
    final box = await Hive.openBox<Checklist>('checklists');
    await box.clear();
  });

  tearDown(() async {
    await Hive.close();
  });

  group('Full checklist lifecycle', () {
    testWidgets('create, add items, check, delete', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify empty state
      expect(find.text(AppStrings.emptyChecklists), findsOneWidget);

      // Create a checklist
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Groceries');
      await tester.tap(find.text(AppStrings.create));
      await tester.pumpAndSettle();

      // Verify checklist appears
      expect(find.text('Groceries'), findsOneWidget);

      // Open checklist
      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();

      // Verify detail screen
      expect(find.text(AppStrings.emptyItems), findsOneWidget);

      // Add items
      await tester.enterText(find.byType(TextField), 'Milk');
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Eggs');
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Bread');
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

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

      // Delete checklist
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Verify snackbar
      expect(find.text(AppStrings.checklistDeleted), findsOneWidget);
    });
  });

  group('Check All / Uncheck All', () {
    testWidgets('checks and unchecks all items', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Create checklist
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Tasks');
      await tester.tap(find.text(AppStrings.create));
      await tester.pumpAndSettle();

      // Open it
      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();

      // Add items
      await tester.enterText(find.byType(TextField), 'Task 1');
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Task 2');
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

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
