import 'package:caesar_puzzle/core/models/placement.dart';

class BoardLayout {
  const BoardLayout({
    required this.id,
    required this.name,
    required this.placements,
    this.pieceSetId = classicPieceSet,
    this.isStandard = false,
  });

  static const String classicPieceSet = 'classic8';

  final String id;
  final String name;
  final List<PlacementParams> placements;
  final String pieceSetId;
  final bool isStandard;
}
