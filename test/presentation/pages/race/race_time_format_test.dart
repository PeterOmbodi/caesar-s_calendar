import 'package:caesar_puzzle/presentation/pages/race/race_time_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('race times in minutes and seconds, with tenths when asked', () {
    expect(formatRaceTime(102345), '1:42');
    expect(formatRaceTime(102345, tenths: true), '1:42.3');
    expect(formatRaceTime(-5), '0:00');
  });

  test('gaps in seconds with tenths, in minutes from a minute on', () {
    expect(formatRaceGap(34250), '+34.2');
    expect(formatRaceGap(900), '+0.9');
    expect(formatRaceGap(65300), '+1:05.3');
  });
}
