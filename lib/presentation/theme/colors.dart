import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:flutter/material.dart';

abstract class ThemeColors {
  GameColors get game;

  Color get primary;

  Color get secondary;

  Color get pieceBorder;

  Color get pieceBorderSelected;

  Color get pieceFillSelectedOverlay;

  Color get gridLine;

  Color get gridBorder;

  Color get boardLabelText;

  Color get previewOutline;

  Color get previewOutlineCollision;

  Color get previewFill;

  Color get previewFillCollision;

  Color get todayLabel;

  Color get customConfigAccent;
}

class AppColors {
  static const Light light = Light();
  static const Dark dark = Dark();

  static ThemeColors _current = light;

  static ThemeColors get current => _current;

  static void update(final Brightness brightness) {
    _current = brightness == Brightness.dark ? dark : light;
  }
}

class Light implements ThemeColors {
  const Light();

  @override
  GameColors get game => GameColors.light;

  @override
  Color get primary => Colors.deepPurple;

  @override
  Color get secondary => Colors.black;

  @override
  Color get pieceBorder => Colors.black;

  @override
  Color get pieceBorderSelected => game.selection;

  @override
  Color get pieceFillSelectedOverlay => Colors.transparent;

  @override
  Color get gridLine => game.gridLine;

  @override
  Color get gridBorder => game.boardBorder;

  @override
  Color get boardLabelText => game.textSecondary;

  @override
  Color get previewOutline => game.ok;

  @override
  Color get previewOutlineCollision => game.bad;

  @override
  Color get previewFill => game.ok;

  @override
  Color get previewFillCollision => game.bad;

  @override
  Color get todayLabel => game.accent;

  @override
  Color get customConfigAccent => game.customConfig;
}

class Dark implements ThemeColors {
  const Dark();

  @override
  GameColors get game => GameColors.dark;

  @override
  Color get primary => Colors.deepPurple;

  @override
  Color get secondary => Colors.black;

  @override
  Color get pieceBorder => Colors.white;

  @override
  Color get pieceBorderSelected => game.selection;

  @override
  Color get pieceFillSelectedOverlay => Colors.transparent;

  @override
  Color get gridLine => game.gridLine;

  @override
  Color get gridBorder => game.boardBorder;

  @override
  Color get boardLabelText => game.textSecondary;

  @override
  Color get previewOutline => game.ok;

  @override
  Color get previewOutlineCollision => game.bad;

  @override
  Color get previewFill => game.ok;

  @override
  Color get previewFillCollision => game.bad;

  @override
  Color get todayLabel => game.accent;

  @override
  Color get customConfigAccent => game.customConfig;
}
