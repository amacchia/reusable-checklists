import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reusable_checklists/data/repositories/shared_prefs_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPrefsSettingsRepository', () {
    test('getThemeMode returns system when nothing stored', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPrefsSettingsRepository(prefs);

      expect(repo.getThemeMode(), ThemeMode.system);
    });

    test('getThemeMode returns light when stored as light', () async {
      SharedPreferences.setMockInitialValues({'themeMode': 'light'});
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPrefsSettingsRepository(prefs);

      expect(repo.getThemeMode(), ThemeMode.light);
    });

    test('getThemeMode returns dark when stored as dark', () async {
      SharedPreferences.setMockInitialValues({'themeMode': 'dark'});
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPrefsSettingsRepository(prefs);

      expect(repo.getThemeMode(), ThemeMode.dark);
    });

    test('getThemeMode returns system when stored value is unknown', () async {
      SharedPreferences.setMockInitialValues({'themeMode': 'garbage'});
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPrefsSettingsRepository(prefs);

      expect(repo.getThemeMode(), ThemeMode.system);
    });

    test('setThemeMode persists light', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPrefsSettingsRepository(prefs);

      await repo.setThemeMode(ThemeMode.light);

      expect(prefs.getString('themeMode'), 'light');
    });

    test('setThemeMode persists dark', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPrefsSettingsRepository(prefs);

      await repo.setThemeMode(ThemeMode.dark);

      expect(prefs.getString('themeMode'), 'dark');
    });

    test('setThemeMode persists system', () async {
      SharedPreferences.setMockInitialValues({'themeMode': 'dark'});
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPrefsSettingsRepository(prefs);

      await repo.setThemeMode(ThemeMode.system);

      expect(prefs.getString('themeMode'), 'system');
    });

    test('round trip via setThemeMode then getThemeMode', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPrefsSettingsRepository(prefs);

      await repo.setThemeMode(ThemeMode.light);
      expect(repo.getThemeMode(), ThemeMode.light);
    });
  });
}
