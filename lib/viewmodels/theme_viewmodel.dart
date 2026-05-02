import 'package:flutter/material.dart';

import '../data/repositories/settings_repository.dart';

class ThemeViewModel extends ChangeNotifier {
  ThemeViewModel(this._repository)
      : _themeMode = _repository.getThemeMode();

  final SettingsRepository _repository;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _repository.setThemeMode(mode);
  }
}
