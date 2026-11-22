import 'package:caesar_puzzle/presentation/theme/app_palette.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const lightAccent = PaletteAccent(
    active: Color(0xFF3F7D3A),
    onActive: Color(0xFFFFFFFF),
    accent: Color(0xFFB06D07),
    target: Color(0xFFFCE9BF),
    targetLine: Color(0xFFDF9A27),
  );
  const darkAccent = PaletteAccent(
    active: Color(0xFF7CB86A),
    onActive: Color(0xFF1F1D26),
    accent: Color(0xFFE0B04A),
    target: Color(0xFF3A2E12),
    targetLine: Color(0xFFE0B04A),
  );

  test('classic palette keeps the current game colours', () {
    expect(AppPalette.classic.colors(Brightness.light), same(GameColors.light));
    expect(AppPalette.classic.colors(Brightness.dark), same(GameColors.dark));
  });

  test('byId finds the palette', () {
    expect(AppPalette.byId(AppPaletteId.classic), same(AppPalette.classic));
  });

  test('fromAccent sets the accent group', () {
    final palette = AppPalette.fromAccent(id: AppPaletteId.classic, light: lightAccent, dark: darkAccent);
    final light = palette.colors(Brightness.light);
    final dark = palette.colors(Brightness.dark);

    expect(light.active, lightAccent.active);
    expect(light.onActive, lightAccent.onActive);
    expect(light.accent, lightAccent.accent);
    expect(light.target, lightAccent.target);
    expect(light.targetLine, lightAccent.targetLine);
    expect(dark.active, darkAccent.active);
    expect(dark.target, darkAccent.target);
  });

  test('fromAccent tints neutrals towards active and leaves the rest alone', () {
    final light = AppPalette.fromAccent(
      id: AppPaletteId.classic,
      light: lightAccent,
      dark: darkAccent,
    ).colors(Brightness.light);

    expect(light.background, isNot(GameColors.light.background));
    expect(light.board, isNot(GameColors.light.board));
    expect(light.gridLine, isNot(GameColors.light.gridLine));
    expect(light.text, GameColors.light.text);
    expect(light.glass, GameColors.light.glass);
    expect(light.ok, GameColors.light.ok);
    expect(light.pieces, GameColors.light.pieces);
  });

  test('zero tint keeps neutrals untouched', () {
    final light = AppPalette.fromAccent(
      id: AppPaletteId.classic,
      light: lightAccent,
      dark: darkAccent,
      tint: 0,
    ).colors(Brightness.light);

    expect(light.background, GameColors.light.background);
    expect(light.board, GameColors.light.board);
    expect(light.blockedCell, GameColors.light.blockedCell);
  });
}
