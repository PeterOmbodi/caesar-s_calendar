import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';

class PuzzlePieceEntity {
  PuzzlePieceEntity({
    required this.id,
    required this.type,
    required this.placeZone,
    required this.relativeCells,
    required this.isConfigItem,
    required this.isUsersItem,
    required this.absoluteCells,
  });

  final String id;
  final PieceType type;
  final PlaceZone placeZone;
  final Set<Cell> relativeCells;
  final Set<Cell> absoluteCells;
  final bool isConfigItem;
  final bool isUsersItem;
}
