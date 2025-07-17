import 'package:flutter/material.dart';

abstract class ThemeColors {
  Color get pieceBorder;
  Color get pieceBorderSelected;
  Color get pieceFillSelectedOverlay;
  Color get pieceCenterDot;
  Color get gridLine;
  Color get gridBorder;
  Color get boardBackground;
  Color get boardBorder;
  Color get boardLabelText;
  Color get previewOutline;
  Color get previewOutlineCollision;
  Color get previewFill;
  Color get previewFillCollision;
  Color get todayLabel;
  Color get cellLabel;
}

class AppColors {
  static const Light light = Light();
  static const Dark dark = Dark();

  static ThemeColors? _current;

  static ThemeColors get current {
    assert(_current != null, 'No instance of AppColors was loaded. Try to initialize AppColors before accessing AppColors.current.');
    return _current!;
  }

  static void update(Brightness brightness) {
    _current = brightness == Brightness.dark ? dark : light;
  }

  static void init() {
    _current = light;
  }
}

class Light implements ThemeColors {
  const Light();
  @override
  Color get pieceBorder => Colors.black;
  @override
  Color get pieceBorderSelected => Colors.yellow;
  @override
  Color get pieceFillSelectedOverlay => Colors.transparent;
  @override
  Color get pieceCenterDot => Colors.red;
  @override
  Color get gridLine => Colors.grey.shade300;
  @override
  Color get gridBorder => Colors.black;
  @override
  Color get boardBackground => Colors.grey.shade100;
  @override
  Color get boardBorder => Colors.grey.shade400;
  @override
  Color get boardLabelText => Colors.black54;
  @override
  Color get previewOutline => Colors.green;
  @override
  Color get previewOutlineCollision => Colors.red;
  @override
  Color get previewFill => Colors.green;
  @override
  Color get previewFillCollision => Colors.red;
  @override
  Color get todayLabel => Colors.blue;
  @override
  Color get cellLabel => Colors.black;
}

class Dark implements ThemeColors {
  const Dark();
  @override
  Color get pieceBorder => Colors.white;
  @override
  Color get pieceBorderSelected => Colors.yellow;
  @override
  Color get pieceFillSelectedOverlay => Colors.transparent;
  @override
  Color get pieceCenterDot => Colors.red;
  @override
  Color get gridLine => Colors.grey.shade700;
  @override
  Color get gridBorder => Colors.white;
  @override
  Color get boardBackground => Colors.grey.shade900;
  @override
  Color get boardBorder => Colors.grey.shade600;
  @override
  Color get boardLabelText => Colors.white70;
  @override
  Color get previewOutline => Colors.lightGreenAccent;
  @override
  Color get previewOutlineCollision => Colors.redAccent;
  @override
  Color get previewFill => Colors.lightGreenAccent;
  @override
  Color get previewFillCollision => Colors.redAccent;
  @override
  Color get todayLabel => Colors.lightBlueAccent;
  @override
  Color get cellLabel => Colors.white;
}
