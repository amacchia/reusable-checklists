import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_theme.dart';
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

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapters();
  await Hive.openBox<Checklist>('checklists');
  final prefs = await SharedPreferences.getInstance();
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
        ChangeNotifierProxyProvider<ChecklistRepository,
            ChecklistListViewModel>(
          create: (ctx) =>
              ChecklistListViewModel(ctx.read<ChecklistRepository>())
                ..loadChecklists(),
          update: (_, repo, vm) => vm!,
        ),
        Provider<SettingsRepository>(
          create: (_) => SharedPrefsSettingsRepository(prefs),
        ),
        ChangeNotifierProxyProvider<SettingsRepository, ThemeViewModel>(
          create: (ctx) =>
              ThemeViewModel(ctx.read<SettingsRepository>()),
          update: (_, repo, vm) => vm!,
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
                  final checklistId = settings.arguments as String;
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
