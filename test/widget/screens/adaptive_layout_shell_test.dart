import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:reusable_checklists/core/constants/app_strings.dart';
import 'package:reusable_checklists/data/models/checklist.dart';
import 'package:reusable_checklists/data/repositories/checklist_repository.dart';
import 'package:reusable_checklists/data/repositories/settings_repository.dart';
import 'package:reusable_checklists/viewmodels/checklist_list_viewmodel.dart';
import 'package:reusable_checklists/viewmodels/theme_viewmodel.dart';
import 'package:reusable_checklists/views/screens/adaptive_layout_shell.dart';

class MockChecklistRepository extends Mock implements ChecklistRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockChecklistRepository mockRepo;
  late MockSettingsRepository mockSettingsRepo;

  setUp(() {
    mockRepo = MockChecklistRepository();
    mockSettingsRepo = MockSettingsRepository();
    when(() => mockRepo.getAllChecklists()).thenAnswer((_) async => []);
    when(() => mockSettingsRepo.getThemeMode()).thenReturn(ThemeMode.system);
    when(() => mockSettingsRepo.setThemeMode(any())).thenAnswer((_) async {});
  });

  setUpAll(() {
    registerFallbackValue(
      Checklist(id: 'fallback', name: 'fallback', createdAt: DateTime(2024)),
    );
    registerFallbackValue(ThemeMode.system);
  });

  Widget buildWideApp() {
    return MultiProvider(
      providers: [
        Provider<ChecklistRepository>.value(value: mockRepo),
        ChangeNotifierProvider<ChecklistListViewModel>(
          create: (ctx) {
            final vm = ChecklistListViewModel(ctx.read<ChecklistRepository>());
            return vm;
          },
        ),
        Provider<SettingsRepository>.value(value: mockSettingsRepo),
        ChangeNotifierProvider<ThemeViewModel>(
          create: (ctx) => ThemeViewModel(ctx.read<SettingsRepository>()),
        ),
      ],
      child: const MaterialApp(
        home: SizedBox(width: 1000, height: 800, child: AdaptiveLayoutShell()),
      ),
    );
  }

  group('AdaptiveLayoutShell', () {
    testWidgets('shows NavigationRail on wide layout', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildWideApp());
      await tester.pump();

      expect(find.byType(NavigationRail), findsOneWidget);
    });

    testWidgets('tapping settings rail destination updates selection', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildWideApp());
      await tester.pump();

      await tester.tap(find.text(AppStrings.settings));
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, 1);
    });

    testWidgets('tapping checklists rail destination updates selection', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildWideApp());
      await tester.pump();

      // First go to settings
      await tester.tap(find.text(AppStrings.settings));
      await tester.pumpAndSettle();

      // Then back to checklists
      await tester.tap(find.text(AppStrings.checklists));
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, 0);
    });
  });
}
