import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/info_display_3_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('label key changes when cell size changes', () {
    final small = InfoDisplay3Cell.labelKey(label: 'Time', brightness: Brightness.light, cellSize: 50);
    final large = InfoDisplay3Cell.labelKey(label: 'Time', brightness: Brightness.light, cellSize: 80);

    expect(small, isNot(large));
  });

  test('formats timer minutes with dynamic segment count', () {
    expect(InfoDisplay3Cell.formatTimerMinutes(9), '09');
    expect(InfoDisplay3Cell.formatTimerMinutes(99), '99');
    expect(InfoDisplay3Cell.formatTimerMinutes(100), '100');
    expect(InfoDisplay3Cell.formatTimerMinutes(1001), '*01');
  });

  test('uses narrow timer minute segments for three character values', () {
    expect(InfoDisplay3Cell.timerMinuteSegmentWidth(cellSize: 100, minuteText: '99'), closeTo(40, 0.001));
    expect(InfoDisplay3Cell.timerMinuteSegmentWidth(cellSize: 100, minuteText: '100'), closeTo(28, 0.001));
    expect(InfoDisplay3Cell.timerMinuteSegmentWidth(cellSize: 100, minuteText: '*01'), closeTo(28, 0.001));
  });
}
