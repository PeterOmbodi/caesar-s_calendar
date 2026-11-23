import 'package:caesar_puzzle/presentation/theme/app_palette.dart';
import 'package:caesar_puzzle/presentation/theme/chrome_theme.dart';
import 'package:caesar_puzzle/presentation/theme/controls_theme.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/widgets/inset_section.dart';
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
    final isDark = brightness == Brightness.dark;
    final activeText = Color.lerp(game.active, isDark ? Colors.white : Colors.black, isDark ? 0.35 : 0.3)!;
    final scheme = ColorScheme.fromSeed(seedColor: game.active, brightness: brightness).copyWith(
      primary: game.active,
      onPrimary: game.onActive,
      tertiary: game.accent,
      secondaryContainer: Color.lerp(game.board, game.active, isDark ? 0.3 : 0.16),
      onSecondaryContainer: activeText,
      surface: game.background,
      onSurface: game.text,
      onSurfaceVariant: game.textSecondary,
      surfaceTint: Colors.transparent,
      surfaceContainerLowest: game.board,
      surfaceContainerLow: game.board,
      surfaceContainer: Color.lerp(game.board, game.blockedCell, 0.5),
      surfaceContainerHigh: game.blockedCell,
      surfaceContainerHighest: game.gridLine,
      outline: Color.lerp(game.boardBorder, game.textSecondary, 0.5),
      outlineVariant: game.gridLine,
      error: game.bad,
    );
    final base = ThemeData(
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
      cardTheme: CardThemeData(
        color: game.board,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(InsetSection.radius)),
          side: BorderSide(color: game.gridLine),
        ),
      ),
      dividerTheme: DividerThemeData(color: game.gridLine),
      switchTheme: SwitchThemeData(
        thumbIcon: WidgetStateProperty.resolveWith(
          (final states) =>
              states.contains(WidgetState.selected) ? Icon(Icons.check, color: game.active) : const Icon(Icons.close),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: game.background, dragHandleColor: game.boardBorder),
      drawerTheme: DrawerThemeData(backgroundColor: game.background),
      dialogTheme: DialogThemeData(backgroundColor: game.board),
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
    final buttonLabel = base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600);
    final buttonSize = Size(64, ControlsTheme.material.regularHeight);
    const buttonShape = StadiumBorder();
    final fieldRadius = BorderRadius.all(Radius.circular(ControlsTheme.material.fieldRadius));
    OutlineInputBorder fieldBorder(final Color color, {final double width = 1}) => OutlineInputBorder(
      borderRadius: fieldRadius,
      borderSide: BorderSide(color: color, width: width),
    );
    return base.copyWith(
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: buttonSize, shape: buttonShape, textStyle: buttonLabel),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: buttonLabel,
          foregroundColor: activeText,
          side: BorderSide(color: scheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: buttonLabel,
          foregroundColor: activeText,
        ),
      ),
      tabBarTheme: TabBarThemeData(labelColor: activeText, indicatorColor: game.active),
      chipTheme: ChipThemeData(
        backgroundColor: game.board,
        selectedColor: scheme.secondaryContainer,
        showCheckmark: false,
        labelStyle: (base.textTheme.labelLarge ?? const TextStyle()).copyWith(
          fontWeight: FontWeight.w600,
          color: WidgetStateColor.resolveWith(
            (final states) => states.contains(WidgetState.disabled)
                ? game.textSecondary.withValues(alpha: 0.38)
                : states.contains(WidgetState.selected)
                ? activeText
                : game.textSecondary,
          ),
        ),
        side: WidgetStateBorderSide.resolveWith(
          (final states) => states.contains(WidgetState.selected) ? BorderSide.none : BorderSide(color: game.gridLine),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(ControlsTheme.material.selectionRadius)),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: fieldBorder(scheme.outline),
        enabledBorder: fieldBorder(scheme.outline),
        focusedBorder: fieldBorder(game.active, width: 2),
        errorBorder: fieldBorder(game.bad),
        focusedErrorBorder: fieldBorder(game.bad, width: 2),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
