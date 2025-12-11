import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';

enum PieceType { lShape, square, zShape, yShape, uShape, pShape, nShape, vShape, zone1, zone2 }

String idForType(final PieceType type) {
  switch (type) {
    case PieceType.lShape:
      return 'L-Shape';
    case PieceType.square:
      return 'Square';
    case PieceType.zShape:
      return 'Z-Shape';
    case PieceType.yShape:
      return 'Y-Shape';
    case PieceType.uShape:
      return 'U-Shape';
    case PieceType.pShape:
      return 'P-Shape';
    case PieceType.nShape:
      return 'N-Shape';
    case PieceType.vShape:
      return 'V-Shape';
    case PieceType.zone1:
      return 'zone1';
    case PieceType.zone2:
      return 'zone2';
  }
}

bool isConfigType(final PieceType type) => type == PieceType.zone1 || type == PieceType.zone2;

double borderRadiusForType(final PieceType type) => isConfigType(type) ? 0 : 8.0;

class PuzzlePieceEntity {
  PuzzlePieceEntity({
    required this.id,
    required this.type,
    required this.placeZone,
    required this.relativeCells,
    required this.isConfigItem,
    required this.isUsersItem,
    this.absoluteCells,
  });

  final String id;
  final PieceType type;
  final PlaceZone placeZone;
  final Set<Cell> relativeCells;
  final Set<Cell>? absoluteCells;
  final bool isConfigItem;
  final bool isUsersItem;

  PuzzlePieceEntity copyWith({
    final Set<Cell>? relativeCells,
    final Set<Cell>? absoluteCells,
    final bool? isConfigItem,
    final bool? isUsersItem,
    final PlaceZone? placeZone,
  }) =>
      PuzzlePieceEntity(
        id: id,
        type: type,
        placeZone: placeZone ?? this.placeZone,
        relativeCells: relativeCells ?? this.relativeCells,
        absoluteCells: absoluteCells ?? this.absoluteCells,
        isConfigItem: isConfigItem ?? this.isConfigItem,
        isUsersItem: isUsersItem ?? this.isUsersItem,
      );
}
