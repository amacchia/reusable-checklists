import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reusable_checklists/data/models/checklist.dart';
import 'package:reusable_checklists/data/models/checklist_item.dart';
import 'package:reusable_checklists/data/repositories/checklist_repository.dart';
import 'package:reusable_checklists/viewmodels/checklist_list_viewmodel.dart';

class MockChecklistRepository extends Mock implements ChecklistRepository {}

void main() {
  late MockChecklistRepository mockRepository;
  late ChecklistListViewModel viewModel;

  setUp(() {
    mockRepository = MockChecklistRepository();
    viewModel = ChecklistListViewModel(mockRepository);
  });

  setUpAll(() {
    registerFallbackValue(Checklist(
      id: 'fallback',
      name: 'fallback',
      createdAt: DateTime(2024),
    ));
  });

  group('ChecklistListViewModel', () {
    group('loadChecklists', () {
      test('sets isLoading then populates checklists', () async {
        final checklists = [
          Checklist(id: '1', name: 'A', createdAt: DateTime(2024, 1)),
          Checklist(id: '2', name: 'B', createdAt: DateTime(2024, 2)),
        ];
        when(() => mockRepository.getAllChecklists())
            .thenAnswer((_) async => checklists);

        final states = <bool>[];
        viewModel.addListener(() => states.add(viewModel.isLoading));

        await viewModel.loadChecklists();

        expect(states, [true, false]);
        expect(viewModel.checklists.length, 2);
        expect(viewModel.checklists.first.name, 'B'); // newest first
      });

      test('sets errorMessage on failure', () async {
        when(() => mockRepository.getAllChecklists())
            .thenThrow(Exception('Failed'));

        await viewModel.loadChecklists();

        expect(viewModel.errorMessage, contains('Failed'));
        expect(viewModel.isLoading, false);
      });
    });

    group('createChecklist', () {
      test('creates and prepends checklist', () async {
        when(() => mockRepository.saveChecklist(any()))
            .thenAnswer((_) async {});

        await viewModel.createChecklist('New List');

        expect(viewModel.checklists.length, 1);
        expect(viewModel.checklists.first.name, 'New List');
        verify(() => mockRepository.saveChecklist(any())).called(1);
      });

      test('sets errorMessage on failure', () async {
        when(() => mockRepository.saveChecklist(any()))
            .thenThrow(Exception('Save failed'));

        await viewModel.createChecklist('New List');

        expect(viewModel.errorMessage, contains('Save failed'));
      });
    });

    group('deleteChecklist', () {
      test('removes checklist from list', () async {
        when(() => mockRepository.getAllChecklists()).thenAnswer((_) async => [
              Checklist(id: '1', name: 'A', createdAt: DateTime(2024)),
            ]);
        when(() => mockRepository.deleteChecklist('1'))
            .thenAnswer((_) async {});

        await viewModel.loadChecklists();
        await viewModel.deleteChecklist('1');

        expect(viewModel.checklists, isEmpty);
        verify(() => mockRepository.deleteChecklist('1')).called(1);
      });

      test('sets errorMessage on failure', () async {
        when(() => mockRepository.deleteChecklist('1'))
            .thenThrow(Exception('Delete failed'));

        await viewModel.deleteChecklist('1');

        expect(viewModel.errorMessage, contains('Delete failed'));
      });
    });

    group('saveChecklist', () {
      test('saves and re-inserts checklist in sorted order', () async {
        when(() => mockRepository.saveChecklist(any()))
            .thenAnswer((_) async {});

        final checklist = Checklist(
          id: '1',
          name: 'Restored',
          createdAt: DateTime(2024),
        );
        await viewModel.saveChecklist(checklist);

        expect(viewModel.checklists.length, 1);
        expect(viewModel.checklists.first.name, 'Restored');
      });

      test('sets errorMessage on failure', () async {
        when(() => mockRepository.saveChecklist(any()))
            .thenThrow(Exception('Save failed'));

        final checklist = Checklist(
          id: '1',
          name: 'Test',
          createdAt: DateTime(2024),
        );
        await viewModel.saveChecklist(checklist);

        expect(viewModel.errorMessage, contains('Save failed'));
      });
    });

    group('reorderChecklists', () {
      test('reorders and reassigns sortIndex', () async {
        final a = Checklist(
            id: 'a', name: 'A', createdAt: DateTime(2024, 1), sortIndex: 0);
        final b = Checklist(
            id: 'b', name: 'B', createdAt: DateTime(2024, 2), sortIndex: 1);
        final c = Checklist(
            id: 'c', name: 'C', createdAt: DateTime(2024, 3), sortIndex: 2);
        when(() => mockRepository.getAllChecklists())
            .thenAnswer((_) async => [a, b, c]);
        when(() => mockRepository.saveChecklist(any()))
            .thenAnswer((_) async {});

        await viewModel.loadChecklists();
        await viewModel.reorderChecklists(0, 3); // move A to the end

        expect(viewModel.checklists.map((c) => c.id).toList(),
            ['b', 'c', 'a']);
        expect(viewModel.checklists.map((c) => c.sortIndex).toList(),
            [0, 1, 2]);
        verify(() => mockRepository.saveChecklist(any())).called(3);
      });

      test('sets errorMessage on failure', () async {
        final a = Checklist(id: 'a', name: 'A', createdAt: DateTime(2024));
        when(() => mockRepository.getAllChecklists())
            .thenAnswer((_) async => [a]);
        when(() => mockRepository.saveChecklist(any()))
            .thenThrow(Exception('Reorder failed'));

        await viewModel.loadChecklists();
        await viewModel.reorderChecklists(0, 1);

        expect(viewModel.errorMessage, contains('Reorder failed'));
      });
    });

    group('loadChecklists ordering', () {
      test('sorts by sortIndex ascending, createdAt descending as tiebreaker',
          () async {
        // Legacy checklists all have sortIndex 0 - fall back to createdAt desc.
        final a = Checklist(id: 'a', name: 'A', createdAt: DateTime(2024, 1));
        final b = Checklist(id: 'b', name: 'B', createdAt: DateTime(2024, 3));
        final c = Checklist(
            id: 'c', name: 'C', createdAt: DateTime(2024, 2), sortIndex: -1);
        when(() => mockRepository.getAllChecklists())
            .thenAnswer((_) async => [a, b, c]);

        await viewModel.loadChecklists();

        expect(viewModel.checklists.map((c) => c.id).toList(),
            ['c', 'b', 'a']);
      });
    });

    group('createChecklist ordering', () {
      test('new checklist lands at the top', () async {
        final a = Checklist(
            id: 'a', name: 'A', createdAt: DateTime(2024), sortIndex: 0);
        when(() => mockRepository.getAllChecklists())
            .thenAnswer((_) async => [a]);
        when(() => mockRepository.saveChecklist(any()))
            .thenAnswer((_) async {});

        await viewModel.loadChecklists();
        await viewModel.createChecklist('New');

        expect(viewModel.checklists.first.name, 'New');
      });
    });

    group('exportAsJson and importFromJson', () {
      test('exports and re-imports round-trips checklists', () async {
        final original = Checklist(
          id: 'a',
          name: 'Original',
          createdAt: DateTime.utc(2024, 1, 1),
          sortIndex: 0,
          items: [
            ChecklistItem(id: 'x', title: 'Milk', sortIndex: 0),
          ],
        );
        when(() => mockRepository.getAllChecklists())
            .thenAnswer((_) async => [original]);
        when(() => mockRepository.saveChecklist(any()))
            .thenAnswer((_) async {});

        await viewModel.loadChecklists();
        final exported = viewModel.exportAsJson();
        expect(exported, contains('Original'));
        expect(exported, contains('Milk'));

        final count = await viewModel.importFromJson(exported);
        expect(count, 1);
        // Imported with a new id because original id collides.
        verify(() => mockRepository.saveChecklist(any()))
            .called(greaterThanOrEqualTo(1));
      });

      test('import preserves id when it does not collide', () async {
        when(() => mockRepository.getAllChecklists())
            .thenAnswer((_) async => []);
        when(() => mockRepository.saveChecklist(any()))
            .thenAnswer((_) async {});

        await viewModel.loadChecklists();
        const payload =
            '{"version":1,"checklists":[{"id":"new","name":"Imported",'
            '"createdAt":"2024-01-01T00:00:00.000Z","sortIndex":0,'
            '"items":[]}]}';
        final count = await viewModel.importFromJson(payload);

        expect(count, 1);
        final captured = verify(() =>
                mockRepository.saveChecklist(captureAny()))
            .captured;
        expect((captured.first as Checklist).id, 'new');
        expect((captured.first as Checklist).name, 'Imported');
      });

      test('import throws on malformed JSON', () async {
        when(() => mockRepository.getAllChecklists())
            .thenAnswer((_) async => []);
        await viewModel.loadChecklists();

        expect(
          () => viewModel.importFromJson('not json'),
          throwsA(isA<FormatException>()),
        );
      });

      test('import throws FormatException on wrong schema', () async {
        when(() => mockRepository.getAllChecklists())
            .thenAnswer((_) async => []);
        await viewModel.loadChecklists();

        expect(
          () => viewModel.importFromJson('{"something":"else"}'),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('clearError', () {
      test('clears errorMessage and notifies', () async {
        when(() => mockRepository.getAllChecklists())
            .thenThrow(Exception('Load failed'));

        await viewModel.loadChecklists();
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
  });
}
