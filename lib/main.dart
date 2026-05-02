import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_theme.dart';
import 'core/navigation/route_observer.dart';
import 'data/models/checklist.dart';
import 'data/repositories/checklist_repository.dart';
import 'data/repositories/hive_checklist_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/shared_prefs_settings_repository.dart';
import 'hive_registrar.g.dart';
import 'viewmodels/checklist_detail_viewmodel.dart';
import 'viewmodels/checklist_list_viewmodel.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'views/screens/checklist_detail_screen.dart';
import 'views/screens/checklist_list_screen.dart';
import 'views/screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapters();
  final results = await Future.wait([
    Hive.openBox<Checklist>('checklists'),
    SharedPreferences.getInstance(),
  ]);
  final prefs = results[1] as SharedPreferences;
  runApp(MainApp(prefs: prefs));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ChecklistRepository>(
          create: (_) =>
              HiveChecklistRepository(Hive.box<Checklist>('checklists')),
        ),
        ChangeNotifierProvider<ChecklistListViewModel>(
          create: (ctx) =>
              ChecklistListViewModel(ctx.read<ChecklistRepository>())
                ..loadChecklists(),
        ),
        Provider<SettingsRepository>(
          create: (_) => SharedPrefsSettingsRepository(prefs),
        ),
        ChangeNotifierProvider<ThemeViewModel>(
          create: (ctx) => ThemeViewModel(ctx.read<SettingsRepository>()),
        ),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeVm, _) {
          return MaterialApp(
            title: 'Reusable Checklists',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeVm.themeMode,
            navigatorObservers: [routeObserver],
            initialRoute: '/',
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/':
                  return MaterialPageRoute(
                    builder: (_) => const ChecklistListScreen(),
                  );
                case '/detail':
                  final checklistId = settings.arguments;
                  if (checklistId is! String) return null;
                  return MaterialPageRoute(
                    builder: (ctx) => ChangeNotifierProvider(
                      create: (ctx) => ChecklistDetailViewModel(
                        ctx.read<ChecklistRepository>(),
                      )..loadChecklist(checklistId),
                      child: const ChecklistDetailScreen(),
                    ),
                  );
                case '/settings':
                  return MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  );
                default:
                  return null;
              }
            },
          );
        },
      ),
    );
  }
}
