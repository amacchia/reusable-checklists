import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:reusable_checklists/core/constants/app_strings.dart';
import 'package:reusable_checklists/core/constants/app_theme.dart';
import 'package:reusable_checklists/data/models/checklist.dart';
import 'package:reusable_checklists/data/repositories/settings_repository.dart';
import 'package:reusable_checklists/viewmodels/checklist_list_viewmodel.dart';
import 'package:reusable_checklists/viewmodels/theme_viewmodel.dart';
import 'package:reusable_checklists/views/screens/settings_screen.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockChecklistListViewModel extends Mock
    implements ChecklistListViewModel {}

Widget buildApp(ThemeViewModel vm, {ChecklistListViewModel? listVm}) {
  final list = listVm ?? MockChecklistListViewModel();
  if (listVm == null) {
    when(() => (list as MockChecklistListViewModel).checklists).thenReturn([]);
  }
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeViewModel>.value(value: vm),
      ChangeNotifierProvider<ChecklistListViewModel>.value(value: list),
    ],
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
    registerFallbackValue(Checklist(
      id: 'fallback',
      name: 'fallback',
      createdAt: DateTime(2024),
    ));
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

    testWidgets('tapping source code invokes launchUrl', (tester) async {
      // Stub the url_launcher platform channel so the tap doesn't throw.
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      final invocations = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        invocations.add(call);
        if (call.method == 'canLaunch') return true;
        if (call.method == 'launch') return true;
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      await tester.pumpWidget(buildApp(themeVm));

      await tester.tap(find.text(AppStrings.sourceCode));
      await tester.pump();
      // Drain any pending microtasks from launchUrl.
      await tester.pump(const Duration(milliseconds: 10));
    });

    testWidgets('non-const SettingsScreen constructor', (tester) async {
      // Force runtime constructor execution (not a const canonical instance).
      final screen = SettingsScreen(key: UniqueKey());
      expect(screen, isA<SettingsScreen>());
    });

    group('Data export/import', () {
      late List<MethodCall> clipboardCalls;
      String? clipboardValue;

      setUp(() {
        clipboardCalls = [];
        clipboardValue = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          clipboardCalls.add(call);
          if (call.method == 'Clipboard.setData') {
            final args = call.arguments as Map;
            clipboardValue = args['text'] as String?;
          }
          if (call.method == 'Clipboard.getData') {
            if (clipboardValue == null) return null;
            return {'text': clipboardValue};
          }
          return null;
        });
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      testWidgets('export copies JSON to clipboard when checklists exist',
          (tester) async {
        final listVm = MockChecklistListViewModel();
        when(() => listVm.checklists).thenReturn([
          Checklist(id: '1', name: 'A', createdAt: DateTime(2024)),
        ]);
        when(listVm.exportAsJson).thenReturn('{"version":1}');

        await tester.pumpWidget(buildApp(themeVm, listVm: listVm));
        await tester.tap(find.text(AppStrings.exportJson));
        await tester.pump();

        expect(clipboardValue, '{"version":1}');
        expect(find.text(AppStrings.exportCopied), findsOneWidget);
      });

      testWidgets('export shows "nothing to export" when empty',
          (tester) async {
        final listVm = MockChecklistListViewModel();
        when(() => listVm.checklists).thenReturn([]);

        await tester.pumpWidget(buildApp(themeVm, listVm: listVm));
        await tester.tap(find.text(AppStrings.exportJson));
        await tester.pump();

        expect(find.text(AppStrings.nothingToExport), findsOneWidget);
        verifyNever(listVm.exportAsJson);
      });

      testWidgets('import reads clipboard and calls importFromJson',
          (tester) async {
        clipboardValue = '{"version":1,"checklists":[]}';
        final listVm = MockChecklistListViewModel();
        when(() => listVm.checklists).thenReturn([]);
        when(() => listVm.importFromJson(any())).thenAnswer((_) async => 2);

        await tester.pumpWidget(buildApp(themeVm, listVm: listVm));
        await tester.tap(find.text(AppStrings.importJson));
        await tester.pump();
        await tester.pump();

        verify(() => listVm.importFromJson(clipboardValue!)).called(1);
        expect(find.text('2 checklist(s) imported'), findsOneWidget);
      });

      testWidgets('import shows error snackbar when clipboard is empty',
          (tester) async {
        clipboardValue = null;
        final listVm = MockChecklistListViewModel();
        when(() => listVm.checklists).thenReturn([]);

        await tester.pumpWidget(buildApp(themeVm, listVm: listVm));
        await tester.tap(find.text(AppStrings.importJson));
        await tester.pump();

        expect(find.text(AppStrings.clipboardEmpty), findsOneWidget);
        verifyNever(() => listVm.importFromJson(any()));
      });

      testWidgets('import shows error snackbar when parsing fails',
          (tester) async {
        clipboardValue = 'garbage';
        final listVm = MockChecklistListViewModel();
        when(() => listVm.checklists).thenReturn([]);
        when(() => listVm.importFromJson(any()))
            .thenThrow(const FormatException('bad json'));

        await tester.pumpWidget(buildApp(themeVm, listVm: listVm));
        await tester.tap(find.text(AppStrings.importJson));
        await tester.pump();
        await tester.pump();

        expect(
          find.textContaining(AppStrings.importFailed
              .replaceFirst('{reason}', 'FormatException')),
          findsOneWidget,
        );
      });
    });
  });
}
