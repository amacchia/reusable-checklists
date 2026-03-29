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
              onDelete: () {},
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
              onDelete: () {},
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
              onDelete: () {},
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
              onDelete: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Groceries'));
      expect(tapped, true);
    });

    testWidgets('calls onDelete when delete icon tapped', (tester) async {
      var deleted = false;
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
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      expect(deleted, true);
    });
  });
}
