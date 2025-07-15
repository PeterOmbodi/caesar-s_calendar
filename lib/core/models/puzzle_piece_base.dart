import 'package:flutter/material.dart';

enum PlaceZone { grid, board }

class PuzzlePieceBase {
  final String id;
  final PlaceZone placeZone;
  final Offset position;
  final double rotation;
  final bool isFlipped;

  const PuzzlePieceBase({
    required this.id,
    required this.placeZone,
    required this.position,
    required this.rotation,
    required this.isFlipped,
  });
}
