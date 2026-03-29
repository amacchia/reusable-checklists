import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_repository.dart';

class SharedPrefsSettingsRepository implements SettingsRepository {
  SharedPrefsSettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _themeModeKey = 'themeMode';

  static const _themeModeMap = {
    'system': ThemeMode.system,
    'light': ThemeMode.light,
    'dark': ThemeMode.dark,
  };

  @override
  ThemeMode getThemeMode() {
    final value = _prefs.getString(_themeModeKey);
    return _themeModeMap[value] ?? ThemeMode.system;
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) {
    final value = mode.name; // 'system', 'light', or 'dark'
    return _prefs.setString(_themeModeKey, value);
  }
}
