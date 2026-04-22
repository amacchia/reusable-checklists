import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reusable_checklists/data/models/checklist.dart';
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
