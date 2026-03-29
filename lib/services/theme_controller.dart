import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._prefs) : _themeMode = _loadThemeMode(_prefs);

  static const String _themeModeKey = 'theme.mode';
  static const String _legacyDarkOverrideKey = 'theme.dark_override_enabled';

  final SharedPreferences _prefs;
  ThemeMode _themeMode;

  static ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final storedMode = prefs.getString(_themeModeKey);
    if (storedMode == null) {
      final legacyDarkOverride = prefs.getBool(_legacyDarkOverrideKey);
      if (legacyDarkOverride == true) {
        return ThemeMode.dark;
      }
      return ThemeMode.dark;
    }
    switch (storedMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  ThemeMode get themeMode => _themeMode;

  bool get hasExplicitPreference => _themeMode != ThemeMode.system;

  bool get isDarkEnabled => _themeMode == ThemeMode.dark;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _prefs.setString(_themeModeKey, mode.name);
    await _prefs.remove(_legacyDarkOverrideKey);
  }

  Future<void> setDarkEnabled(bool enabled) async {
    await setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }
}
