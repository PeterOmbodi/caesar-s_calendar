import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/presentation/theme/app_palette.dart';
import 'package:caesar_puzzle/presentation/theme/chrome_theme.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('app themes register game colors and chrome theme', () {
    final light = AppThemeData.of(AppPalette.classic, Brightness.light);
    final dark = AppThemeData.of(AppPalette.classic, Brightness.dark);
    expect(light.extension<GameColors>(), same(GameColors.light));
    expect(dark.extension<GameColors>(), same(GameColors.dark));
    expect(light.extension<ChromeTheme>(), same(ChromeTheme.glass));
    expect(dark.extension<ChromeTheme>(), same(ChromeTheme.glass));
  });

  test('app theme takes its primary colours from the game palette', () {
    final scheme = AppThemeData.of(AppPalette.classic, Brightness.light).colorScheme;
    expect(scheme.primary, GameColors.light.active);
    expect(scheme.onPrimary, GameColors.light.onActive);
    expect(scheme.tertiary, GameColors.light.accent);
  });

  test('app theme takes its surfaces and outlines from the game palette', () {
    final theme = AppThemeData.of(AppPalette.classic, Brightness.light);
    final scheme = theme.colorScheme;
    expect(scheme.surface, GameColors.light.background);
    expect(scheme.surfaceContainerLow, GameColors.light.board);
    expect(scheme.surfaceContainerHigh, GameColors.light.blockedCell);
    expect(scheme.outlineVariant, GameColors.light.gridLine);
    expect(theme.cardTheme.color, GameColors.light.board);
    expect(theme.cardTheme.elevation, 0);
  });

  test('outline is a mid tone, darker than the hairline outline variant', () {
    for (final brightness in Brightness.values) {
      final scheme = AppThemeData.of(AppPalette.classic, brightness).colorScheme;
      final background = scheme.surface.computeLuminance();
      double distance(final Color c) => (c.computeLuminance() - background).abs();
      expect(distance(scheme.outline), greaterThan(distance(scheme.outlineVariant)));
    }
  });

  test('switches show a check when on and a cross when off', () {
    final thumbIcon = AppThemeData.of(AppPalette.classic, Brightness.light).switchTheme.thumbIcon!;
    expect(thumbIcon.resolve({WidgetState.selected})?.icon, Icons.check);
    expect(thumbIcon.resolve({})?.icon, Icons.close);
  });

  test('the check on a switch is drawn in the active colour', () {
    for (final brightness in Brightness.values) {
      final thumbIcon = AppThemeData.of(AppPalette.classic, brightness).switchTheme.thumbIcon!;
      expect(thumbIcon.resolve({WidgetState.selected})?.color, AppPalette.classic.colors(brightness).active);
    }
  });

  test('app themes are cached per palette and brightness', () {
    expect(
      AppThemeData.of(AppPalette.classic, Brightness.dark),
      same(AppThemeData.of(AppPalette.classic, Brightness.dark)),
    );
  });

  test('every game piece has a colour', () {
    final gamePieces = PieceType.values.where((final t) => t != PieceType.zone1 && t != PieceType.zone2);
    for (final colors in [GameColors.light, GameColors.dark]) {
      expect(colors.pieces.keys, containsAll(gamePieces));
    }
  });

  test('lerp returns the end values at 0 and 1', () {
    final start = GameColors.light.lerp(GameColors.dark, 0);
    final end = GameColors.light.lerp(GameColors.dark, 1);

    expect(start.board, GameColors.light.board);
    expect(end.board, GameColors.dark.board);
    expect(end.piece(PieceType.pShape), GameColors.dark.piece(PieceType.pShape));
  });
}
