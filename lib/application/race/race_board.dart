import 'package:caesar_puzzle/core/models/placement.dart';

/// A player's pieces on the board at the end of the race, without the blocked cells.
class RaceBoard {
  RaceBoard(final Iterable<PlacementParams> pieces, {this.publishedAtMs})
    : pieces = List.unmodifiable(pieces.toList()..sort((final a, final b) => a.pieceId.compareTo(b.pieceId)));

  final List<PlacementParams> pieces;

  /// Server time of the write; null for a board that has not been through the database.
  final int? publishedAtMs;

  static String _key(final PlacementParams p) => '${p.pieceId}:${p.row}:${p.col}:${p.rotationSteps}:${p.isFlipped}';

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is RaceBoard &&
          other.pieces.length == pieces.length &&
          Iterable<int>.generate(pieces.length).every((final i) => _key(other.pieces[i]) == _key(pieces[i]));

  @override
  int get hashCode => Object.hashAll(pieces.map(_key));
}
