import 'dart:convert';

import 'package:caesar_puzzle/core/constants/standard_puzzle_config.dart';
import 'package:caesar_puzzle/core/models/placement.dart';

/// The config id is a hash of this JSON, so the format must not change.
class PuzzleConfigJson {
  const PuzzleConfigJson._();

  static String encode(final List<PlacementParams> placements) => jsonEncode([
    for (final p in placements)
      {'pieceId': p.pieceId, 'row': p.row, 'col': p.col, 'rot': p.rotationSteps, 'flip': p.isFlipped},
  ]);

  static List<PlacementParams> decode(final String json) => [
    for (final item in (jsonDecode(json) as List).cast<Map<String, dynamic>>())
      PlacementParams(
        item['pieceId'] as String,
        item['row'] as int,
        item['col'] as int,
        item['rot'] as int,
        item['flip'] as bool,
      ),
  ];

  static List<PlacementParams> get standardPlacements => [
    for (final MapEntry(key: id, value: p) in StandardPuzzleConfig.placementsByPieceId.entries)
      PlacementParams(id, p.row, p.col, p.rotationSteps, p.isFlipped),
  ];
}
