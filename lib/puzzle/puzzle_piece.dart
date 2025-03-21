import 'package:flutter/material.dart';
import 'dart:math' as math;

class PuzzlePiece {
  final Path path;
  final Color color;
  final String id;
  final Offset centerPoint;
  Offset position;
  double rotation;
  bool isFlipped = false;

  PuzzlePiece({
    required this.path,
    required this.color,
    required this.id,
    required this.position,
    this.rotation = 0.0,
    required this.centerPoint,
    this.isFlipped = false,
  });

  void mirror() {
    isFlipped = !isFlipped;
  }

  bool containsPoint(Offset point) {
    final matrix = Matrix4.identity()
      ..translate(position.dx, position.dy)
      ..translate(centerPoint.dx, centerPoint.dy)
      ..rotateZ(rotation);

    if (isFlipped) {
      matrix.scale(-1.0, 1.0);
    }

    matrix.translate(-centerPoint.dx, -centerPoint.dy);

    final invertedMatrix = Matrix4.inverted(matrix);
    final transformedPoint = Offset(
      invertedMatrix.storage[0] * point.dx + invertedMatrix.storage[4] * point.dy + invertedMatrix.storage[12],
      invertedMatrix.storage[1] * point.dx + invertedMatrix.storage[5] * point.dy + invertedMatrix.storage[13],
    );

    return path.contains(transformedPoint);
  }

  PuzzlePiece copyWith({Offset? newPosition, double? newRotation, bool? newIsFlipped}) {
    return PuzzlePiece(
      path: path,
      color: color,
      id: id,
      position: newPosition ?? position,
      rotation: newRotation ?? rotation,
      centerPoint: centerPoint,
      isFlipped: newIsFlipped ?? isFlipped,
    );
  }

  Path getTransformedPath() {
    final matrix = Matrix4.identity()
      ..translate(position.dx, position.dy)
      ..translate(centerPoint.dx, centerPoint.dy)
      ..rotateZ(rotation);

    if (isFlipped) {
      matrix.scale(-1.0, 1.0);
    }

    matrix.translate(-centerPoint.dx, -centerPoint.dy);

    return path.transform(matrix.storage);
  }

  void rotate() {
    rotation = (rotation + math.pi / 2) % (math.pi * 2);
  }
}
