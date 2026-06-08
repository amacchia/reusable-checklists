import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:reusable_checklists/core/constants/app_strings.dart';
import 'package:reusable_checklists/data/models/checklist.dart';
import 'package:reusable_checklists/hive_registrar.g.dart';
import 'package:reusable_checklists/main.dart' as app;
import 'package:reusable_checklists/views/screens/adaptive_layout_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Checklist> box;
  late SharedPreferences prefs;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('main_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapters();
    }
    box = await Hive.openBox<Checklist>('checklists');
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('MainApp renders list screen on compact', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(app.MainApp(prefs: prefs));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(AppStrings.appTitle), findsOneWidget);
  });

  testWidgets('MainApp renders adaptive layout shell', (tester) async {
    await tester.pumpWidget(app.MainApp(prefs: prefs));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(AdaptiveLayoutShell), findsOneWidget);
  });

  testWidgets('MainApp navigates to /settings via push on compact', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(app.MainApp(prefs: prefs));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(AppStrings.settings), findsOneWidget);
  });

  testWidgets('onGenerateRoute handles /detail route', (tester) async {
    await tester.pumpWidget(app.MainApp(prefs: prefs));
    await tester.pump();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final route = materialApp.onGenerateRoute!(
      const RouteSettings(name: '/detail', arguments: 'some-id'),
    );
    expect(route, isNotNull);
  });

  testWidgets('onGenerateRoute returns null for unknown routes', (
    tester,
  ) async {
    await tester.pumpWidget(app.MainApp(prefs: prefs));
    await tester.pump();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(
      materialApp.onGenerateRoute!(const RouteSettings(name: '/nope')),
      isNull,
    );
  });

  testWidgets('onGenerateRoute returns null for /detail without String args', (
    tester,
  ) async {
    await tester.pumpWidget(app.MainApp(prefs: prefs));
    await tester.pump();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(
      materialApp.onGenerateRoute!(const RouteSettings(name: '/detail')),
      isNull,
    );
    expect(
      materialApp.onGenerateRoute!(
        const RouteSettings(name: '/detail', arguments: 42),
      ),
      isNull,
    );
  });
}
