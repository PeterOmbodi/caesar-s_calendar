import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeNotifier extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  ThemeModeNotifier();

  Future<void> load() async {
    final prefs = SharedPreferencesAsync();
    final value = await prefs.getString(_themeKey);
    if (value != null) {
      _mode = ThemeMode.values.firstWhere(
        (e) => e.toString() == value,
        orElse: () => ThemeMode.system,
      );
    } else {
      _mode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = SharedPreferencesAsync();
    return await prefs.setString(_themeKey, mode.toString());
  }

  Future<void> toggle([Brightness? systemBrightness]) async {
    if (_mode == ThemeMode.light) {
      await setMode(ThemeMode.dark);
    } else if (_mode == ThemeMode.dark) {
      await setMode(ThemeMode.light);
    } else {
      if (systemBrightness == Brightness.dark) {
        await setMode(ThemeMode.light);
      } else {
        await setMode(ThemeMode.dark);
      }
    }
  }
}

class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.light.primary,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 2,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        backgroundColor: Colors.deepPurple.withValues(alpha: 0.8),
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    ),
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.dark.primary,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 2,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        backgroundColor: Colors.deepPurple.withValues(alpha: 0.8),
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    ),
  );
}
