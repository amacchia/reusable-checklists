import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:reusable_checklists/core/constants/app_theme.dart';
import 'package:reusable_checklists/data/models/checklist.dart';
import 'package:reusable_checklists/data/models/checklist_item.dart';
import 'package:reusable_checklists/data/repositories/checklist_repository.dart';
import 'package:reusable_checklists/viewmodels/checklist_detail_viewmodel.dart';
import 'package:reusable_checklists/viewmodels/checklist_list_viewmodel.dart';
import 'package:reusable_checklists/viewmodels/selection_viewmodel.dart';
import 'package:reusable_checklists/views/screens/checklist_detail_screen.dart';
import 'package:reusable_checklists/views/screens/checklist_list_screen.dart';

class MockChecklistRepository extends Mock implements ChecklistRepository {}

/// ReorderableList drags must move incrementally so the list can update its
/// insertion index as the dragged item passes over its siblings.
Future<void> dragReorderToLast(WidgetTester tester, Finder handle) async {
  final gesture = await tester.startGesture(tester.getCenter(handle));
  await tester.pump();
  for (var i = 0; i < 30; i++) {
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump(const Duration(milliseconds: 20));
  }
  await tester.pumpAndSettle();
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  late MockChecklistRepository mockRepository;

  setUp(() {
    mockRepository = MockChecklistRepository();
  });

  setUpAll(() {
    registerFallbackValue(
      Checklist(id: 'fallback', name: 'fallback', createdAt: DateTime(2024)),
    );
  });

  group('reorder via onReorderItem integration', () {
    testWidgets(
      'dragging first checklist to the end keeps it in last position',
      (tester) async {
        final a = Checklist(id: 'a', name: 'Alpha', createdAt: DateTime(2024));
        final b = Checklist(
          id: 'b',
          name: 'Beta',
          createdAt: DateTime(2024, 2),
          sortIndex: 1,
        );
        final c = Checklist(
          id: 'c',
          name: 'Gamma',
          createdAt: DateTime(2024, 3),
          sortIndex: 2,
        );
        when(
          () => mockRepository.getAllChecklists(),
        ).thenAnswer((_) async => [a, b, c]);
        when(
          () => mockRepository.saveChecklist(any()),
        ).thenAnswer((_) async {});

        final vm = ChecklistListViewModel(mockRepository);
        await vm.loadChecklists();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ChecklistListViewModel>.value(value: vm),
              ChangeNotifierProvider<SelectionNotifier>(
                create: (_) => SelectionNotifier(),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const ChecklistListScreen(showSettingsAction: false),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final alphaHandle = find.descendant(
          of: find.ancestor(
            of: find.text('Alpha'),
            matching: find.byType(Card),
          ),
          matching: find.byIcon(Icons.drag_handle),
        );
        await dragReorderToLast(tester, alphaHandle);

        expect(vm.checklists.map((c) => c.id).toList(), ['b', 'c', 'a']);
        expect(vm.errorMessage, isNull);
      },
    );

    testWidgets('dragging first item to the end keeps it in last position', (
      tester,
    ) async {
      final checklist = Checklist(
        id: '1',
        name: 'Test',
        createdAt: DateTime(2024),
        items: [
          ChecklistItem(id: 'a', title: 'Item A', sortIndex: 0),
          ChecklistItem(id: 'b', title: 'Item B', sortIndex: 1),
          ChecklistItem(id: 'c', title: 'Item C', sortIndex: 2),
        ],
      );
      when(
        () => mockRepository.getChecklistById('1'),
      ).thenAnswer((_) async => checklist);
      when(() => mockRepository.saveChecklist(any())).thenAnswer((_) async {});

      final vm = ChecklistDetailViewModel(mockRepository);
      await vm.loadChecklist('1');

      await tester.pumpWidget(
        ChangeNotifierProvider<ChecklistDetailViewModel>.value(
          value: vm,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ChecklistDetailScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final itemAHandle = find.descendant(
        of: find.ancestor(
          of: find.text('Item A'),
          matching: find.byType(ListTile),
        ),
        matching: find.byIcon(Icons.drag_handle),
      );
      await dragReorderToLast(tester, itemAHandle);

      expect(vm.sortedItems.map((i) => i.title).toList(), [
        'Item B',
        'Item C',
        'Item A',
      ]);
      expect(vm.errorMessage, isNull);
    });
  });
}
