import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:material_ui/material_ui.dart';

enum AppPaletteId { classic, purple, bronze, laurel, terracotta, system }

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

  /// Material You colours derived from the system [seed]; neutrals follow the same tint as the presets.
  factory AppPalette.fromSeed({required final AppPaletteId id, required final Color seed}) {
    PaletteAccent accentFor(final Brightness brightness, final GameColors base) {
      final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
      return PaletteAccent(
        active: scheme.primary,
        onActive: scheme.onPrimary,
        accent: scheme.tertiary,
        target: Color.lerp(base.board, scheme.tertiary, brightness == Brightness.dark ? 0.3 : 0.25)!,
        targetLine: scheme.tertiary,
      );
    }

    return AppPalette.fromAccent(
      id: id,
      light: accentFor(Brightness.light, GameColors.light),
      dark: accentFor(Brightness.dark, GameColors.dark),
    );
  }

  static const classic = AppPalette(id: AppPaletteId.classic, light: GameColors.light, dark: GameColors.dark);

  static final presets = [
    classic,
    AppPalette.fromAccent(
      id: AppPaletteId.purple,
      light: const PaletteAccent(
        active: Color(0xFF7B2D8E),
        onActive: Color(0xFFFFFFFF),
        accent: Color(0xFFB06D07),
        target: Color(0xFFFCE9BF),
        targetLine: Color(0xFFDF9A27),
      ),
      dark: const PaletteAccent(
        active: Color(0xFF9450AE),
        onActive: Color(0xFFFFFFFF),
        accent: Color(0xFFE0B04A),
        target: Color(0xFF3A2E12),
        targetLine: Color(0xFFE0B04A),
      ),
    ),
    AppPalette.fromAccent(
      id: AppPaletteId.bronze,
      light: const PaletteAccent(
        active: Color(0xFF9A6A1F),
        onActive: Color(0xFFFFFFFF),
        accent: Color(0xFF2F6FA3),
        target: Color(0xFFDCE9F5),
        targetLine: Color(0xFF3F86C4),
      ),
      dark: const PaletteAccent(
        active: Color(0xFFD19A45),
        onActive: Color(0xFF1F1D26),
        accent: Color(0xFF6FB3E8),
        target: Color(0xFF0E2A42),
        targetLine: Color(0xFF4DA3E0),
      ),
    ),
    AppPalette.fromAccent(
      id: AppPaletteId.laurel,
      light: const PaletteAccent(
        active: Color(0xFF3F7D3A),
        onActive: Color(0xFFFFFFFF),
        accent: Color(0xFFB06D07),
        target: Color(0xFFFCE9BF),
        targetLine: Color(0xFFDF9A27),
      ),
      dark: const PaletteAccent(
        active: Color(0xFF7CB86A),
        onActive: Color(0xFF1F1D26),
        accent: Color(0xFFE0B04A),
        target: Color(0xFF3A2E12),
        targetLine: Color(0xFFE0B04A),
      ),
    ),
    AppPalette.fromAccent(
      id: AppPaletteId.terracotta,
      light: const PaletteAccent(
        active: Color(0xFFB5523A),
        onActive: Color(0xFFFFFFFF),
        accent: Color(0xFF2F6FA3),
        target: Color(0xFFDCE9F5),
        targetLine: Color(0xFF3F86C4),
      ),
      dark: const PaletteAccent(
        active: Color(0xFFE07A5F),
        onActive: Color(0xFF1F1D26),
        accent: Color(0xFF6FB3E8),
        target: Color(0xFF0E2A42),
        targetLine: Color(0xFF4DA3E0),
      ),
    ),
  ];

  static AppPalette byId(final AppPaletteId id) => resolve(id, presets);

  /// Falls back to [classic] when [id] is not among [available], e.g. system colours on iOS.
  static AppPalette resolve(final AppPaletteId id, final Iterable<AppPalette> available) =>
      available.firstWhere((final p) => p.id == id, orElse: () => classic);

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
