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
