import 'package:flutter/material.dart';

enum ChromeSurfaceStyle { glass, tonal }

@immutable
class ChromeTheme extends ThemeExtension<ChromeTheme> {
  const ChromeTheme({
    required this.surfaceStyle,
    required this.blurSigma,
    required this.barRadius,
    required this.barHeight,
  });

  factory ChromeTheme.of(final BuildContext context) => Theme.of(context).extension<ChromeTheme>()!;

  static const glass = ChromeTheme(surfaceStyle: ChromeSurfaceStyle.glass, blurSigma: 22, barRadius: 33, barHeight: 66);

  final ChromeSurfaceStyle surfaceStyle;
  final double blurSigma;
  final double barRadius;
  final double barHeight;

  @override
  ChromeTheme copyWith({
    final ChromeSurfaceStyle? surfaceStyle,
    final double? blurSigma,
    final double? barRadius,
    final double? barHeight,
  }) => ChromeTheme(
    surfaceStyle: surfaceStyle ?? this.surfaceStyle,
    blurSigma: blurSigma ?? this.blurSigma,
    barRadius: barRadius ?? this.barRadius,
    barHeight: barHeight ?? this.barHeight,
  );

  @override
  ChromeTheme lerp(final ChromeTheme? other, final double t) {
    if (other == null) {
      return this;
    }
    return ChromeTheme(
      surfaceStyle: t < 0.5 ? surfaceStyle : other.surfaceStyle,
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t),
      barRadius: lerpDouble(barRadius, other.barRadius, t),
      barHeight: lerpDouble(barHeight, other.barHeight, t),
    );
  }

  static double lerpDouble(final double a, final double b, final double t) => a + (b - a) * t;
}
