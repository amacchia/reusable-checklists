import 'package:flutter/material.dart';

abstract interface class SettingsRepository {
  ThemeMode getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);
}
