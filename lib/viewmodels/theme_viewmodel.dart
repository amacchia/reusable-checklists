import 'package:flutter/material.dart';

import '../data/repositories/settings_repository.dart';

class ThemeViewModel extends ChangeNotifier {
  ThemeViewModel(this._repository)
      : _themeMode = _repository.getThemeMode();

  final SettingsRepository _repository;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _repository.setThemeMode(mode);
    notifyListeners();
  }
}
