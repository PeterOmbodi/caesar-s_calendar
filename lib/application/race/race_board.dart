import 'package:caesar_puzzle/core/models/placement.dart';

/// A player's pieces on the board at the end of the race, without the blocked cells.
class RaceBoard {
  RaceBoard(final Iterable<PlacementParams> pieces, {this.publishedAtMs})
    : pieces = List.unmodifiable(pieces.toList()..sort((final a, final b) => a.pieceId.compareTo(b.pieceId)));

  final List<PlacementParams> pieces;

  /// Server time of the write; null for a board that has not been through the database.
  final int? publishedAtMs;

  /// The database drops empty maps; [publishedAt] keeps a board without pieces.
  Map<String, Object?> toValue({required final Object publishedAt}) => {
    'at': publishedAt,
    'pieces': {
      for (final p in pieces) p.pieceId: {'row': p.row, 'col': p.col, 'rot': p.rotationSteps, 'flip': p.isFlipped},
    },
  };

  /// Null for a missing or malformed value.
  static RaceBoard? fromValue(final Object? value) {
    if (value is! Map || value['at'] is! num) {
      return null;
    }
    final entries = value['pieces'] ?? const {};
    if (entries is! Map) {
      return null;
    }
    final pieces = <PlacementParams>[];
    for (final MapEntry(key: id, value: piece) in entries.entries) {
      if (piece is! Map) {
        return null;
      }
      final row = piece['row'];
      final col = piece['col'];
      final rot = piece['rot'];
      final flip = piece['flip'];
      if (row is! num || col is! num || rot is! num || flip is! bool) {
        return null;
      }
      pieces.add(PlacementParams('$id', row.toInt(), col.toInt(), rot.toInt(), flip));
    }
    return RaceBoard(pieces, publishedAtMs: (value['at']! as num).toInt());
  }

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
