import 'package:flutter_test/flutter_test.dart';
import 'package:reusable_checklists/data/models/checklist_item.dart';

void main() {
  group('ChecklistItem', () {
    test('creates with default isChecked false', () {
      final item = ChecklistItem(id: '1', title: 'Test', sortIndex: 0);
      expect(item.isChecked, false);
    });

    test('creates with all fields', () {
      final item = ChecklistItem(
        id: '1',
        title: 'Test',
        isChecked: true,
        sortIndex: 2,
      );
      expect(item.id, '1');
      expect(item.title, 'Test');
      expect(item.isChecked, true);
      expect(item.sortIndex, 2);
    });

    group('copyWith', () {
      late ChecklistItem item;

      setUp(() {
        item = ChecklistItem(id: '1', title: 'Original', sortIndex: 0);
      });

      test('copies with new title', () {
        final copy = item.copyWith(title: 'Updated');
        expect(copy.title, 'Updated');
        expect(copy.id, '1');
        expect(copy.isChecked, false);
        expect(copy.sortIndex, 0);
      });

      test('copies with new isChecked', () {
        final copy = item.copyWith(isChecked: true);
        expect(copy.isChecked, true);
        expect(copy.title, 'Original');
      });

      test('copies with new sortIndex', () {
        final copy = item.copyWith(sortIndex: 5);
        expect(copy.sortIndex, 5);
      });

      test('copies with no changes returns equivalent object', () {
        final copy = item.copyWith();
        expect(copy.id, item.id);
        expect(copy.title, item.title);
        expect(copy.isChecked, item.isChecked);
        expect(copy.sortIndex, item.sortIndex);
      });
    });
  });
}
