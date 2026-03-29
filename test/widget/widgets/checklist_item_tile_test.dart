import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reusable_checklists/data/models/checklist_item.dart';
import 'package:reusable_checklists/views/widgets/checklist_item_tile.dart';

void main() {
  group('ChecklistItemTile', () {
    Widget buildTile(ChecklistItem item,
        {VoidCallback? onToggle, VoidCallback? onDelete}) {
      return MaterialApp(
        home: Scaffold(
          body: ReorderableListView(
            onReorder: (a, b) {},
            children: [
              ChecklistItemTile(
                key: ValueKey(item.id),
                item: item,
                onToggle: onToggle ?? () {},
                onDelete: onDelete ?? () {},
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('displays item title', (tester) async {
      final item = ChecklistItem(id: '1', title: 'Buy milk', sortIndex: 0);
      await tester.pumpWidget(buildTile(item));

      expect(find.text('Buy milk'), findsOneWidget);
    });

    testWidgets('shows checkbox unchecked when not checked', (tester) async {
      final item = ChecklistItem(id: '1', title: 'Test', sortIndex: 0);
      await tester.pumpWidget(buildTile(item));

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, false);
    });

    testWidgets('shows checkbox checked when checked', (tester) async {
      final item = ChecklistItem(
          id: '1', title: 'Test', sortIndex: 0, isChecked: true);
      await tester.pumpWidget(buildTile(item));

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, true);
    });

    testWidgets('applies strikethrough when checked', (tester) async {
      final item = ChecklistItem(
          id: '1', title: 'Test', sortIndex: 0, isChecked: true);
      await tester.pumpWidget(buildTile(item));

      final text = tester.widget<Text>(find.text('Test'));
      expect(text.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('calls onToggle when checkbox tapped', (tester) async {
      var toggled = false;
      final item = ChecklistItem(id: '1', title: 'Test', sortIndex: 0);
      await tester.pumpWidget(buildTile(item, onToggle: () => toggled = true));

      await tester.tap(find.byType(Checkbox));
      expect(toggled, true);
    });

    testWidgets('calls onDelete when delete icon tapped', (tester) async {
      var deleted = false;
      final item = ChecklistItem(id: '1', title: 'Test', sortIndex: 0);
      await tester.pumpWidget(buildTile(item, onDelete: () => deleted = true));

      await tester.tap(find.byIcon(Icons.delete_outline));
      expect(deleted, true);
    });
  });
}
