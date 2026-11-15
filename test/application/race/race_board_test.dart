import 'package:caesar_puzzle/application/race/race_board.dart';
import 'package:caesar_puzzle/core/models/placement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final board = RaceBoard([PlacementParams('Z-Shape', 3, -1, 1, true), PlacementParams('L-Shape', 0, 4, 0, false)]);

  Map<String, Object?> stored(final RaceBoard board) => {...board.toValue(publishedAt: 'timestamp'), 'at': 9000};

  test('goes through the database value unchanged', () {
    expect(RaceBoard.fromValue(stored(board)), board);
  });

  test('pieces are kept in id order, so equal boards compare equal', () {
    expect(board.pieces.map((final p) => p.pieceId), ['L-Shape', 'Z-Shape']);
    expect(RaceBoard(board.pieces.reversed), board);
  });

  test('a board without pieces is still a board', () {
    expect(RaceBoard.fromValue({'at': 9000}), RaceBoard(const []));
  });

  test('the web hands numbers over as doubles', () {
    final value = {
      'at': 9000.0,
      'pieces': {
        'Square': {'row': 2.0, 'col': 3.0, 'rot': 0.0, 'flip': false},
      },
    };
    expect(RaceBoard.fromValue(value), RaceBoard([PlacementParams('Square', 2, 3, 0, false)]));
  });

  test('a missing or malformed value reads as no board', () {
    expect(RaceBoard.fromValue(null), isNull);
    expect(RaceBoard.fromValue({'pieces': {}}), isNull);
    expect(
      RaceBoard.fromValue({
        'at': 9000,
        'pieces': {
          'Square': {'row': 2},
        },
      }),
      isNull,
    );
  });

  test('a moved piece makes another board', () {
    expect(RaceBoard([board.pieces.first, PlacementParams('Z-Shape', 3, 0, 1, true)]), isNot(board));
  });
}
