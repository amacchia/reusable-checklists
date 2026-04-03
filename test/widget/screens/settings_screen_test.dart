import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:reusable_checklists/core/constants/app_strings.dart';
import 'package:reusable_checklists/core/constants/app_theme.dart';
import 'package:reusable_checklists/data/repositories/settings_repository.dart';
import 'package:reusable_checklists/viewmodels/theme_viewmodel.dart';
import 'package:reusable_checklists/views/screens/settings_screen.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

Widget buildApp(ThemeViewModel vm) {
  return ChangeNotifierProvider<ThemeViewModel>.value(
    value: vm,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const SettingsScreen(),
    ),
  );
}

void main() {
  late MockSettingsRepository mockRepo;
  late ThemeViewModel themeVm;

  setUpAll(() {
    registerFallbackValue(ThemeMode.system);
  });

  setUp(() {
    mockRepo = MockSettingsRepository();
    when(() => mockRepo.getThemeMode()).thenReturn(ThemeMode.system);
    when(() => mockRepo.setThemeMode(any())).thenAnswer((_) async {});
    themeVm = ThemeViewModel(mockRepo);
  });

  group('SettingsScreen', () {
    testWidgets('shows settings title', (tester) async {
      await tester.pumpWidget(buildApp(themeVm));

      expect(find.text(AppStrings.settings), findsOneWidget);
    });

    testWidgets('shows theme section', (tester) async {
      await tester.pumpWidget(buildApp(themeVm));

      expect(find.text(AppStrings.theme), findsOneWidget);
      expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
    });

    testWidgets('shows all theme options', (tester) async {
      await tester.pumpWidget(buildApp(themeVm));

      expect(find.text(AppStrings.themeSystem), findsOneWidget);
      expect(find.text(AppStrings.themeLight), findsOneWidget);
      expect(find.text(AppStrings.themeDark), findsOneWidget);
    });

    testWidgets('system theme is selected by default', (tester) async {
      await tester.pumpWidget(buildApp(themeVm));

      final segmentedButton = tester.widget<SegmentedButton<ThemeMode>>(
        find.byType(SegmentedButton<ThemeMode>),
      );
      expect(segmentedButton.selected, {ThemeMode.system});
    });

    testWidgets('tapping light theme calls setThemeMode', (tester) async {
      await tester.pumpWidget(buildApp(themeVm));

      await tester.tap(find.text(AppStrings.themeLight));
      await tester.pumpAndSettle();

      verify(() => mockRepo.setThemeMode(ThemeMode.light)).called(1);
    });

    testWidgets('tapping dark theme calls setThemeMode', (tester) async {
      await tester.pumpWidget(buildApp(themeVm));

      await tester.tap(find.text(AppStrings.themeDark));
      await tester.pumpAndSettle();

      verify(() => mockRepo.setThemeMode(ThemeMode.dark)).called(1);
    });

    testWidgets('shows source code link', (tester) async {
      await tester.pumpWidget(buildApp(themeVm));

      expect(find.text(AppStrings.sourceCode), findsOneWidget);
      expect(find.byIcon(Icons.code), findsOneWidget);
    });

    testWidgets('does not show source code URL', (tester) async {
      await tester.pumpWidget(buildApp(themeVm));

      expect(find.text(AppStrings.sourceCodeUrl), findsNothing);
    });
  });
}
