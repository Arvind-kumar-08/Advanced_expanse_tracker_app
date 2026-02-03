import 'package:flutter/material.dart';
import '../../data/datasources/local/hive_datasources.dart';

/// Provider for theme state management
class ThemeProvider with ChangeNotifier {
  final HiveDataSource _hiveDataSource;
  bool _isDarkMode = false;

  ThemeProvider({required HiveDataSource hiveDataSource})
      : _hiveDataSource = hiveDataSource {
    _loadThemeMode();
  }

  // Getters
  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Load saved theme mode
  void _loadThemeMode() {
    _isDarkMode = _hiveDataSource.getThemeMode();
    notifyListeners();
  }

  /// Toggle theme mode
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _hiveDataSource.saveThemeMode(_isDarkMode);
    notifyListeners();
  }

  /// Set specific theme mode
  Future<void> setThemeMode(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      await _hiveDataSource.saveThemeMode(_isDarkMode);
      notifyListeners();
    }
  }

  /// Set dark mode
  Future<void> setDarkMode() async {
    await setThemeMode(true);
  }

  /// Set light mode
  Future<void> setLightMode() async {
    await setThemeMode(false);
  }
}