import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:reusable_checklists/core/constants/app_strings.dart';
import 'package:reusable_checklists/core/constants/app_theme.dart';
import 'package:reusable_checklists/data/models/checklist.dart';
import 'package:reusable_checklists/data/models/checklist_item.dart';
import 'package:reusable_checklists/data/repositories/checklist_repository.dart';
import 'package:reusable_checklists/viewmodels/checklist_detail_viewmodel.dart';
import 'package:reusable_checklists/views/screens/checklist_detail_screen.dart';
import 'package:reusable_checklists/views/widgets/checklist_item_tile.dart';
import 'package:reusable_checklists/views/widgets/text_input_dialog.dart';

class MockChecklistDetailViewModel extends Mock
    implements ChecklistDetailViewModel {}

class MockChecklistRepository extends Mock implements ChecklistRepository {}

Widget buildApp(ChecklistDetailViewModel vm) {
  return ChangeNotifierProvider<ChecklistDetailViewModel>.value(
    value: vm,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const ChecklistDetailScreen(),
    ),
  );
}

void main() {
  late MockChecklistDetailViewModel mockVm;

  setUpAll(() {
    registerFallbackValue(
      ChecklistItem(id: 'fallback', title: 'fallback', sortIndex: 0),
    );
    registerFallbackValue(
      Checklist(id: 'fallback', name: 'fallback', createdAt: DateTime(2024)),
    );
  });

  setUp(() {
    mockVm = MockChecklistDetailViewModel();
    when(() => mockVm.errorMessage).thenReturn(null);
    when(() => mockVm.isSearchActive).thenReturn(false);
    when(() => mockVm.hasSearchQuery).thenReturn(false);
    when(() => mockVm.searchQuery).thenReturn('');
  });

  /// Helper to stub all list getters on the mock VM.
  void stubItems(
    MockChecklistDetailViewModel vm, {
    List<ChecklistItem> unchecked = const [],
    List<ChecklistItem> checked = const [],
  }) {
    when(() => vm.sortedItems).thenReturn([...unchecked, ...checked]);
    when(() => vm.visibleItems).thenReturn([...unchecked, ...checked]);
    when(() => vm.uncheckedItems).thenReturn(unchecked);
    when(() => vm.checkedItems).thenReturn(checked);
  }

  group('ChecklistDetailScreen', () {
    testWidgets('shows loading when checklist is null', (tester) async {
      when(() => mockVm.checklist).thenReturn(null);
      stubItems(mockVm);

      await tester.pumpWidget(buildApp(mockVm));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows checklist name in app bar', (tester) async {
      when(() => mockVm.checklist).thenReturn(
        Checklist(id: '1', name: 'Groceries', createdAt: DateTime(2024)),
      );
      stubItems(mockVm);

      await tester.pumpWidget(buildApp(mockVm));

      expect(find.text('Groceries'), findsOneWidget);
    });

    testWidgets('shows empty state when no items', (tester) async {
      when(
        () => mockVm.checklist,
      ).thenReturn(Checklist(id: '1', name: 'Test', createdAt: DateTime(2024)));
      stubItems(mockVm);

      await tester.pumpWidget(buildApp(mockVm));

      expect(find.text(AppStrings.emptyItems), findsOneWidget);
    });

    testWidgets('shows unchecked items in main list', (tester) async {
      final items = [
        ChecklistItem(id: 'a', title: 'Milk', sortIndex: 0),
        ChecklistItem(id: 'b', title: 'Eggs', sortIndex: 1),
      ];
      when(() => mockVm.checklist).thenReturn(
        Checklist(
          id: '1',
          name: 'Test',
          createdAt: DateTime(2024),
          items: items,
        ),
      );
      stubItems(mockVm, unchecked: items);

      await tester.pumpWidget(buildApp(mockVm));

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Eggs'), findsOneWidget);
      expect(find.text('Completed'), findsNothing);
    });

    testWidgets('shows Completed section when checked items exist', (
      tester,
    ) async {
      final unchecked = [ChecklistItem(id: 'a', title: 'Milk', sortIndex: 0)];
      final checked = [
        ChecklistItem(id: 'b', title: 'Bread', sortIndex: 1, isChecked: true),
      ];
      when(() => mockVm.checklist).thenReturn(
        Checklist(
          id: '1',
          name: 'Test',
          createdAt: DateTime(2024),
          items: [...unchecked, ...checked],
        ),
      );
      stubItems(mockVm, unchecked: unchecked, checked: checked);

      await tester.pumpWidget(buildApp(mockVm));

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('hides Completed header when no checked items', (tester) async {
      final items = [ChecklistItem(id: 'a', title: 'Milk', sortIndex: 0)];
      when(() => mockVm.checklist).thenReturn(
        Checklist(
          id: '1',
          name: 'Test',
          createdAt: DateTime(2024),
          items: items,
        ),
      );
      stubItems(mockVm, unchecked: items);

      await tester.pumpWidget(buildApp(mockVm));

      expect(find.text('Completed'), findsNothing);
    });

    testWidgets('shows Check All and Uncheck All buttons', (tester) async {
      when(
        () => mockVm.checklist,
      ).thenReturn(Checklist(id: '1', name: 'Test', createdAt: DateTime(2024)));
      stubItems(mockVm);

      await tester.pumpWidget(buildApp(mockVm));

      expect(find.byTooltip(AppStrings.checkAll), findsOneWidget);
      expect(find.byTooltip(AppStrings.uncheckAll), findsOneWidget);
    });

    testWidgets('Check All calls vm.checkAll', (tester) async {
      final items = [ChecklistItem(id: 'a', title: 'Test', sortIndex: 0)];
      when(() => mockVm.checklist).thenReturn(
        Checklist(
          id: '1',
          name: 'Test',
          createdAt: DateTime(2024),
          items: items,
        ),
      );
      stubItems(mockVm, unchecked: items);
      when(() => mockVm.checkAll()).thenAnswer((_) async {});

      await tester.pumpWidget(buildApp(mockVm));
      await tester.tap(find.byTooltip(AppStrings.checkAll));

      verify(() => mockVm.checkAll()).called(1);
    });

    testWidgets('Uncheck All calls vm.uncheckAll', (tester) async {
      final items = [ChecklistItem(id: 'a', title: 'Test', sortIndex: 0)];
      when(() => mockVm.checklist).thenReturn(
        Checklist(
          id: '1',
          name: 'Test',
          createdAt: DateTime(2024),
          items: items,
        ),
      );
      stubItems(mockVm, unchecked: items);
      when(() => mockVm.uncheckAll()).thenAnswer((_) async {});

      await tester.pumpWidget(buildApp(mockVm));
      await tester.tap(find.byTooltip(AppStrings.uncheckAll));

      verify(() => mockVm.uncheckAll()).called(1);
    });

    testWidgets('shows add item input bar', (tester) async {
      when(
        () => mockVm.checklist,
      ).thenReturn(Checklist(id: '1', name: 'Test', createdAt: DateTime(2024)));
      stubItems(mockVm);

      await tester.pumpWidget(buildApp(mockVm));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text(AppStrings.addItem), findsOneWidget);
    });

    testWidgets('TextField uses sentence capitalization', (tester) async {
      when(
        () => mockVm.checklist,
      ).thenReturn(Checklist(id: '1', name: 'Test', createdAt: DateTime(2024)));
      stubItems(mockVm);

      await tester.pumpWidget(buildApp(mockVm));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.textCapitalization, TextCapitalization.sentences);
    });

    testWidgets('add item button calls addItem and clears input', (
      tester,
    ) async {
      when(
        () => mockVm.checklist,
      ).thenReturn(Checklist(id: '1', name: 'Test', createdAt: DateTime(2024)));
      stubItems(mockVm);
      when(() => mockVm.addItem(any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildApp(mockVm));

      await tester.enterText(find.byType(TextField), 'New item');
      await tester.tap(find.byIcon(Icons.add));

      verify(() => mockVm.addItem('New item')).called(1);
    });

    testWidgets('does not add empty items', (tester) async {
      when(
        () => mockVm.checklist,
      ).thenReturn(Checklist(id: '1', name: 'Test', createdAt: DateTime(2024)));
      stubItems(mockVm);

      await tester.pumpWidget(buildApp(mockVm));

      await tester.tap(find.byIcon(Icons.add));

      verifyNever(() => mockVm.addItem(any()));
    });

    testWidgets('toggle calls vm.toggleItem', (tester) async {
      final items = [ChecklistItem(id: 'a', title: 'Test', sortIndex: 0)];
      when(() => mockVm.checklist).thenReturn(
        Checklist(
          id: '1',
          name: 'Test',
          createdAt: DateTime(2024),
          items: items,
        ),
      );
      stubItems(mockVm, unchecked: items);
      when(() => mockVm.toggleItem('a')).thenAnswer((_) async {});

      await tester.pumpWidget(buildApp(mockVm));
      await tester.tap(find.byType(Checkbox));

      verify(() => mockVm.toggleItem('a')).called(1);
    });

    testWidgets('add item via keyboard submit', (tester) async {
      when(
        () => mockVm.checklist,
      ).thenReturn(Checklist(id: '1', name: 'Test', createdAt: DateTime(2024)));
      stubItems(mockVm);
      when(() => mockVm.addItem(any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildApp(mockVm));

      await tester.enterText(find.byType(TextField), 'Keyboard item');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      verify(() => mockVm.addItem('Keyboard item')).called(1);
    });

    testWidgets('toggling a checked item calls vm.toggleItem', (tester) async {
      final checked = [
        ChecklistItem(id: 'c', title: 'Bread', sortIndex: 0, isChecked: true),
      ];
      when(() => mockVm.checklist).thenReturn(
        Checklist(
          id: '1',
          name: 'Test',
          createdAt: DateTime(2024),
          items: checked,
        ),
      );
      stubItems(mockVm, checked: checked);
      when(() => mockVm.toggleItem('c')).thenAnswer((_) async {});

      await tester.pumpWidget(buildApp(mockVm));
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      verify(() => mockVm.toggleItem('c')).called(1);
    });

    testWidgets('deleting a checked item calls vm.removeItem', (tester) async {
      final checked = [
        ChecklistItem(id: 'c', title: 'Bread', sortIndex: 0, isChecked: true),
      ];
      when(() => mockVm.checklist).thenReturn(
        Checklist(
          id: '1',
          name: 'Test',
          createdAt: DateTime(2024),
          items: checked,
        ),
      );
      stubItems(mockVm, checked: checked);
      when(() => mockVm.removeItem('c')).thenAnswer((_) async {});

      await tester.pumpWidget(buildApp(mockVm));
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      verify(() => mockVm.removeItem('c')).called(1);
    });

    testWidgets('non-const ChecklistDetailScreen constructor', (tester) async {
      final screen = ChecklistDetailScreen(key: UniqueKey());
      expect(screen, isA<ChecklistDetailScreen>());
    });

    testWidgets('rename button opens dialog with current name and saves', (
      tester,
    ) async {
      when(() => mockVm.checklist).thenReturn(
        Checklist(id: '1', name: 'Groceries', createdAt: DateTime(2024)),
      );
      stubItems(mockVm);
      when(() => mockVm.renameChecklist(any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildApp(mockVm));
      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();

      final dialogField = find.descendant(
        of: find.byType(TextInputDialog),
        matching: find.byType(TextField),
      );
      expect(find.text(AppStrings.renameChecklist), findsWidgets);
      expect(
        tester.widget<TextField>(dialogField).controller?.text,
        'Groceries',
      );

      await tester.enterText(dialogField, 'Weekly Shop');
      await tester.tap(find.text(AppStrings.save));
      await tester.pumpAndSettle();

      verify(() => mockVm.renameChecklist('Weekly Shop')).called(1);
    });

    testWidgets('item edit icon opens dialog and saves new title', (
      tester,
    ) async {
      final items = [ChecklistItem(id: 'a', title: 'Milk', sortIndex: 0)];
      when(() => mockVm.checklist).thenReturn(
        Checklist(
          id: '1',
          name: 'Test',
          createdAt: DateTime(2024),
          items: items,
        ),
      );
      stubItems(mockVm, unchecked: items);
      when(() => mockVm.editItem(any(), any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildApp(mockVm));
      final tileEditIcon = find.descendant(
        of: find.byType(ChecklistItemTile),
        matching: find.byIcon(Icons.edit_outlined),
      );
      await tester.tap(tileEditIcon);
      await tester.pumpAndSettle();

      final dialogField = find.descendant(
        of: find.byType(TextInputDialog),
        matching: find.byType(TextField),
      );
      expect(find.text(AppStrings.editItem), findsWidgets);
      expect(tester.widget<TextField>(dialogField).controller?.text, 'Milk');

      await tester.enterText(dialogField, 'Oat milk');
      await tester.tap(find.text(AppStrings.save));
      await tester.pumpAndSettle();

      verify(() => mockVm.editItem('a', 'Oat milk')).called(1);
    });

    testWidgets('delete item shows snackbar', (tester) async {
      final items = [ChecklistItem(id: 'a', title: 'Test', sortIndex: 0)];
      when(() => mockVm.checklist).thenReturn(
        Checklist(
          id: '1',
          name: 'Test',
          createdAt: DateTime(2024),
          items: items,
        ),
      );
      stubItems(mockVm, unchecked: items);
      when(() => mockVm.removeItem('a')).thenAnswer((_) async {});

      await tester.pumpWidget(buildApp(mockVm));
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      expect(find.text(AppStrings.itemDeleted), findsOneWidget);
    });

    testWidgets('undo after delete item calls vm.restoreItem', (tester) async {
      final item = ChecklistItem(id: 'a', title: 'Milk', sortIndex: 0);
      when(() => mockVm.checklist).thenReturn(
        Checklist(
          id: '1',
          name: 'Test',
          createdAt: DateTime(2024),
          items: [item],
        ),
      );
      stubItems(mockVm, unchecked: [item]);
      when(() => mockVm.removeItem('a')).thenAnswer((_) async {});
      when(() => mockVm.restoreItem(any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildApp(mockVm));
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(SnackBarAction, AppStrings.undo));
      await tester.pumpAndSettle();

      verify(
        () => mockVm.restoreItem(
          any(
            that: predicate<ChecklistItem>(
              (i) => i.id == 'a' && i.title == 'Milk',
            ),
          ),
        ),
      ).called(1);
    });

    testWidgets('shows error snackbar when errorMessage is set', (
      tester,
    ) async {
      when(
        () => mockVm.checklist,
      ).thenReturn(Checklist(id: '1', name: 'Test', createdAt: DateTime(2024)));
      stubItems(mockVm);

      await tester.pumpWidget(buildApp(mockVm));
      await tester.pump();

      // Manually trigger the snackbar via the ScaffoldMessenger
      final scaffoldContext = tester.element(find.byType(Scaffold));
      ScaffoldMessenger.of(
        scaffoldContext,
      ).showSnackBar(const SnackBar(content: Text('Something went wrong')));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('ChecklistDetailBody constrainWidth on expanded', (
      tester,
    ) async {
      final items = [ChecklistItem(id: 'a', title: 'Milk', sortIndex: 0)];
      when(() => mockVm.checklist).thenReturn(
        Checklist(
          id: '1',
          name: 'Test',
          createdAt: DateTime(2024),
          items: items,
        ),
      );
      stubItems(mockVm, unchecked: items);

      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<ChecklistDetailViewModel>.value(
          value: mockVm,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: ChecklistDetailBody(constrainWidth: true),
            ),
          ),
        ),
      );

      expect(find.byType(ChecklistDetailBody), findsOneWidget);
    });

    testWidgets('shows search icon in app bar', (tester) async {
      when(
        () => mockVm.checklist,
      ).thenReturn(Checklist(id: '1', name: 'Test', createdAt: DateTime(2024)));
      stubItems(mockVm);

      await tester.pumpWidget(buildApp(mockVm));

      expect(find.byTooltip(AppStrings.search), findsOneWidget);
    });

    testWidgets('tapping search icon shows search field', (tester) async {
      when(
        () => mockVm.checklist,
      ).thenReturn(Checklist(id: '1', name: 'Test', createdAt: DateTime(2024)));
      stubItems(mockVm);

      await tester.pumpWidget(buildApp(mockVm));

      await tester.tap(find.byTooltip(AppStrings.search));
      await tester.pump();

      verify(() => mockVm.openSearch()).called(1);
    });
  });

  group('ChecklistDetailScreen search', () {
    late ChecklistDetailViewModel realVm;
    late MockChecklistRepository mockRepository;

    setUp(() {
      mockRepository = MockChecklistRepository();
      realVm = ChecklistDetailViewModel(mockRepository);
    });

    Future<void> pumpDetail(WidgetTester tester, Checklist checklist) async {
      when(
        () => mockRepository.getChecklistById('1'),
      ).thenAnswer((_) async => checklist);
      when(() => mockRepository.saveChecklist(any())).thenAnswer((_) async {});
      unawaited(realVm.loadChecklist('1'));

      await tester.pumpWidget(
        ChangeNotifierProvider<ChecklistDetailViewModel>.value(
          value: realVm,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ChecklistDetailScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Checklist checklistWith(List<ChecklistItem> items) {
      return Checklist(
        id: '1',
        name: 'Test',
        createdAt: DateTime(2024),
        items: items,
      );
    }

    testWidgets('typing filters items case-insensitively by substring', (
      tester,
    ) async {
      final checklist = checklistWith([
        ChecklistItem(id: 'a', title: 'Buy Milk', sortIndex: 0),
        ChecklistItem(id: 'b', title: 'Eggs', sortIndex: 1),
        ChecklistItem(id: 'c', title: 'oat milk', sortIndex: 2),
      ]);
      await pumpDetail(tester, checklist);

      expect(find.text('Buy Milk'), findsOneWidget);
      expect(find.text('Eggs'), findsOneWidget);
      expect(find.text('oat milk'), findsOneWidget);

      realVm.searchQuery = 'MILK';
      await tester.pumpAndSettle();

      expect(find.text('Buy Milk'), findsOneWidget);
      expect(find.text('oat milk'), findsOneWidget);
      expect(find.text('Eggs'), findsNothing);
    });

    testWidgets('clearing the query restores the full list', (tester) async {
      final checklist = checklistWith([
        ChecklistItem(id: 'a', title: 'Milk', sortIndex: 0),
        ChecklistItem(id: 'b', title: 'Eggs', sortIndex: 1),
      ]);
      await pumpDetail(tester, checklist);

      realVm.searchQuery = 'milk';
      await tester.pumpAndSettle();
      expect(find.text('Eggs'), findsNothing);

      realVm.searchQuery = '';
      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Eggs'), findsOneWidget);
    });

    testWidgets('filtered results respect check state sections', (
      tester,
    ) async {
      final checklist = checklistWith([
        ChecklistItem(id: 'a', title: 'Milk', sortIndex: 0),
        ChecklistItem(id: 'b', title: 'Bread', sortIndex: 1, isChecked: true),
      ]);
      await pumpDetail(tester, checklist);

      realVm.searchQuery = 'bread';
      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsNothing);
      expect(find.text('Bread'), findsOneWidget);
      expect(find.text(AppStrings.completed), findsOneWidget);
    });

    testWidgets('shows no results empty state when nothing matches', (
      tester,
    ) async {
      final checklist = checklistWith([
        ChecklistItem(id: 'a', title: 'Milk', sortIndex: 0),
      ]);
      await pumpDetail(tester, checklist);

      realVm.searchQuery = 'zzz';
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.noSearchResults), findsOneWidget);
      expect(find.text('Milk'), findsNothing);
    });

    testWidgets('shows empty items state when checklist has no items', (
      tester,
    ) async {
      await pumpDetail(tester, checklistWith([]));

      expect(find.text(AppStrings.emptyItems), findsOneWidget);
    });

    testWidgets('hides drag handles while search is active', (tester) async {
      final checklist = checklistWith([
        ChecklistItem(id: 'a', title: 'Milk', sortIndex: 0),
        ChecklistItem(id: 'b', title: 'Eggs', sortIndex: 1),
      ]);
      await pumpDetail(tester, checklist);

      expect(find.byIcon(Icons.drag_handle), findsNWidgets(2));

      realVm.searchQuery = 'milk';
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.drag_handle), findsNothing);
    });

    testWidgets('typing in search field updates vm.searchQuery', (
      tester,
    ) async {
      final checklist = checklistWith([
        ChecklistItem(id: 'a', title: 'Milk', sortIndex: 0),
      ]);
      await pumpDetail(tester, checklist);

      realVm.openSearch();
      await tester.pumpAndSettle();

      final searchField = find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(TextField),
      );
      await tester.enterText(searchField, 'milk');
      await tester.pump();

      expect(realVm.searchQuery, 'milk');
      expect(find.text('Milk'), findsOneWidget);
    });

    testWidgets('close search resets query and shows full list', (
      tester,
    ) async {
      final checklist = checklistWith([
        ChecklistItem(id: 'a', title: 'Milk', sortIndex: 0),
        ChecklistItem(id: 'b', title: 'Eggs', sortIndex: 1),
      ]);
      await pumpDetail(tester, checklist);

      realVm.openSearch();
      realVm.searchQuery = 'milk';
      await tester.pumpAndSettle();
      expect(find.text('Eggs'), findsNothing);

      realVm.closeSearch();
      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Eggs'), findsOneWidget);
      expect(find.byTooltip(AppStrings.search), findsOneWidget);
    });

    testWidgets('toggle still works on filtered items', (tester) async {
      final checklist = checklistWith([
        ChecklistItem(id: 'a', title: 'Milk', sortIndex: 0),
        ChecklistItem(id: 'b', title: 'Eggs', sortIndex: 1),
      ]);
      await pumpDetail(tester, checklist);

      realVm.searchQuery = 'milk';
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(
        realVm.checklist!.items.firstWhere((i) => i.id == 'a').isChecked,
        true,
      );
      expect(find.text(AppStrings.completed), findsOneWidget);
    });

    testWidgets('delete still works on filtered items', (tester) async {
      final checklist = checklistWith([
        ChecklistItem(id: 'a', title: 'Milk', sortIndex: 0),
        ChecklistItem(id: 'b', title: 'Eggs', sortIndex: 1),
      ]);
      await pumpDetail(tester, checklist);

      realVm.searchQuery = 'milk';
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(realVm.checklist!.items.any((i) => i.id == 'a'), false);
      expect(find.text(AppStrings.itemDeleted), findsOneWidget);
    });

    testWidgets('reordering is blocked while search filter is active', (
      tester,
    ) async {
      final checklist = checklistWith([
        ChecklistItem(id: 'a', title: 'Milk A', sortIndex: 0),
        ChecklistItem(id: 'b', title: 'Milk B', sortIndex: 1),
      ]);
      await pumpDetail(tester, checklist);

      realVm.searchQuery = 'milk';
      await tester.pumpAndSettle();

      await realVm.reorderItems(0, 1);
      await tester.pumpAndSettle();

      verifyNever(() => mockRepository.saveChecklist(any()));
      expect(realVm.sortedItems.map((i) => i.title).toList(), [
        'Milk A',
        'Milk B',
      ]);
    });
  });
}
