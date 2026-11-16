// Prints the short month names of every app locale: fvm flutter test tool/month_labels
import 'package:caesar_puzzle/presentation/utils/month_label.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

const _locales = [
  'bg',
  'cs',
  'da',
  'de',
  'en',
  'es',
  'et',
  'fi',
  'fr',
  'hr',
  'hu',
  'is',
  'it',
  'lt',
  'lv',
  'mk',
  'nb',
  'nl',
  'pl',
  'pt',
  'ro',
  'sk',
  'sl',
  'sq',
  'sv',
  'uk',
];

void main() {
  setUpAll(() => initializeDateFormatting());

  test('short month names', () {
    for (final locale in _locales) {
      final months = Intl.withLocale(locale, () => [for (var m = 1; m <= 12; m++) shortMonthName(m)]);
      final pattern = Intl.withLocale(
        locale,
        () => [for (var m = 1; m <= 12; m++) DateFormat('MMM').format(DateTime(2000, m))],
      );
      final longest = months.map((final m) => m.length).reduce((final a, final b) => a > b ? a : b);
      // ignore: avoid_print
      print('$locale  max $longest  ${months.join(' ')}\n    was: ${pattern.join(' ')}');
    }
  });
}
