part of 'settings_cubit.dart';

enum AppTheme { system, light, dark }

@freezed
abstract class SettingsState with _$SettingsState {

  const SettingsState._();

  const factory SettingsState({
    @Default(AppTheme.system) AppTheme theme,
    @Default(false) bool unlockConfig,
    @Default(true) bool preventOverlap,
  }) = _SettingsState;


  factory SettingsState.fromJson(Map<String, dynamic> json) =>
      _$SettingsStateFromJson(json);

}

extension AppThemeX on AppTheme {
  ThemeMode toThemeMode() {
    switch (this) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
        return ThemeMode.dark;
      case AppTheme.system:
        return ThemeMode.system;
    }
  }

  static AppTheme fromThemeMode(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return AppTheme.light;
      case ThemeMode.dark:
        return AppTheme.dark;
      case ThemeMode.system:
        return AppTheme.system;
    }
  }
}
