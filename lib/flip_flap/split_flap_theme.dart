import 'package:flutter/material.dart';

@immutable
class FlipFlapTheme extends ThemeExtension<FlipFlapTheme> {
  const FlipFlapTheme({required this.tileDecoration, required this.panelDecoration, required this.symbolStyle});

  final BoxDecoration tileDecoration;
  final BoxDecoration panelDecoration;
  final TextStyle symbolStyle;

  @override
  FlipFlapTheme copyWith({
    final BoxDecoration? tileDecoration,
    final BoxDecoration? panelDecoration,
    final TextStyle? symbolStyle,
  }) => FlipFlapTheme(
    tileDecoration: tileDecoration ?? this.tileDecoration,
    panelDecoration: panelDecoration ?? this.panelDecoration,
    symbolStyle: symbolStyle ?? this.symbolStyle,
  );

  @override
  FlipFlapTheme lerp(final ThemeExtension<FlipFlapTheme>? other, final double t) {
    if (other is! FlipFlapTheme) return this;

    return FlipFlapTheme(
      tileDecoration: BoxDecoration.lerp(tileDecoration, other.tileDecoration, t) ?? tileDecoration,
      panelDecoration: BoxDecoration.lerp(panelDecoration, other.panelDecoration, t) ?? panelDecoration,
      symbolStyle: TextStyle.lerp(symbolStyle, other.symbolStyle, t) ?? symbolStyle,
    );
  }

  static FlipFlapTheme of(final BuildContext context) {
    final fromTheme = Theme.of(context).extension<FlipFlapTheme>();
    if (fromTheme != null) return fromTheme;
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? FlipFlapTheme.dark : FlipFlapTheme.light;
  }

  static final FlipFlapTheme light = FlipFlapTheme(
    tileDecoration: const BoxDecoration(
      color: Color(0xFFE0E0E0),
      border: Border.fromBorderSide(BorderSide(color: Color(0xFF424242), width: 0.5)),
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    panelDecoration: const BoxDecoration(color: Colors.transparent),
    symbolStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black87),
  );

  static final FlipFlapTheme dark = FlipFlapTheme(
    tileDecoration: const BoxDecoration(
      color: Color(0xFF424242),
      border: Border.fromBorderSide(BorderSide(color: Color(0xFFFFFFFF), width: 0.5)),
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    panelDecoration: const BoxDecoration(color: Colors.transparent),
    symbolStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white70),
  );
}
