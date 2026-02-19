import 'package:caesar_puzzle/core/models/move.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/core/models/position.dart';

class MovePlacementDto {
  const MovePlacementDto({required this.zone, required this.position});

  factory MovePlacementDto.fromMap(final Map<String, dynamic> map) => MovePlacementDto(
    zone: PlaceZone.values.byName(map['zone'] as String),
    position: Position.fromMap(Map<String, dynamic>.from(map['position'] as Map)),
  );

  factory MovePlacementDto.fromDomain(final MovePlacement placement) => MovePlacementDto(
    zone: placement.zone,
    position: placement.position,
  );

  final PlaceZone zone;
  final Position position;

  Map<String, dynamic> toMap() => {'zone': zone.name, 'position': position.toMap()};

  MovePlacement toDomain() => MovePlacement(zone: zone, position: position);
}

class MovePieceDto {
  const MovePieceDto({required this.from, required this.to});

  factory MovePieceDto.fromMap(final Map<String, dynamic> map) => MovePieceDto(
    from: MovePlacementDto.fromMap(Map<String, dynamic>.from(map['from'] as Map)),
    to: MovePlacementDto.fromMap(Map<String, dynamic>.from(map['to'] as Map)),
  );

  factory MovePieceDto.fromDomain(final MovePiece move) => MovePieceDto(
    from: MovePlacementDto.fromDomain(move.from),
    to: MovePlacementDto.fromDomain(move.to),
  );

  final MovePlacementDto from;
  final MovePlacementDto to;

  Map<String, dynamic> toMap() => {'from': from.toMap(), 'to': to.toMap()};

  MovePiece toDomain(final String pieceId) => MovePiece(
    pieceId,
    from: from.toDomain(),
    to: to.toDomain(),
  );
}

class MoveDto {
  const MoveDto({required this.type, required this.pieceId, this.data});

  factory MoveDto.fromMap(final Map<String, dynamic> map) => MoveDto(
    type: map['type'] as String,
    pieceId: map['pieceId'] as String,
    data: map['data'] == null ? null : Map<String, dynamic>.from(map['data'] as Map),
  );

  factory MoveDto.fromDomain(final Move move) => move.map(
    movePiece: (final mp) => MoveDto(
      type: _MoveTypes.movePiece,
      pieceId: mp.pieceId,
      data: MovePieceDto.fromDomain(mp).toMap(),
    ),
    rotatePiece: (final rp) => MoveDto(
      type: _MoveTypes.rotatePiece,
      pieceId: rp.pieceId,
      data: {
        'rotation': rp.rotation,
        'snapCorrection': rp.snapCorrection == null ? null : MovePieceDto.fromDomain(rp.snapCorrection!).toMap(),
      },
    ),
    flipPiece: (final fp) => MoveDto(
      type: _MoveTypes.flipPiece,
      pieceId: fp.pieceId,
      data: {
        'isFlipped': fp.isFlipped,
        'snapCorrection': fp.snapCorrection == null ? null : MovePieceDto.fromDomain(fp.snapCorrection!).toMap(),
      },
    ),
    hintMove: (final hm) => MoveDto(
      type: _MoveTypes.hintMove,
      pieceId: hm.pieceId,
      data: {
        'from': MovePlacementDto.fromDomain(hm.from).toMap(),
        'to': MovePlacementDto.fromDomain(hm.to).toMap(),
        'rotationFrom': hm.rotationFrom,
        'rotationTo': hm.rotationTo,
        'flippedFrom': hm.flippedFrom,
        'flippedTo': hm.flippedTo,
      },
    ),
  );

  final String type;
  final String pieceId;
  final Map<String, dynamic>? data;

  Map<String, dynamic> toMap() => {'type': type, 'pieceId': pieceId, 'data': data};

  Move toDomain() {
    switch (type) {
      case _MoveTypes.movePiece:
        return MovePieceDto.fromMap(Map<String, dynamic>.from(data!)).toDomain(pieceId);
      case _MoveTypes.rotatePiece:
        final payload = Map<String, dynamic>.from(data!);
        final snap = payload['snapCorrection'] == null
            ? null
            : MovePieceDto.fromMap(Map<String, dynamic>.from(payload['snapCorrection'] as Map)).toDomain(pieceId);
        return RotatePiece(pieceId, snap, rotation: (payload['rotation'] as num).toDouble());
      case _MoveTypes.flipPiece:
        final payload = Map<String, dynamic>.from(data!);
        final snap = payload['snapCorrection'] == null
            ? null
            : MovePieceDto.fromMap(Map<String, dynamic>.from(payload['snapCorrection'] as Map)).toDomain(pieceId);
        return FlipPiece(pieceId, snap, isFlipped: payload['isFlipped'] as bool);
      case _MoveTypes.hintMove:
        final payload = Map<String, dynamic>.from(data!);
        return HintMove(
          pieceId,
          from: MovePlacementDto.fromMap(Map<String, dynamic>.from(payload['from'] as Map)).toDomain(),
          to: MovePlacementDto.fromMap(Map<String, dynamic>.from(payload['to'] as Map)).toDomain(),
          rotationFrom: (payload['rotationFrom'] as num).toDouble(),
          rotationTo: (payload['rotationTo'] as num).toDouble(),
          flippedFrom: payload['flippedFrom'] as bool,
          flippedTo: payload['flippedTo'] as bool,
        );
    }
    throw StateError('Unknown move type: $type');
  }
}

class _MoveTypes {
  static const movePiece = 'move_piece';
  static const rotatePiece = 'rotate_piece';
  static const flipPiece = 'flip_piece';
  static const hintMove = 'hint_move';
}
