import 'package:caesar_puzzle/presentation/theme/chrome_theme.dart';
import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/widgets/system_bars.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppThemeData {
  static final ThemeData light = _build(GameColors.light, AppColors.light.primary, Brightness.light);
  static final ThemeData dark = _build(GameColors.dark, AppColors.dark.primary, Brightness.dark);

  /// Desktop browsers behave like Material whatever the host OS.
  static TargetPlatform? get _platform => kIsWeb &&
          defaultTargetPlatform != TargetPlatform.iOS &&
          defaultTargetPlatform != TargetPlatform.android
      ? TargetPlatform.linux
      : null;

  static ThemeData _build(final GameColors game, final Color seed, final Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness).copyWith(
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
