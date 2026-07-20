import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/puzzle_board_painter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cell label font size scales with grid cell size', () {
    expect(PuzzleBoardPainter.cellLabelFontSize(50), closeTo(14, 0.001));
    expect(PuzzleBoardPainter.cellLabelFontSize(100), greaterThan(PuzzleBoardPainter.cellLabelFontSize(50)));
  });
}
