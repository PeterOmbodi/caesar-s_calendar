import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/presentation/theme/chrome_theme.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app themes register game colors and chrome theme', () {
    expect(AppThemeData.light.extension<GameColors>(), same(GameColors.light));
    expect(AppThemeData.dark.extension<GameColors>(), same(GameColors.dark));
    expect(AppThemeData.light.extension<ChromeTheme>(), same(ChromeTheme.glass));
    expect(AppThemeData.dark.extension<ChromeTheme>(), same(ChromeTheme.glass));
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
