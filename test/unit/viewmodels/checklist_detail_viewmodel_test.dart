import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reusable_checklists/data/models/checklist.dart';
import 'package:reusable_checklists/data/models/checklist_item.dart';
import 'package:reusable_checklists/data/repositories/checklist_repository.dart';
import 'package:reusable_checklists/viewmodels/checklist_detail_viewmodel.dart';

class MockChecklistRepository extends Mock implements ChecklistRepository {}

void main() {
  late MockChecklistRepository mockRepository;
  late ChecklistDetailViewModel viewModel;

  setUp(() {
    mockRepository = MockChecklistRepository();
    viewModel = ChecklistDetailViewModel(mockRepository);
  });

  setUpAll(() {
    registerFallbackValue(Checklist(
      id: 'fallback',
      name: 'fallback',
      createdAt: DateTime(2024),
    ));
  });

  Checklist makeChecklist({List<ChecklistItem>? items}) {
    return Checklist(
      id: '1',
      name: 'Test',
      createdAt: DateTime(2024),
      items: items ??
          [
            ChecklistItem(id: 'a', title: 'Item A', sortIndex: 0),
            ChecklistItem(id: 'b', title: 'Item B', sortIndex: 1),
            ChecklistItem(id: 'c', title: 'Item C', sortIndex: 2),
          ],
    );
  }

  group('ChecklistDetailViewModel', () {
    group('loadChecklist', () {
      test('loads checklist from repository', () async {
        final checklist = makeChecklist();
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);

        await viewModel.loadChecklist('1');

        expect(viewModel.checklist, isNotNull);
        expect(viewModel.checklist!.name, 'Test');
      });

      test('sets errorMessage on failure', () async {
        when(() => mockRepository.getChecklistById('1'))
            .thenThrow(Exception('Load failed'));

        await viewModel.loadChecklist('1');

        expect(viewModel.errorMessage, contains('Load failed'));
      });
    });

    group('sortedItems', () {
      test('returns empty list when checklist is null', () {
        expect(viewModel.sortedItems, isEmpty);
      });

      test('returns items sorted by sortIndex', () async {
        final checklist = makeChecklist(items: [
          ChecklistItem(id: 'b', title: 'B', sortIndex: 2),
          ChecklistItem(id: 'a', title: 'A', sortIndex: 0),
          ChecklistItem(id: 'c', title: 'C', sortIndex: 1),
        ]);
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);

        await viewModel.loadChecklist('1');

        expect(viewModel.sortedItems.map((i) => i.title).toList(),
            ['A', 'C', 'B']);
      });
    });

    group('addItem', () {
      test('adds item and persists', () async {
        final checklist = makeChecklist(items: []);
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);
        when(() => mockRepository.saveChecklist(any()))
            .thenAnswer((_) async {});

        await viewModel.loadChecklist('1');
        await viewModel.addItem('New Item');

        expect(viewModel.checklist!.items.length, 1);
        expect(viewModel.checklist!.items.first.title, 'New Item');
        expect(viewModel.checklist!.items.first.sortIndex, 0);
        verify(() => mockRepository.saveChecklist(any())).called(1);
      });

      test('does nothing when checklist is null', () async {
        await viewModel.addItem('Test');
        verifyNever(() => mockRepository.saveChecklist(any()));
      });

      test('sets errorMessage on failure', () async {
        final checklist = makeChecklist(items: []);
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);
        when(() => mockRepository.saveChecklist(any()))
            .thenThrow(Exception('Save failed'));

        await viewModel.loadChecklist('1');
        await viewModel.addItem('Test');

        expect(viewModel.errorMessage, contains('Save failed'));
      });
    });

    group('removeItem', () {
      test('removes item and reindexes', () async {
        final checklist = makeChecklist();
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);
        when(() => mockRepository.saveChecklist(any()))
            .thenAnswer((_) async {});

        await viewModel.loadChecklist('1');
        await viewModel.removeItem('b');

        expect(viewModel.checklist!.items.length, 2);
        expect(
            viewModel.checklist!.items.any((i) => i.id == 'b'), false);
        // Verify reindexing
        final sorted = viewModel.sortedItems;
        expect(sorted[0].sortIndex, 0);
        expect(sorted[1].sortIndex, 1);
      });

      test('does nothing when checklist is null', () async {
        await viewModel.removeItem('a');
        verifyNever(() => mockRepository.saveChecklist(any()));
      });

      test('sets errorMessage on failure', () async {
        final checklist = makeChecklist();
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);
        when(() => mockRepository.saveChecklist(any()))
            .thenThrow(Exception('Remove failed'));

        await viewModel.loadChecklist('1');
        await viewModel.removeItem('a');

        expect(viewModel.errorMessage, contains('Remove failed'));
      });
    });

    group('toggleItem', () {
      test('toggles item check state', () async {
        final checklist = makeChecklist();
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);
        when(() => mockRepository.saveChecklist(any()))
            .thenAnswer((_) async {});

        await viewModel.loadChecklist('1');
        await viewModel.toggleItem('a');

        expect(
            viewModel.checklist!.items.firstWhere((i) => i.id == 'a').isChecked,
            true);
      });

      test('toggles back to unchecked', () async {
        final checklist = makeChecklist(items: [
          ChecklistItem(
              id: 'a', title: 'A', sortIndex: 0, isChecked: true),
        ]);
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);
        when(() => mockRepository.saveChecklist(any()))
            .thenAnswer((_) async {});

        await viewModel.loadChecklist('1');
        await viewModel.toggleItem('a');

        expect(
            viewModel.checklist!.items.first.isChecked, false);
      });

      test('does nothing when checklist is null', () async {
        await viewModel.toggleItem('a');
        verifyNever(() => mockRepository.saveChecklist(any()));
      });

      test('sets errorMessage on failure', () async {
        final checklist = makeChecklist();
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);
        when(() => mockRepository.saveChecklist(any()))
            .thenThrow(Exception('Toggle failed'));

        await viewModel.loadChecklist('1');
        await viewModel.toggleItem('a');

        expect(viewModel.errorMessage, contains('Toggle failed'));
      });
    });

    group('checkAll', () {
      test('checks all items', () async {
        final checklist = makeChecklist();
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);
        when(() => mockRepository.saveChecklist(any()))
            .thenAnswer((_) async {});

        await viewModel.loadChecklist('1');
        await viewModel.checkAll();

        expect(viewModel.checklist!.items.every((i) => i.isChecked), true);
      });

      test('does nothing when checklist is null', () async {
        await viewModel.checkAll();
        verifyNever(() => mockRepository.saveChecklist(any()));
      });

      test('sets errorMessage on failure', () async {
        final checklist = makeChecklist();
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);
        when(() => mockRepository.saveChecklist(any()))
            .thenThrow(Exception('CheckAll failed'));

        await viewModel.loadChecklist('1');
        await viewModel.checkAll();

        expect(viewModel.errorMessage, contains('CheckAll failed'));
      });
    });

    group('uncheckAll', () {
      test('unchecks all items', () async {
        final checklist = makeChecklist(items: [
          ChecklistItem(
              id: 'a', title: 'A', sortIndex: 0, isChecked: true),
          ChecklistItem(
              id: 'b', title: 'B', sortIndex: 1, isChecked: true),
        ]);
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);
        when(() => mockRepository.saveChecklist(any()))
            .thenAnswer((_) async {});

        await viewModel.loadChecklist('1');
        await viewModel.uncheckAll();

        expect(viewModel.checklist!.items.every((i) => !i.isChecked), true);
      });

      test('does nothing when checklist is null', () async {
        await viewModel.uncheckAll();
        verifyNever(() => mockRepository.saveChecklist(any()));
      });

      test('sets errorMessage on failure', () async {
        final checklist = makeChecklist(items: [
          ChecklistItem(
              id: 'a', title: 'A', sortIndex: 0, isChecked: true),
        ]);
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);
        when(() => mockRepository.saveChecklist(any()))
            .thenThrow(Exception('UncheckAll failed'));

        await viewModel.loadChecklist('1');
        await viewModel.uncheckAll();

        expect(viewModel.errorMessage, contains('UncheckAll failed'));
      });
    });

    group('uncheckedItems and checkedItems', () {
      test('returns empty lists when checklist is null', () {
        expect(viewModel.uncheckedItems, isEmpty);
        expect(viewModel.checkedItems, isEmpty);
      });

      test('separates items by checked state', () async {
        final checklist = makeChecklist(items: [
          ChecklistItem(id: 'a', title: 'A', sortIndex: 0),
          ChecklistItem(
              id: 'b', title: 'B', sortIndex: 1, isChecked: true),
          ChecklistItem(id: 'c', title: 'C', sortIndex: 2),
        ]);
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);

        await viewModel.loadChecklist('1');

        expect(viewModel.uncheckedItems.map((i) => i.title).toList(),
            ['A', 'C']);
        expect(
            viewModel.checkedItems.map((i) => i.title).toList(), ['B']);
      });

      test('all unchecked when none are checked', () async {
        final checklist = makeChecklist();
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);

        await viewModel.loadChecklist('1');

        expect(viewModel.uncheckedItems.length, 3);
        expect(viewModel.checkedItems, isEmpty);
      });

      test('all checked when everything is checked', () async {
        final checklist = makeChecklist(items: [
          ChecklistItem(
              id: 'a', title: 'A', sortIndex: 0, isChecked: true),
          ChecklistItem(
              id: 'b', title: 'B', sortIndex: 1, isChecked: true),
        ]);
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);

        await viewModel.loadChecklist('1');

        expect(viewModel.uncheckedItems, isEmpty);
        expect(viewModel.checkedItems.length, 2);
      });
    });

    group('renameChecklist', () {
      test('updates checklist name and persists', () async {
        final checklist = makeChecklist();
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);
        when(() => mockRepository.saveChecklist(any()))
            .thenAnswer((_) async {});

        await viewModel.loadChecklist('1');
        await viewModel.renameChecklist('  Renamed  ');

        expect(viewModel.checklist!.name, 'Renamed');
        verify(() => mockRepository.saveChecklist(any())).called(1);
      });

      test('does nothing when name is empty', () async {
        final checklist = makeChecklist();
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);

        await viewModel.loadChecklist('1');
        await viewModel.renameChecklist('   ');

        expect(viewModel.checklist!.name, 'Test');
        verifyNever(() => mockRepository.saveChecklist(any()));
      });

      test('does nothing when name is unchanged', () async {
        final checklist = makeChecklist();
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);

        await viewModel.loadChecklist('1');
        await viewModel.renameChecklist('Test');

        verifyNever(() => mockRepository.saveChecklist(any()));
      });

      test('does nothing when checklist is null', () async {
        await viewModel.renameChecklist('Anything');
        verifyNever(() => mockRepository.saveChecklist(any()));
      });

      test('sets errorMessage on failure', () async {
        final checklist = makeChecklist();
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);
        when(() => mockRepository.saveChecklist(any()))
            .thenThrow(Exception('Rename failed'));

        await viewModel.loadChecklist('1');
        await viewModel.renameChecklist('New Name');

        expect(viewModel.errorMessage, contains('Rename failed'));
      });
    });

    group('editItem', () {
      test('updates item title and persists', () async {
        final checklist = makeChecklist();
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);
        when(() => mockRepository.saveChecklist(any()))
            .thenAnswer((_) async {});

        await viewModel.loadChecklist('1');
        await viewModel.editItem('a', '  Updated  ');

        final item =
            viewModel.checklist!.items.firstWhere((i) => i.id == 'a');
        expect(item.title, 'Updated');
        verify(() => mockRepository.saveChecklist(any())).called(1);
      });

      test('does nothing when title is empty', () async {
        final checklist = makeChecklist();
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);

        await viewModel.loadChecklist('1');
        await viewModel.editItem('a', '   ');

        final item =
            viewModel.checklist!.items.firstWhere((i) => i.id == 'a');
        expect(item.title, 'Item A');
        verifyNever(() => mockRepository.saveChecklist(any()));
      });

      test('does nothing when title is unchanged', () async {
        final checklist = makeChecklist();
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);

        await viewModel.loadChecklist('1');
        await viewModel.editItem('a', 'Item A');

        verifyNever(() => mockRepository.saveChecklist(any()));
      });

      test('does nothing when checklist is null', () async {
        await viewModel.editItem('a', 'New');
        verifyNever(() => mockRepository.saveChecklist(any()));
      });

      test('sets errorMessage on failure', () async {
        final checklist = makeChecklist();
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);
        when(() => mockRepository.saveChecklist(any()))
            .thenThrow(Exception('Edit failed'));

        await viewModel.loadChecklist('1');
        await viewModel.editItem('a', 'New Title');

        expect(viewModel.errorMessage, contains('Edit failed'));
      });
    });

    group('clearError', () {
      test('clears errorMessage and notifies', () async {
        when(() => mockRepository.getChecklistById('1'))
            .thenThrow(Exception('Load failed'));

        await viewModel.loadChecklist('1');
        expect(viewModel.errorMessage, isNotNull);

        var notified = 0;
        viewModel.addListener(() => notified++);
        viewModel.clearError();

        expect(viewModel.errorMessage, isNull);
        expect(notified, 1);
      });

      test('is a no-op when errorMessage is already null', () {
        var notified = 0;
        viewModel.addListener(() => notified++);
        viewModel.clearError();

        expect(notified, 0);
      });
    });

    group('restoreItem', () {
      test('re-inserts removed item at its original sort index', () async {
        final checklist = makeChecklist();
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);
        when(() => mockRepository.saveChecklist(any()))
            .thenAnswer((_) async {});

        await viewModel.loadChecklist('1');
        final removed = viewModel.checklist!.items
            .firstWhere((i) => i.id == 'b');
        await viewModel.removeItem('b');
        await viewModel.restoreItem(removed);

        expect(viewModel.sortedItems.map((i) => i.title).toList(),
            ['Item A', 'Item B', 'Item C']);
      });

      test('clamps insert index when sortIndex is out of range', () async {
        final checklist = makeChecklist(items: [
          ChecklistItem(id: 'a', title: 'A', sortIndex: 0),
        ]);
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);
        when(() => mockRepository.saveChecklist(any()))
            .thenAnswer((_) async {});

        await viewModel.loadChecklist('1');
        final restored =
            ChecklistItem(id: 'z', title: 'Z', sortIndex: 99);
        await viewModel.restoreItem(restored);

        expect(viewModel.sortedItems.map((i) => i.title).toList(),
            ['A', 'Z']);
      });

      test('is a no-op if item with same id already exists', () async {
        final checklist = makeChecklist();
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);

        await viewModel.loadChecklist('1');
        final duplicate =
            ChecklistItem(id: 'a', title: 'Dup', sortIndex: 0);
        await viewModel.restoreItem(duplicate);

        verifyNever(() => mockRepository.saveChecklist(any()));
      });

      test('does nothing when checklist is null', () async {
        final item = ChecklistItem(id: 'a', title: 'A', sortIndex: 0);
        await viewModel.restoreItem(item);
        verifyNever(() => mockRepository.saveChecklist(any()));
      });

      test('sets errorMessage on failure', () async {
        final checklist = makeChecklist();
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);
        when(() => mockRepository.saveChecklist(any()))
            .thenThrow(Exception('Restore failed'));

        await viewModel.loadChecklist('1');
        final restored =
            ChecklistItem(id: 'z', title: 'Z', sortIndex: 0);
        await viewModel.restoreItem(restored);

        expect(viewModel.errorMessage, contains('Restore failed'));
      });
    });

    group('reorderItems', () {
      test('moves unchecked item from index 0 to index 2', () async {
        final checklist = makeChecklist();
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);
        when(() => mockRepository.saveChecklist(any()))
            .thenAnswer((_) async {});

        await viewModel.loadChecklist('1');
        await viewModel.reorderItems(0, 3); // move A after C

        final sorted = viewModel.sortedItems;
        expect(sorted.map((i) => i.title).toList(), ['Item B', 'Item C', 'Item A']);
        expect(sorted[0].sortIndex, 0);
        expect(sorted[1].sortIndex, 1);
        expect(sorted[2].sortIndex, 2);
      });

      test('moves unchecked item from index 2 to index 0', () async {
        final checklist = makeChecklist();
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);
        when(() => mockRepository.saveChecklist(any()))
            .thenAnswer((_) async {});

        await viewModel.loadChecklist('1');
        await viewModel.reorderItems(2, 0); // move C before A

        final sorted = viewModel.sortedItems;
        expect(sorted.map((i) => i.title).toList(), ['Item C', 'Item A', 'Item B']);
      });

      test('reorder only affects unchecked items, checked keep their slot',
          () async {
        final checklist = makeChecklist(items: [
          ChecklistItem(id: 'a', title: 'A', sortIndex: 0),
          ChecklistItem(
              id: 'b', title: 'B', sortIndex: 1, isChecked: true),
          ChecklistItem(id: 'c', title: 'C', sortIndex: 2),
        ]);
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);
        when(() => mockRepository.saveChecklist(any()))
            .thenAnswer((_) async {});

        await viewModel.loadChecklist('1');
        // Unchecked items are [A, C], move C before A
        await viewModel.reorderItems(1, 0);

        expect(viewModel.uncheckedItems.map((i) => i.title).toList(),
            ['C', 'A']);
        expect(
            viewModel.checkedItems.map((i) => i.title).toList(), ['B']);
        // B keeps its middle slot (sortIndex 1), so unchecking it later
        // restores it between C and A.
        final byId = {for (final i in viewModel.sortedItems) i.id: i};
        expect(byId['b']!.sortIndex, 1);
      });

      test('checked item returns to its prior slot when unchecked',
          () async {
        final checklist = makeChecklist(items: [
          ChecklistItem(id: 'a', title: 'A', sortIndex: 0),
          ChecklistItem(id: 'b', title: 'B', sortIndex: 1),
          ChecklistItem(id: 'c', title: 'C', sortIndex: 2),
          ChecklistItem(id: 'd', title: 'D', sortIndex: 3),
        ]);
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);
        when(() => mockRepository.saveChecklist(any()))
            .thenAnswer((_) async {});

        await viewModel.loadChecklist('1');
        // Check B (slot 1).
        await viewModel.toggleItem('b');
        // Reorder unchecked [A, C, D] -> [D, A, C]. B's slot should be preserved.
        await viewModel.reorderItems(2, 0);
        expect(viewModel.uncheckedItems.map((i) => i.title).toList(),
            ['D', 'A', 'C']);
        // Uncheck B; it returns to its remembered slot.
        await viewModel.toggleItem('b');
        expect(viewModel.uncheckedItems.map((i) => i.title).toList(),
            ['D', 'B', 'A', 'C']);
      });

      test('does nothing when checklist is null', () async {
        await viewModel.reorderItems(0, 1);
        verifyNever(() => mockRepository.saveChecklist(any()));
      });

      test('sets errorMessage on failure', () async {
        final checklist = makeChecklist();
        when(() => mockRepository.getChecklistById('1'))
            .thenAnswer((_) async => checklist);
        when(() => mockRepository.saveChecklist(any()))
            .thenThrow(Exception('Reorder failed'));

        await viewModel.loadChecklist('1');
        await viewModel.reorderItems(0, 2);

        expect(viewModel.errorMessage, contains('Reorder failed'));
      });
    });
  });
}
