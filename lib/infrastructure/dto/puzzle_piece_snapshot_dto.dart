import 'package:caesar_puzzle/application/models/puzzle_piece_snapshot.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/core/models/position.dart';

class PuzzlePieceSnapshotDto {
  const PuzzlePieceSnapshotDto({
    required this.id,
    required this.placeZone,
    required this.position,
    required this.rotation,
    required this.isFlipped,
    required this.isUsersItem,
    required this.isConfigItem,
  });

  factory PuzzlePieceSnapshotDto.fromMap(final Map<String, dynamic> map) => PuzzlePieceSnapshotDto(
    id: map['id'] as String,
    placeZone: PlaceZone.values.byName(map['zone'] as String),
    position: Position.fromMap(Map<String, dynamic>.from(map['pos'] as Map)),
    rotation: (map['rotation'] as num).toDouble(),
    isFlipped: map['isFlipped'] as bool,
    isUsersItem: map['isUsersItem'] as bool,
    isConfigItem: map['isConfigItem'] as bool,
  );

  factory PuzzlePieceSnapshotDto.fromDomain(final PuzzlePieceSnapshot snapshot) => PuzzlePieceSnapshotDto(
    id: snapshot.id,
    placeZone: snapshot.placeZone,
    position: snapshot.position,
    rotation: snapshot.rotation,
    isFlipped: snapshot.isFlipped,
    isUsersItem: snapshot.isUsersItem,
    isConfigItem: snapshot.isConfigItem,
  );

  final String id;
  final PlaceZone placeZone;
  final Position position;
  final double rotation;
  final bool isFlipped;
  final bool isUsersItem;
  final bool isConfigItem;

  Map<String, dynamic> toMap() => {
    'id': id,
    'zone': placeZone.name,
    'pos': position.toMap(),
    'rotation': rotation,
    'isFlipped': isFlipped,
    'isUsersItem': isUsersItem,
    'isConfigItem': isConfigItem,
  };

  PuzzlePieceSnapshot toDomain() => PuzzlePieceSnapshot(
    id: id,
    placeZone: placeZone,
    position: position,
    rotation: rotation,
    isFlipped: isFlipped,
    isUsersItem: isUsersItem,
    isConfigItem: isConfigItem,
  );
}
