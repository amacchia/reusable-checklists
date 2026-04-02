import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:reusable_checklists/core/constants/app_strings.dart';
import 'package:reusable_checklists/core/constants/app_theme.dart';
import 'package:reusable_checklists/data/models/checklist.dart';
import 'package:reusable_checklists/data/models/checklist_item.dart';
import 'package:reusable_checklists/viewmodels/checklist_detail_viewmodel.dart';
import 'package:reusable_checklists/views/screens/checklist_detail_screen.dart';

class MockChecklistDetailViewModel extends Mock
    implements ChecklistDetailViewModel {}

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

  setUp(() {
    mockVm = MockChecklistDetailViewModel();
    when(() => mockVm.errorMessage).thenReturn(null);
  });

  /// Helper to stub all list getters on the mock VM.
  void stubItems(
    MockChecklistDetailViewModel vm, {
    List<ChecklistItem> unchecked = const [],
    List<ChecklistItem> checked = const [],
  }) {
    when(() => vm.sortedItems).thenReturn([...unchecked, ...checked]);
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
      when(() => mockVm.checklist).thenReturn(
        Checklist(id: '1', name: 'Test', createdAt: DateTime(2024)),
      );
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

    testWidgets('shows Completed section when checked items exist',
        (tester) async {
      final unchecked = [
        ChecklistItem(id: 'a', title: 'Milk', sortIndex: 0),
      ];
      final checked = [
        ChecklistItem(
            id: 'b', title: 'Bread', sortIndex: 1, isChecked: true),
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

    testWidgets('hides Completed header when no checked items',
        (tester) async {
      final items = [
        ChecklistItem(id: 'a', title: 'Milk', sortIndex: 0),
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

      expect(find.text('Completed'), findsNothing);
    });

    testWidgets('shows Check All and Uncheck All buttons', (tester) async {
      when(() => mockVm.checklist).thenReturn(
        Checklist(id: '1', name: 'Test', createdAt: DateTime(2024)),
      );
      stubItems(mockVm);

      await tester.pumpWidget(buildApp(mockVm));

      expect(find.text(AppStrings.checkAll), findsOneWidget);
      expect(find.text(AppStrings.uncheckAll), findsOneWidget);
    });

    testWidgets('Check All calls vm.checkAll', (tester) async {
      final items = [
        ChecklistItem(id: 'a', title: 'Test', sortIndex: 0),
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
      when(() => mockVm.checkAll()).thenAnswer((_) async {});

      await tester.pumpWidget(buildApp(mockVm));
      await tester.tap(find.text(AppStrings.checkAll));

      verify(() => mockVm.checkAll()).called(1);
    });

    testWidgets('Uncheck All calls vm.uncheckAll', (tester) async {
      final items = [
        ChecklistItem(id: 'a', title: 'Test', sortIndex: 0),
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
      when(() => mockVm.uncheckAll()).thenAnswer((_) async {});

      await tester.pumpWidget(buildApp(mockVm));
      await tester.tap(find.text(AppStrings.uncheckAll));

      verify(() => mockVm.uncheckAll()).called(1);
    });

    testWidgets('shows add item input bar', (tester) async {
      when(() => mockVm.checklist).thenReturn(
        Checklist(id: '1', name: 'Test', createdAt: DateTime(2024)),
      );
      stubItems(mockVm);

      await tester.pumpWidget(buildApp(mockVm));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text(AppStrings.addItem), findsOneWidget);
    });

    testWidgets('TextField uses sentence capitalization', (tester) async {
      when(() => mockVm.checklist).thenReturn(
        Checklist(id: '1', name: 'Test', createdAt: DateTime(2024)),
      );
      stubItems(mockVm);

      await tester.pumpWidget(buildApp(mockVm));

      final textField =
          tester.widget<TextField>(find.byType(TextField));
      expect(
          textField.textCapitalization, TextCapitalization.sentences);
    });

    testWidgets('add item button calls addItem and clears input',
        (tester) async {
      when(() => mockVm.checklist).thenReturn(
        Checklist(id: '1', name: 'Test', createdAt: DateTime(2024)),
      );
      stubItems(mockVm);
      when(() => mockVm.addItem(any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildApp(mockVm));

      await tester.enterText(find.byType(TextField), 'New item');
      await tester.tap(find.byIcon(Icons.add));

      verify(() => mockVm.addItem('New item')).called(1);
    });

    testWidgets('does not add empty items', (tester) async {
      when(() => mockVm.checklist).thenReturn(
        Checklist(id: '1', name: 'Test', createdAt: DateTime(2024)),
      );
      stubItems(mockVm);

      await tester.pumpWidget(buildApp(mockVm));

      await tester.tap(find.byIcon(Icons.add));

      verifyNever(() => mockVm.addItem(any()));
    });

    testWidgets('toggle calls vm.toggleItem', (tester) async {
      final items = [
        ChecklistItem(id: 'a', title: 'Test', sortIndex: 0),
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
      when(() => mockVm.toggleItem('a')).thenAnswer((_) async {});

      await tester.pumpWidget(buildApp(mockVm));
      await tester.tap(find.byType(Checkbox));

      verify(() => mockVm.toggleItem('a')).called(1);
    });

    testWidgets('add item via keyboard submit', (tester) async {
      when(() => mockVm.checklist).thenReturn(
        Checklist(id: '1', name: 'Test', createdAt: DateTime(2024)),
      );
      stubItems(mockVm);
      when(() => mockVm.addItem(any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildApp(mockVm));

      await tester.enterText(find.byType(TextField), 'Keyboard item');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      verify(() => mockVm.addItem('Keyboard item')).called(1);
    });

    testWidgets('delete item shows snackbar', (tester) async {
      final items = [
        ChecklistItem(id: 'a', title: 'Test', sortIndex: 0),
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
      when(() => mockVm.removeItem('a')).thenAnswer((_) async {});

      await tester.pumpWidget(buildApp(mockVm));
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      expect(find.text(AppStrings.itemDeleted), findsOneWidget);
    });
  });
}
