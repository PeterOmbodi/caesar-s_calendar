import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/core/models/position.dart';

class PuzzlePieceSnapshot {
  const PuzzlePieceSnapshot({
    required this.id,
    required this.placeZone,
    required this.position,
    required this.rotation,
    required this.isFlipped,
    required this.isUsersItem,
    required this.isConfigItem,
  });

  final String id;
  final PlaceZone placeZone;
  final Position position;
  final double rotation;
  final bool isFlipped;
  final bool isUsersItem;
  final bool isConfigItem;
}
