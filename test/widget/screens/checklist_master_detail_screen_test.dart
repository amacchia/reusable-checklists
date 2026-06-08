import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:reusable_checklists/core/constants/app_strings.dart';
import 'package:reusable_checklists/core/constants/app_theme.dart';
import 'package:reusable_checklists/data/models/checklist.dart';
import 'package:reusable_checklists/data/models/checklist_item.dart';
import 'package:reusable_checklists/data/repositories/checklist_repository.dart';
import 'package:reusable_checklists/viewmodels/checklist_list_viewmodel.dart';
import 'package:reusable_checklists/views/screens/checklist_master_detail_screen.dart';

class MockChecklistRepository extends Mock implements ChecklistRepository {}

class MockChecklistListViewModel extends Mock
    implements ChecklistListViewModel {}

class FakeChecklist extends Fake implements Checklist {}

Widget buildWideApp(ChecklistListViewModel listVm, {ChecklistRepository? repo}) {
  return MultiProvider(
    providers: [
      Provider<ChecklistRepository>.value(
        value: repo ?? MockChecklistRepository(),
      ),
      ChangeNotifierProvider<ChecklistListViewModel>.value(value: listVm),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const SizedBox(
        width: 1000,
        height: 800,
        child: ChecklistMasterDetailScreen(),
      ),
    ),
  );
}

void main() {
  late MockChecklistListViewModel mockListVm;

  setUp(() {
    mockListVm = MockChecklistListViewModel();
    when(() => mockListVm.errorMessage).thenReturn(null);
    when(() => mockListVm.isLoading).thenReturn(false);
    when(() => mockListVm.checklists).thenReturn([]);
  });

  setUpAll(() {
    registerFallbackValue(FakeChecklist());
  });

  group('ChecklistMasterDetailScreen', () {
    testWidgets('shows empty detail panel on wide layout', (tester) async {
      await tester.pumpWidget(buildWideApp(mockListVm));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.selectChecklist), findsOneWidget);
    });

    testWidgets('shows FAB on wide layout', (tester) async {
      await tester.pumpWidget(buildWideApp(mockListVm));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('FAB opens new checklist dialog on wide layout',
        (tester) async {
      await tester.pumpWidget(buildWideApp(mockListVm));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.newChecklist), findsOneWidget);
    });

    testWidgets(
        'creating checklist via dialog calls createChecklist on wide layout',
        (tester) async {
      when(() => mockListVm.createChecklist(any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildWideApp(mockListVm));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'New List');
      await tester.pump();
      await tester.tap(find.text(AppStrings.create));
      await tester.pumpAndSettle();

      verify(() => mockListVm.createChecklist('New List')).called(1);
    });

    testWidgets('shows settings icon on wide layout when not in selection',
        (tester) async {
      when(() => mockListVm.checklists).thenReturn([]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ChecklistRepository>(
                create: (_) => MockChecklistRepository()),
            ChangeNotifierProvider<ChecklistListViewModel>.value(
                value: mockListVm),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SizedBox(
              width: 1000,
              height: 800,
              child: ChecklistMasterDetailScreen(),
            ),
            routes: {
              '/settings': (_) =>
                  const Scaffold(body: Text('SETTINGS_PAGE')),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('settings icon navigates to /settings on wide layout',
        (tester) async {
      when(() => mockListVm.checklists).thenReturn([]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ChecklistRepository>(
                create: (_) => MockChecklistRepository()),
            ChangeNotifierProvider<ChecklistListViewModel>.value(
                value: mockListVm),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SizedBox(
              width: 1000,
              height: 800,
              child: ChecklistMasterDetailScreen(),
            ),
            routes: {
              '/settings': (_) =>
                  const Scaffold(body: Text('SETTINGS_PAGE')),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.text('SETTINGS_PAGE'), findsOneWidget);
    });

    testWidgets('long press enters selection mode on wide layout',
        (tester) async {
      when(() => mockListVm.checklists).thenReturn([
        Checklist(id: '1', name: 'Groceries', createdAt: DateTime(2024)),
      ]);

      await tester.pumpWidget(buildWideApp(mockListVm));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Groceries'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.byIcon(Icons.restart_alt), findsOneWidget);
    });

    testWidgets('close button exits selection mode on wide layout',
        (tester) async {
      when(() => mockListVm.checklists).thenReturn([
        Checklist(id: '1', name: 'Groceries', createdAt: DateTime(2024)),
      ]);

      await tester.pumpWidget(buildWideApp(mockListVm));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Groceries'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.appTitle), findsOneWidget);
    });

    testWidgets('FAB hidden during selection mode on wide layout',
        (tester) async {
      when(() => mockListVm.checklists).thenReturn([
        Checklist(id: '1', name: 'Groceries', createdAt: DateTime(2024)),
      ]);

      await tester.pumpWidget(buildWideApp(mockListVm));
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.longPress(find.text('Groceries'));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('delete selected calls deleteChecklist', (tester) async {
      when(() => mockListVm.checklists).thenReturn([
        Checklist(id: '1', name: 'Groceries', createdAt: DateTime(2024)),
      ]);
      when(() => mockListVm.deleteChecklist('1')).thenAnswer((_) async {});

      await tester.pumpWidget(buildWideApp(mockListVm));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Groceries'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      verify(() => mockListVm.deleteChecklist('1')).called(1);
    });

    testWidgets('reset selected calls resetChecklist', (tester) async {
      final checklist = Checklist(
        id: '1',
        name: 'Groceries',
        createdAt: DateTime(2024),
        items: [
          ChecklistItem(
              id: 'a', title: 'Milk', sortIndex: 0, isChecked: true),
        ],
      );
      when(() => mockListVm.checklists).thenReturn([checklist]);
      when(() => mockListVm.resetChecklist('1')).thenAnswer((_) async {});

      await tester.pumpWidget(buildWideApp(mockListVm));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Groceries'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.restart_alt));
      await tester.pumpAndSettle();

      verify(() => mockListVm.resetChecklist('1')).called(1);
    });

    testWidgets('tapping checklist selects it in detail panel', (tester) async {
      final repo = MockChecklistRepository();
      final checklist = Checklist(
        id: '1',
        name: 'Groceries',
        createdAt: DateTime(2024),
        items: [ChecklistItem(id: 'a', title: 'Milk', sortIndex: 0)],
      );
      when(() => mockListVm.checklists).thenReturn([checklist]);
      when(() => repo.getChecklistById('1'))
          .thenAnswer((_) async => checklist);

      await tester.pumpWidget(buildWideApp(mockListVm, repo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'tapping already-selected checklist deselects in checkbox',
        (tester) async {
      when(() => mockListVm.checklists).thenReturn([
        Checklist(id: '1', name: 'Groceries', createdAt: DateTime(2024)),
      ]);

      await tester.pumpWidget(buildWideApp(mockListVm));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Groceries'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.appTitle), findsOneWidget);
    });

    testWidgets(
        'back gesture during selection mode clears selection on wide layout',
        (tester) async {
      when(() => mockListVm.checklists).thenReturn([
        Checklist(id: '1', name: 'Groceries', createdAt: DateTime(2024)),
      ]);

      await tester.pumpWidget(buildWideApp(mockListVm));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Groceries'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close), findsOneWidget);

      final navigator =
          tester.state<NavigatorState>(find.byType(Navigator));
      await navigator.maybePop();
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.appTitle), findsOneWidget);
    });

    testWidgets(
        'back gesture when checklist selected deselects on wide layout',
        (tester) async {
      final repo = MockChecklistRepository();
      final checklist = Checklist(
        id: '1',
        name: 'Groceries',
        createdAt: DateTime(2024),
      );
      when(() => mockListVm.checklists).thenReturn([checklist]);
      when(() => repo.getChecklistById('1'))
          .thenAnswer((_) async => checklist);

      await tester.pumpWidget(buildWideApp(mockListVm, repo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();

      final navigator =
          tester.state<NavigatorState>(find.byType(Navigator));
      await navigator.maybePop();
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.selectChecklist), findsOneWidget);
    });

    testWidgets('selecting another checklist switches detail', (tester) async {
      final repo = MockChecklistRepository();
      final a =
          Checklist(id: '1', name: 'Groceries', createdAt: DateTime(2024));
      final b =
          Checklist(id: '2', name: 'Travel', createdAt: DateTime(2024));
      when(() => mockListVm.checklists).thenReturn([a, b]);
      when(() => repo.getChecklistById('1')).thenAnswer((_) async => a);
      when(() => repo.getChecklistById('2')).thenAnswer((_) async => b);

      await tester.pumpWidget(buildWideApp(mockListVm, repo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Travel'));
      await tester.pumpAndSettle();
    });
  });
}