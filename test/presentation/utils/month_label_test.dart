import 'package:caesar_puzzle/presentation/utils/month_label.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  setUpAll(() => initializeDateFormatting());

  test('drops the trailing dot of abbreviated months', () {
    Intl.withLocale('uk', () {
      expect(shortMonthName(10), 'жовт');
      expect(shortMonthName(5), isNot(endsWith('.')));
    });
    Intl.withLocale('en', () => expect(shortMonthName(10), 'Oct'));
  });

  test('months are short words, not digits or full names', () {
    for (final locale in ['bg', 'lt', 'et']) {
      Intl.withLocale(locale, () {
        for (var month = 1; month <= 12; month++) {
          final name = shortMonthName(month);
          expect(name, isNot(matches(RegExp(r'^\d+$'))), reason: '$locale $month');
          expect(name.length, lessThanOrEqualTo(5), reason: '$locale $name');
        }
      });
    }
  });

  test('months keep the size when they fit and share a smaller one when the widest does not', () {
    Intl.withLocale('en', () {
      expect(monthLabelFontSize(maxFontSize: 17, maxWidth: 200), 17);
      final small = monthLabelFontSize(maxFontSize: 17, maxWidth: 20);
      expect(small, lessThan(17));
      expect(small, greaterThan(0));
    });
  });
}
