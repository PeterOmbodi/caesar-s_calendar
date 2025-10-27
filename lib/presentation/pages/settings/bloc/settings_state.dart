part of 'settings_cubit.dart';

enum AppTheme { system, light, dark }

@freezed
abstract class SettingsState with _$SettingsState {

  const factory SettingsState({
    @Default(AppTheme.system) final AppTheme theme,
    @Default(false) final bool unlockConfig,
    @Default(true) final bool preventOverlap,
    @Default(true) final bool autoLockConfig,
    @Default(true) final bool separateMoveColors,
    @Default(false) final bool snapToGridOnTransform,
    @Default(SolutionIndicator.none) final SolutionIndicator solutionIndicator,
    @Default(true) final bool showTimer,
  }) = _SettingsState;

  const SettingsState._();


  factory SettingsState.fromJson(final Map<String, dynamic> json) =>
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

  static AppTheme fromThemeMode(final ThemeMode m) {
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
