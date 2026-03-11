class StandardConfigPlacement {
  const StandardConfigPlacement({
    required this.row,
    required this.col,
    required this.rotationSteps,
    required this.isFlipped,
  });

  final int row;
  final int col;
  final int rotationSteps;
  final bool isFlipped;
}

class StandardPuzzleConfig {
  const StandardPuzzleConfig._();

  // SHA-256 of:
  // [{"pieceId":"zone1","row":0,"col":6,"rot":0,"flip":false},{"pieceId":"zone2","row":6,"col":3,"rot":0,"flip":false}]
  static const String id =
      'f6b4b9084919c768b93a63e6767a04b14b8961be32d7059138ac58b4feae7a6d';

  static const Map<String, StandardConfigPlacement> placementsByPieceId = {
    'zone1': StandardConfigPlacement(
      row: 0,
      col: 6,
      rotationSteps: 0,
      isFlipped: false,
    ),
    'zone2': StandardConfigPlacement(
      row: 6,
      col: 3,
      rotationSteps: 0,
      isFlipped: false,
    ),
  };
}
