import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:flutter/material.dart';

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
    extensions: [SplitFlapTheme.light],
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
    extensions: [SplitFlapTheme.dark],
  );
}

@immutable
class SplitFlapTheme extends ThemeExtension<SplitFlapTheme> {
  const SplitFlapTheme({required this.tileDecoration, required this.panelDecoration, required this.symbolStyle});

  final BoxDecoration tileDecoration;
  final BoxDecoration panelDecoration;
  final TextStyle symbolStyle;

  @override
  SplitFlapTheme copyWith({
    final BoxDecoration? tileDecoration,
    final BoxDecoration? panelDecoration,
    final TextStyle? symbolStyle,
  }) => SplitFlapTheme(
    tileDecoration: tileDecoration ?? this.tileDecoration,
    panelDecoration: panelDecoration ?? this.panelDecoration,
    symbolStyle: symbolStyle ?? this.symbolStyle,
  );

  @override
  SplitFlapTheme lerp(final ThemeExtension<SplitFlapTheme>? other, final double t) {
    if (other is! SplitFlapTheme) return this;

    return SplitFlapTheme(
      tileDecoration: BoxDecoration.lerp(tileDecoration, other.tileDecoration, t) ?? tileDecoration,
      panelDecoration: BoxDecoration.lerp(panelDecoration, other.panelDecoration, t) ?? panelDecoration,
      symbolStyle: TextStyle.lerp(symbolStyle, other.symbolStyle, t) ?? symbolStyle,
    );
  }

  static SplitFlapTheme of(final BuildContext context) =>
      Theme.of(context).extension<SplitFlapTheme>() ?? (Theme.of(context).brightness == Brightness.dark ? dark : light);

  static final SplitFlapTheme light = SplitFlapTheme(
    tileDecoration: BoxDecoration(
      color: AppColors.light.boardBorder,
      border: Border.fromBorderSide(BorderSide(color: AppColors.light.boardBackground, width: 0.5)),
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    panelDecoration: const BoxDecoration(color: Colors.transparent),

    symbolStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.light.cellLabel),
  );

  static final SplitFlapTheme dark = SplitFlapTheme(
    tileDecoration: BoxDecoration(
      color: AppColors.dark.boardBorder,
      border: Border.fromBorderSide(BorderSide(color: AppColors.dark.boardBackground, width: 0.5)),
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    panelDecoration: const BoxDecoration(color: Colors.transparent),
    symbolStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.dark.cellLabel),
  );
}
