import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:intl/intl.dart' show DateFormat, Intl;

/// Abbreviated month without the trailing dot some locales add ("жовт." → "жовт").
/// From the date symbols, not `DateFormat('MMM')`: that pattern gives digits in Bulgarian and Lithuanian and full
/// names in Estonian.
String shortMonthName(final int month) =>
    DateFormat.MMM().dateSymbols.STANDALONESHORTMONTHS[month - 1].replaceFirst(RegExp(r'\.$'), '');

final _monthFontSizes = <(String, double, double, FontWeight), double>{};

/// One size for all twelve months, so a row of months looks even: [maxFontSize], or smaller when the widest month
/// would not fit [maxWidth] on one line (Finnish "maalis", "marras").
double monthLabelFontSize({
  required final double maxFontSize,
  required final double maxWidth,
  final FontWeight fontWeight = FontWeight.w700,
}) => _monthFontSizes.putIfAbsent((Intl.getCurrentLocale(), maxFontSize, maxWidth, fontWeight), () {
  var widest = 0.0;
  for (var month = 1; month <= 12; month++) {
    final painter = TextPainter(
      text: TextSpan(
        text: shortMonthName(month),
        style: TextStyle(fontSize: maxFontSize, fontWeight: fontWeight),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    widest = max(widest, painter.width);
    painter.dispose();
  }
  return widest <= maxWidth ? maxFontSize : maxFontSize * maxWidth / widest;
});
