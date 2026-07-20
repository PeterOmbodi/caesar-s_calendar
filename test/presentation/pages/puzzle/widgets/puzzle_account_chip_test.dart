import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/puzzle_account_chip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rebuilds when puzzle cell size changes', () {
    expect(PuzzleAccountChip.shouldRebuildForCellSize(50, 80), isTrue);
    expect(PuzzleAccountChip.shouldRebuildForCellSize(80, 80), isFalse);
  });

  test('avatar radius scales up from grid cell size', () {
    expect(PuzzleAccountChip.avatarRadiusForCellSize(50), closeTo(20, 0.001));
    expect(PuzzleAccountChip.avatarRadiusForCellSize(100), closeTo(40, 0.001));
  });

  test('placeholder icon size scales from avatar radius', () {
    expect(PuzzleAccountChip.placeholderIconSizeForRadius(12), closeTo(13.2, 0.001));
    expect(PuzzleAccountChip.placeholderIconSizeForRadius(40), closeTo(44, 0.001));
  });
}
