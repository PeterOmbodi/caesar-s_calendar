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
}
