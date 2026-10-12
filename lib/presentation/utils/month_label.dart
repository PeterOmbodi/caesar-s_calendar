import 'package:intl/intl.dart';

/// Abbreviated month without the trailing dot some locales add ("жовт." → "жовт").
String shortMonthName(final int month) => DateFormat('MMM').format(DateTime(2000, month)).replaceFirst(RegExp(r'\.$'), '');
