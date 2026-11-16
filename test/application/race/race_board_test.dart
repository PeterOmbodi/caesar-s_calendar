import 'package:caesar_puzzle/application/race/race_board.dart';
import 'package:caesar_puzzle/core/models/placement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final board = RaceBoard([PlacementParams('Z-Shape', 3, -1, 1, true), PlacementParams('L-Shape', 0, 4, 0, false)]);

  test('pieces are kept in id order, so equal boards compare equal', () {
    expect(board.pieces.map((final p) => p.pieceId), ['L-Shape', 'Z-Shape']);
    expect(RaceBoard(board.pieces.reversed), board);
  });

  test('a moved piece makes another board', () {
    expect(RaceBoard([board.pieces.first, PlacementParams('Z-Shape', 3, 0, 1, true)]), isNot(board));
  });
}
