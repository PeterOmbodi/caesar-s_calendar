import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flip_flap/split_flap_theme.dart';

class AppThemeData {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.light.primary),
    appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(elevation: 2),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        backgroundColor: Colors.deepPurple.withValues(alpha: 0.8),
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
    ),
    extensions: [
      FlipFlapTheme(
        unitDecoration: BoxDecoration(
          color: AppColors.light.boardBorder,
          border: Border.fromBorderSide(BorderSide(color: AppColors.light.boardBackground, width: 0.5)),
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        displayDecoration: const BoxDecoration(color: Colors.transparent),
        textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.light.cellLabel),
      ),
    ],
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.dark.primary, brightness: Brightness.dark),
    appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(elevation: 2),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        backgroundColor: Colors.deepPurple.withValues(alpha: 0.8),
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
    ),
    extensions: [
      FlipFlapTheme(
        unitDecoration: BoxDecoration(
          color: AppColors.dark.boardBorder,
          border: Border.fromBorderSide(BorderSide(color: AppColors.dark.boardBackground, width: 0.5)),
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        displayDecoration: const BoxDecoration(color: Colors.transparent),
        textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.dark.cellLabel),
      ),
    ],
  );
}
