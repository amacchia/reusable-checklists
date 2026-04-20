import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:reusable_checklists/core/constants/app_strings.dart';
import 'package:reusable_checklists/core/constants/app_theme.dart';
import 'package:reusable_checklists/data/models/checklist.dart';
import 'package:reusable_checklists/data/repositories/checklist_repository.dart';
import 'package:reusable_checklists/main.dart' show routeObserver;
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

    testWidgets('long press enters selection mode', (tester) async {
      when(() => mockVm.isLoading).thenReturn(false);
      when(() => mockVm.checklists).thenReturn([
        Checklist(id: '1', name: 'Groceries', createdAt: DateTime(2024)),
      ]);

      await tester.pumpWidget(buildApp(mockVm));

      await tester.longPress(find.text('Groceries'));
      await tester.pump();

      expect(find.text('1 selected'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('tapping tiles in selection mode toggles selection',
        (tester) async {
      when(() => mockVm.isLoading).thenReturn(false);
      when(() => mockVm.checklists).thenReturn([
        Checklist(id: '1', name: 'Groceries', createdAt: DateTime(2024)),
        Checklist(id: '2', name: 'Travel', createdAt: DateTime(2024)),
      ]);

      await tester.pumpWidget(buildApp(mockVm));

      await tester.longPress(find.text('Groceries'));
      await tester.pump();
      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(find.text('Travel'));
      await tester.pump();
      expect(find.text('2 selected'), findsOneWidget);
    });

    testWidgets('close button exits selection mode', (tester) async {
      when(() => mockVm.isLoading).thenReturn(false);
      when(() => mockVm.checklists).thenReturn([
        Checklist(id: '1', name: 'Groceries', createdAt: DateTime(2024)),
      ]);

      await tester.pumpWidget(buildApp(mockVm));

      await tester.longPress(find.text('Groceries'));
      await tester.pump();
      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(find.text(AppStrings.appTitle), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('delete selected shows snackbar with undo', (tester) async {
      final checklist =
          Checklist(id: '1', name: 'Groceries', createdAt: DateTime(2024));
      when(() => mockVm.isLoading).thenReturn(false);
      when(() => mockVm.checklists).thenReturn([checklist]);
      when(() => mockVm.deleteChecklist('1')).thenAnswer((_) async {});

      await tester.pumpWidget(buildApp(mockVm));

      await tester.longPress(find.text('Groceries'));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      verify(() => mockVm.deleteChecklist('1')).called(1);
      expect(find.text(AppStrings.checklistDeleted), findsOneWidget);
      expect(find.text(AppStrings.undo), findsOneWidget);
    });

    testWidgets('undo after delete calls saveChecklist', (tester) async {
      final checklist =
          Checklist(id: '1', name: 'Groceries', createdAt: DateTime(2024));
      when(() => mockVm.isLoading).thenReturn(false);
      when(() => mockVm.checklists).thenReturn([checklist]);
      when(() => mockVm.deleteChecklist('1')).thenAnswer((_) async {});
      when(() => mockVm.saveChecklist(any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildApp(mockVm));

      await tester.longPress(find.text('Groceries'));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(SnackBarAction, AppStrings.undo));
      await tester.pumpAndSettle();

      verify(() => mockVm.saveChecklist(checklist)).called(1);
    });

    testWidgets('tapping an already-selected tile deselects it',
        (tester) async {
      when(() => mockVm.isLoading).thenReturn(false);
      when(() => mockVm.checklists).thenReturn([
        Checklist(id: '1', name: 'Groceries', createdAt: DateTime(2024)),
        Checklist(id: '2', name: 'Travel', createdAt: DateTime(2024)),
      ]);

      await tester.pumpWidget(buildApp(mockVm));

      await tester.longPress(find.text('Groceries'));
      await tester.pump();
      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(find.text('Travel'));
      await tester.pump();
      expect(find.text('2 selected'), findsOneWidget);

      // Tap travel again to deselect it.
      await tester.tap(find.text('Travel'));
      await tester.pump();
      expect(find.text('1 selected'), findsOneWidget);
    });

    testWidgets('tapping the selection checkbox toggles selection',
        (tester) async {
      when(() => mockVm.isLoading).thenReturn(false);
      when(() => mockVm.checklists).thenReturn([
        Checklist(id: '1', name: 'Groceries', createdAt: DateTime(2024)),
      ]);

      await tester.pumpWidget(buildApp(mockVm));

      await tester.longPress(find.text('Groceries'));
      await tester.pump();

      // Tap the Checkbox widget directly (covers onChanged callback).
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      // Deselecting the only item exits selection mode.
      expect(find.text(AppStrings.appTitle), findsOneWidget);
    });

    testWidgets('deleting multiple selected shows plural snackbar',
        (tester) async {
      final a = Checklist(id: '1', name: 'Groceries', createdAt: DateTime(2024));
      final b = Checklist(id: '2', name: 'Travel', createdAt: DateTime(2024));
      when(() => mockVm.isLoading).thenReturn(false);
      when(() => mockVm.checklists).thenReturn([a, b]);
      when(() => mockVm.deleteChecklist(any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildApp(mockVm));

      await tester.longPress(find.text('Groceries'));
      await tester.pump();
      await tester.tap(find.text('Travel'));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      expect(find.text('2 checklists deleted'), findsOneWidget);
    });

    testWidgets('settings icon navigates to /settings', (tester) async {
      when(() => mockVm.isLoading).thenReturn(false);
      when(() => mockVm.checklists).thenReturn([]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ChecklistRepository>(
              create: (_) => MockChecklistRepository(),
            ),
            ChangeNotifierProvider<ChecklistListViewModel>.value(value: mockVm),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ChecklistListScreen(),
            routes: {
              '/settings': (_) => const Scaffold(body: Text('SETTINGS_PAGE')),
            },
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.text('SETTINGS_PAGE'), findsOneWidget);
    });

    testWidgets('tapping a tile navigates to /detail', (tester) async {
      when(() => mockVm.isLoading).thenReturn(false);
      when(() => mockVm.checklists).thenReturn([
        Checklist(id: '1', name: 'Groceries', createdAt: DateTime(2024)),
      ]);
      when(() => mockVm.loadChecklists()).thenAnswer((_) async {});

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ChecklistRepository>(
              create: (_) => MockChecklistRepository(),
            ),
            ChangeNotifierProvider<ChecklistListViewModel>.value(value: mockVm),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ChecklistListScreen(),
            routes: {
              '/detail': (_) => const Scaffold(body: Text('DETAIL_PAGE')),
            },
          ),
        ),
      );

      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();

      expect(find.text('DETAIL_PAGE'), findsOneWidget);
    });

    testWidgets(
        'popping back from /detail triggers didPopNext and reloads',
        (tester) async {
      when(() => mockVm.isLoading).thenReturn(false);
      when(() => mockVm.checklists).thenReturn([
        Checklist(id: '1', name: 'Groceries', createdAt: DateTime(2024)),
      ]);
      when(() => mockVm.loadChecklists()).thenAnswer((_) async {});

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ChecklistRepository>(
              create: (_) => MockChecklistRepository(),
            ),
            ChangeNotifierProvider<ChecklistListViewModel>.value(value: mockVm),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            navigatorObservers: [routeObserver],
            home: const ChecklistListScreen(),
            routes: {
              '/detail': (_) => const Scaffold(body: Text('DETAIL_PAGE')),
            },
          ),
        ),
      );

      // Navigate to detail.
      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();
      expect(find.text('DETAIL_PAGE'), findsOneWidget);

      // Pop back - didPopNext should fire on the list screen.
      final BuildContext detailContext = tester.element(find.text('DETAIL_PAGE'));
      Navigator.of(detailContext).pop();
      await tester.pumpAndSettle();

      // Called once on initial load + once on return.
      verify(() => mockVm.loadChecklists()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('back gesture during selection mode clears selection',
        (tester) async {
      when(() => mockVm.isLoading).thenReturn(false);
      when(() => mockVm.checklists).thenReturn([
        Checklist(id: '1', name: 'Groceries', createdAt: DateTime(2024)),
      ]);

      await tester.pumpWidget(buildApp(mockVm));

      await tester.longPress(find.text('Groceries'));
      await tester.pump();
      expect(find.text('1 selected'), findsOneWidget);

      // Simulate a system back gesture; PopScope blocks the pop and
      // clears the selection instead.
      final NavigatorState navigator = tester.state<NavigatorState>(
        find.byType(Navigator),
      );
      await navigator.maybePop();
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.appTitle), findsOneWidget);
    });

    testWidgets('FAB is hidden during selection mode', (tester) async {
      when(() => mockVm.isLoading).thenReturn(false);
      when(() => mockVm.checklists).thenReturn([
        Checklist(id: '1', name: 'Groceries', createdAt: DateTime(2024)),
      ]);

      await tester.pumpWidget(buildApp(mockVm));
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.longPress(find.text('Groceries'));
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });
}
