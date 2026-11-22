import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:material_ui/material_ui.dart';

enum AppPaletteId { classic }

/// The colours a palette sets for one brightness; neutrals are tinted towards [active].
@immutable
class PaletteAccent {
  const PaletteAccent({
    required this.active,
    required this.onActive,
    required this.accent,
    required this.target,
    required this.targetLine,
  });

  final Color active;
  final Color onActive;
  final Color accent;
  final Color target;
  final Color targetLine;
}

@immutable
class AppPalette {
  const AppPalette({required this.id, required this.light, required this.dark, this.isPremium = false});

  factory AppPalette.fromAccent({
    required final AppPaletteId id,
    required final PaletteAccent light,
    required final PaletteAccent dark,
    final double tint = 1,
    final bool isPremium = false,
  }) => AppPalette(
    id: id,
    light: _apply(GameColors.light, light, _lightTint * tint),
    dark: _apply(GameColors.dark, dark, _darkTint * tint),
    isPremium: isPremium,
  );

  static const classic = AppPalette(id: AppPaletteId.classic, light: GameColors.light, dark: GameColors.dark);

  static const values = [classic];

  static AppPalette byId(final AppPaletteId id) => values.firstWhere((final p) => p.id == id, orElse: () => classic);

  static const _lightTint = _NeutralTint(background: 0.04, board: 0.02, lines: 0.05);
  static const _darkTint = _NeutralTint(background: 0.06, board: 0.04, lines: 0.08);

  final AppPaletteId id;
  final GameColors light;
  final GameColors dark;
  final bool isPremium;

  GameColors colors(final Brightness brightness) => brightness == Brightness.dark ? dark : light;

  static GameColors _apply(final GameColors base, final PaletteAccent accent, final _NeutralTint tint) {
    Color mix(final Color color, final double amount) => Color.lerp(color, accent.active, amount)!;
    return base.copyWith(
      active: accent.active,
      onActive: accent.onActive,
      accent: accent.accent,
      target: accent.target,
      targetLine: accent.targetLine,
      background: mix(base.background, tint.background),
      backgroundTop: mix(base.backgroundTop, tint.background),
      board: mix(base.board, tint.board),
      gridLine: mix(base.gridLine, tint.lines),
      boardBorder: mix(base.boardBorder, tint.lines),
      blockedCell: mix(base.blockedCell, tint.lines),
    );
  }
}

class _NeutralTint {
  const _NeutralTint({required this.background, required this.board, required this.lines});

  final double background;
  final double board;
  final double lines;

  _NeutralTint operator *(final double factor) =>
      _NeutralTint(background: background * factor, board: board * factor, lines: lines * factor);
}
