import 'package:caesar_puzzle/presentation/theme/app_palette.dart';
import 'package:caesar_puzzle/presentation/theme/chrome_theme.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/widgets/system_bars.dart';
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

class AppThemeData {
  static final _cache = <(AppPalette, Brightness), ThemeData>{};

  static ThemeData of(final AppPalette palette, final Brightness brightness) =>
      _cache.putIfAbsent((palette, brightness), () => _build(palette.colors(brightness), brightness));

  /// Desktop browsers behave like Material whatever the host OS.
  static TargetPlatform? get _platform =>
      kIsWeb && defaultTargetPlatform != TargetPlatform.iOS && defaultTargetPlatform != TargetPlatform.android
      ? TargetPlatform.linux
      : null;

  static ThemeData _build(final GameColors game, final Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: game.active, brightness: brightness).copyWith(
      primary: game.active,
      onPrimary: game.onActive,
      tertiary: game.accent,
      surface: game.background,
      onSurface: game.text,
      onSurfaceVariant: game.textSecondary,
      error: game.bad,
    );
    return ThemeData(
      platform: _platform,
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: game.background,
      appBarTheme: AppBarTheme(
        backgroundColor: game.background,
        foregroundColor: game.text,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemBars.styleFor(brightness),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      extensions: [game, ChromeTheme.glass],
    );
  }
}
