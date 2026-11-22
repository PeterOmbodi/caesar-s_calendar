import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:material_ui/material_ui.dart';

/// Colours for painters that draw outside the widget tree's theme lookups.
@immutable
class ThemeColors {
  const ThemeColors(this.game, this.brightness);

  final GameColors game;
  final Brightness brightness;

  Color get pieceBorder => brightness == Brightness.dark ? Colors.white : Colors.black;

  Color get gridLine => game.gridLine;

  Color get customConfigAccent => game.customConfig;
}

class AppColors {
  static ThemeColors _current = const ThemeColors(GameColors.light, Brightness.light);

  static ThemeColors get current => _current;

  static void update(final GameColors game, final Brightness brightness) {
    if (identical(_current.game, game) && _current.brightness == brightness) return;
    _current = ThemeColors(game, brightness);
  }
}
