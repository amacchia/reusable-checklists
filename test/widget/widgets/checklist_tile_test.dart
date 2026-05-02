import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reusable_checklists/data/models/checklist.dart';
import 'package:reusable_checklists/data/models/checklist_item.dart';
import 'package:reusable_checklists/views/widgets/checklist_tile.dart';

void main() {
  group('ChecklistTile', () {
    testWidgets('displays checklist name', (tester) async {
      final checklist = Checklist(
        id: '1',
        name: 'Groceries',
        createdAt: DateTime(2024),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChecklistTile(
              checklist: checklist,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Groceries'), findsOneWidget);
    });

    testWidgets('displays checked count when items exist', (tester) async {
      final checklist = Checklist(
        id: '1',
        name: 'Groceries',
        createdAt: DateTime(2024),
        items: [
          ChecklistItem(id: 'a', title: 'Milk', sortIndex: 0, isChecked: true),
          ChecklistItem(id: 'b', title: 'Eggs', sortIndex: 1),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChecklistTile(
              checklist: checklist,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('1 / 2 checked'), findsOneWidget);
    });

    testWidgets('does not display subtitle when no items', (tester) async {
      final checklist = Checklist(
        id: '1',
        name: 'Groceries',
        createdAt: DateTime(2024),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChecklistTile(
              checklist: checklist,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('checked'), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      final checklist = Checklist(
        id: '1',
        name: 'Groceries',
        createdAt: DateTime(2024),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChecklistTile(
              checklist: checklist,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Groceries'));
      expect(tapped, true);
    });

    testWidgets('calls onLongPress on long press', (tester) async {
      var longPressed = false;
      final checklist = Checklist(
        id: '1',
        name: 'Groceries',
        createdAt: DateTime(2024),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChecklistTile(
              checklist: checklist,
              onTap: () {},
              onLongPress: () => longPressed = true,
            ),
          ),
        ),
      );

      await tester.longPress(find.text('Groceries'));
      expect(longPressed, true);
    });

    testWidgets('shows checkbox when in selection mode', (tester) async {
      final checklist = Checklist(
        id: '1',
        name: 'Groceries',
        createdAt: DateTime(2024),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChecklistTile(
              checklist: checklist,
              onTap: () {},
              isSelectionMode: true,
            ),
          ),
        ),
      );

      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('calls onSelectionTap when tapped in selection mode',
        (tester) async {
      var selectionTapped = false;
      var normalTapped = false;
      final checklist = Checklist(
        id: '1',
        name: 'Groceries',
        createdAt: DateTime(2024),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChecklistTile(
              checklist: checklist,
              onTap: () => normalTapped = true,
              isSelectionMode: true,
              onSelectionTap: () => selectionTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Groceries'));
      expect(selectionTapped, true);
      expect(normalTapped, false);
    });

    testWidgets('checkbox onChanged calls onSelectionTap', (tester) async {
      var selectionTapped = false;
      final checklist = Checklist(
        id: '1',
        name: 'Groceries',
        createdAt: DateTime(2024),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChecklistTile(
              checklist: checklist,
              onTap: () {},
              isSelectionMode: true,
              onSelectionTap: () => selectionTapped = true,
            ),
          ),
        ),
      );

      // Tap the Checkbox widget directly to trigger onChanged.
      await tester.tap(find.byType(Checkbox));
      expect(selectionTapped, true);
    });

    testWidgets('does not show checkbox in normal mode', (tester) async {
      final checklist = Checklist(
        id: '1',
        name: 'Groceries',
        createdAt: DateTime(2024),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChecklistTile(
              checklist: checklist,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(Checkbox), findsNothing);
    });
  });
}
