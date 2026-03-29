import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:reusable_checklists/core/constants/app_strings.dart';
import 'package:reusable_checklists/core/constants/app_theme.dart';
import 'package:reusable_checklists/data/models/checklist.dart';
import 'package:reusable_checklists/data/repositories/checklist_repository.dart';
import 'package:reusable_checklists/viewmodels/checklist_list_viewmodel.dart';
import 'package:reusable_checklists/views/screens/checklist_list_screen.dart';

class MockChecklistRepository extends Mock implements ChecklistRepository {}

class MockChecklistListViewModel extends Mock
    implements ChecklistListViewModel {}

Widget buildApp(ChecklistListViewModel vm) {
  return MultiProvider(
    providers: [
      Provider<ChecklistRepository>(
        create: (_) => MockChecklistRepository(),
      ),
      ChangeNotifierProvider<ChecklistListViewModel>.value(value: vm),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const ChecklistListScreen(),
    ),
  );
}

void main() {
  late MockChecklistListViewModel mockVm;

  setUp(() {
    mockVm = MockChecklistListViewModel();
    when(() => mockVm.errorMessage).thenReturn(null);
  });

  setUpAll(() {
    registerFallbackValue(Checklist(
      id: 'fallback',
      name: 'fallback',
      createdAt: DateTime(2024),
    ));
  });

  group('ChecklistListScreen', () {
    testWidgets('shows loading indicator when isLoading', (tester) async {
      when(() => mockVm.isLoading).thenReturn(true);
      when(() => mockVm.checklists).thenReturn([]);

      await tester.pumpWidget(buildApp(mockVm));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no checklists', (tester) async {
      when(() => mockVm.isLoading).thenReturn(false);
      when(() => mockVm.checklists).thenReturn([]);

      await tester.pumpWidget(buildApp(mockVm));

      expect(find.text(AppStrings.emptyChecklists), findsOneWidget);
      expect(find.text(AppStrings.emptyChecklistsSubtitle), findsOneWidget);
    });

    testWidgets('shows checklist tiles', (tester) async {
      when(() => mockVm.isLoading).thenReturn(false);
      when(() => mockVm.checklists).thenReturn([
        Checklist(id: '1', name: 'Groceries', createdAt: DateTime(2024)),
        Checklist(id: '2', name: 'Travel', createdAt: DateTime(2024)),
      ]);

      await tester.pumpWidget(buildApp(mockVm));

      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Travel'), findsOneWidget);
    });

    testWidgets('shows app title', (tester) async {
      when(() => mockVm.isLoading).thenReturn(false);
      when(() => mockVm.checklists).thenReturn([]);

      await tester.pumpWidget(buildApp(mockVm));

      expect(find.text(AppStrings.appTitle), findsOneWidget);
    });

    testWidgets('shows FAB', (tester) async {
      when(() => mockVm.isLoading).thenReturn(false);
      when(() => mockVm.checklists).thenReturn([]);

      await tester.pumpWidget(buildApp(mockVm));

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('FAB opens new checklist dialog', (tester) async {
      when(() => mockVm.isLoading).thenReturn(false);
      when(() => mockVm.checklists).thenReturn([]);

      await tester.pumpWidget(buildApp(mockVm));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.newChecklist), findsOneWidget);
    });

    testWidgets('creating checklist via dialog calls createChecklist',
        (tester) async {
      when(() => mockVm.isLoading).thenReturn(false);
      when(() => mockVm.checklists).thenReturn([]);
      when(() => mockVm.createChecklist(any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildApp(mockVm));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'New List');
      await tester.pump();
      await tester.tap(find.text(AppStrings.create));
      await tester.pumpAndSettle();

      verify(() => mockVm.createChecklist('New List')).called(1);
    });

    testWidgets('delete shows snackbar with undo', (tester) async {
      final checklist =
          Checklist(id: '1', name: 'Groceries', createdAt: DateTime(2024));
      when(() => mockVm.isLoading).thenReturn(false);
      when(() => mockVm.checklists).thenReturn([checklist]);
      when(() => mockVm.deleteChecklist('1')).thenAnswer((_) async {});

      await tester.pumpWidget(buildApp(mockVm));

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      expect(find.text(AppStrings.checklistDeleted), findsOneWidget);
      expect(find.text(AppStrings.undo), findsOneWidget);
    });

    testWidgets('undo action calls saveChecklist', (tester) async {
      final checklist =
          Checklist(id: '1', name: 'Groceries', createdAt: DateTime(2024));
      when(() => mockVm.isLoading).thenReturn(false);
      when(() => mockVm.checklists).thenReturn([checklist]);
      when(() => mockVm.deleteChecklist('1')).thenAnswer((_) async {});
      when(() => mockVm.saveChecklist(any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildApp(mockVm));

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(SnackBarAction, AppStrings.undo));
      await tester.pumpAndSettle();

      verify(() => mockVm.saveChecklist(checklist)).called(1);
    });
  });
}
