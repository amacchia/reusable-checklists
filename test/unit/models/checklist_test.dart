import 'package:flutter_test/flutter_test.dart';
import 'package:reusable_checklists/data/models/checklist.dart';
import 'package:reusable_checklists/data/models/checklist_item.dart';

void main() {
  group('Checklist', () {
    test('creates with empty items by default', () {
      final checklist = Checklist(
        id: '1',
        name: 'Test',
        createdAt: DateTime(2024),
      );
      expect(checklist.items, isEmpty);
    });

    test('creates with provided items', () {
      final items = [
        ChecklistItem(id: 'a', title: 'Item 1', sortIndex: 0),
      ];
      final checklist = Checklist(
        id: '1',
        name: 'Test',
        createdAt: DateTime(2024),
        items: items,
      );
      expect(checklist.items.length, 1);
    });

    group('checkedCount', () {
      test('returns 0 when no items checked', () {
        final checklist = Checklist(
          id: '1',
          name: 'Test',
          createdAt: DateTime(2024),
          items: [
            ChecklistItem(id: 'a', title: 'A', sortIndex: 0),
            ChecklistItem(id: 'b', title: 'B', sortIndex: 1),
          ],
        );
        expect(checklist.checkedCount, 0);
      });

      test('returns correct count when some items checked', () {
        final checklist = Checklist(
          id: '1',
          name: 'Test',
          createdAt: DateTime(2024),
          items: [
            ChecklistItem(id: 'a', title: 'A', sortIndex: 0, isChecked: true),
            ChecklistItem(id: 'b', title: 'B', sortIndex: 1),
          ],
        );
        expect(checklist.checkedCount, 1);
      });

      test('returns 0 when items list is empty', () {
        final checklist = Checklist(
          id: '1',
          name: 'Test',
          createdAt: DateTime(2024),
        );
        expect(checklist.checkedCount, 0);
      });
    });

    group('isAllChecked', () {
      test('returns false when empty', () {
        final checklist = Checklist(
          id: '1',
          name: 'Test',
          createdAt: DateTime(2024),
        );
        expect(checklist.isAllChecked, false);
      });

      test('returns false when not all checked', () {
        final checklist = Checklist(
          id: '1',
          name: 'Test',
          createdAt: DateTime(2024),
          items: [
            ChecklistItem(id: 'a', title: 'A', sortIndex: 0, isChecked: true),
            ChecklistItem(id: 'b', title: 'B', sortIndex: 1),
          ],
        );
        expect(checklist.isAllChecked, false);
      });

      test('returns true when all checked', () {
        final checklist = Checklist(
          id: '1',
          name: 'Test',
          createdAt: DateTime(2024),
          items: [
            ChecklistItem(id: 'a', title: 'A', sortIndex: 0, isChecked: true),
            ChecklistItem(id: 'b', title: 'B', sortIndex: 1, isChecked: true),
          ],
        );
        expect(checklist.isAllChecked, true);
      });
    });

    group('copyWith', () {
      late Checklist checklist;

      setUp(() {
        checklist = Checklist(
          id: '1',
          name: 'Original',
          createdAt: DateTime(2024),
          items: [
            ChecklistItem(id: 'a', title: 'A', sortIndex: 0),
          ],
        );
      });

      test('copies with new name', () {
        final copy = checklist.copyWith(name: 'Updated');
        expect(copy.name, 'Updated');
        expect(copy.id, '1');
        expect(copy.items.length, 1);
      });

      test('copies with new items', () {
        final copy = checklist.copyWith(items: []);
        expect(copy.items, isEmpty);
        expect(copy.name, 'Original');
      });

      test('copies with no changes returns equivalent object', () {
        final copy = checklist.copyWith();
        expect(copy.id, checklist.id);
        expect(copy.name, checklist.name);
        expect(copy.createdAt, checklist.createdAt);
        expect(copy.items.length, checklist.items.length);
      });
    });
  });
}
