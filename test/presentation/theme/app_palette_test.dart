import 'dart:math' as math;

import 'package:caesar_puzzle/presentation/theme/app_palette.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/theme/theme.dart';
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

  test('presets have distinct ids and start with classic', () {
    final ids = AppPalette.presets.map((final p) => p.id).toList();
    expect(ids.first, AppPaletteId.classic);
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids, isNot(contains(AppPaletteId.system)));
  });

  test('system colours fall back to classic where the platform has none', () {
    expect(AppPalette.resolve(AppPaletteId.system, AppPalette.presets), same(AppPalette.classic));
  });

  test('fromSeed takes the accent group from the seeded Material scheme', () {
    const seed = Color(0xFF3366CC);
    final palette = AppPalette.fromSeed(id: AppPaletteId.system, seed: seed);
    for (final brightness in Brightness.values) {
      final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
      final colors = palette.colors(brightness);
      expect(colors.active, scheme.primary);
      expect(colors.onActive, scheme.onPrimary);
      expect(colors.accent, scheme.tertiary);
      expect(colors.targetLine, scheme.tertiary);
    }
  });

  test('a saved palette the app does not know loads as classic', () {
    expect(SettingsState.fromJson({'palette': 'neon'}).palette, AppPaletteId.classic);
  });

  group('contrast', () {
    double contrast(final Color a, final Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
    }

    for (final palette in AppPalette.presets) {
      for (final brightness in Brightness.values) {
        test('${palette.id.name} ${brightness.name}', () {
          final theme = AppThemeData.of(palette, brightness);
          final colors = palette.colors(brightness);
          final readable = theme.textButtonTheme.style!.foregroundColor!.resolve({})!;
          expect(
            contrast(theme.colorScheme.onPrimary, theme.colorScheme.primary),
            greaterThanOrEqualTo(4.5),
            reason: 'button label',
          );
          expect(contrast(readable, colors.background), greaterThanOrEqualTo(4.5), reason: 'text button');
          expect(
            contrast(theme.colorScheme.onSecondaryContainer, theme.colorScheme.secondaryContainer),
            greaterThanOrEqualTo(4.5),
            reason: 'selected segment',
          );
          expect(contrast(colors.accent, colors.target), greaterThanOrEqualTo(3), reason: 'goal digits');
        });
      }
    }
  });
}
