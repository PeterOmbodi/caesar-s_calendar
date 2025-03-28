import 'dart:math' as math;

import 'package:flutter/material.dart';

class PuzzlePiece {
  final Path originalPath;
  final Color color;
  final String id;
  final Offset centerPoint;
  Offset position;
  double rotation;
  bool isFlipped;
  final double borderRadius;
  final bool isDraggable;

  PuzzlePiece({
    required Path path,
    required this.color,
    required this.id,
    required this.position,
    this.rotation = 0.0,
    required this.centerPoint,
    this.isFlipped = false,
    this.borderRadius = 8.0,
    this.isDraggable = true,
  }) : originalPath = path;

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

  Path get path {
    return borderRadius > 0 ? _roundExternalCorners(originalPath, borderRadius) : originalPath;
  }

  Path _roundExternalCorners(Path originalPath, double radius) {
    final List<Offset> vertices = _extractVertices(originalPath);
    if (vertices.isEmpty) return originalPath;
    final int n = vertices.length;

    List<Offset> prevLinePoints = List.filled(n, Offset.zero);
    List<Offset> nextLinePoints = List.filled(n, Offset.zero);
    List<bool> roundFlag = List.filled(n, false);
    List<double> arcOffsets = List.filled(n, 0.0);

    for (int i = 0; i < n; i++) {
      final prev = vertices[(i - 1 + n) % n];
      final curr = vertices[i];
      final next = vertices[(i + 1) % n];
      final v1 = curr - prev;
      final v2 = next - curr;
      final len1 = v1.distance;
      final len2 = v2.distance;
      if (len1 == 0 || len2 == 0) {
        roundFlag[i] = false;
        prevLinePoints[i] = curr;
        nextLinePoints[i] = curr;
        arcOffsets[i] = 0;
        continue;
      }
      final n1 = v1 / len1;
      final n2 = v2 / len2;
      final dot = (n1.dx * n2.dx + n1.dy * n2.dy).clamp(-1.0, 1.0);
      final angle = math.acos(dot);
      final cross = n1.dx * n2.dy - n1.dy * n2.dx;
      bool isConvex = cross > 0;
      if ((angle - math.pi).abs() < 0.01 || !isConvex) {
        roundFlag[i] = false;
        prevLinePoints[i] = curr;
        nextLinePoints[i] = curr;
        arcOffsets[i] = 0;
      } else {
        roundFlag[i] = true;
        double offset = math.min(radius, math.min(len1 / 2, len2 / 2));
        arcOffsets[i] = offset;
        prevLinePoints[i] = curr - n1 * offset;
        nextLinePoints[i] = curr + n2 * offset;
      }
    }

    final Path newPath = Path();
    final Offset startPoint = roundFlag[0] ? prevLinePoints[0] : vertices[0];
    newPath.moveTo(startPoint.dx, startPoint.dy);

    for (int i = 0; i < n; i++) {
      if (roundFlag[i]) {
        newPath.lineTo(prevLinePoints[i].dx, prevLinePoints[i].dy);
        newPath.arcToPoint(
          nextLinePoints[i],
          radius: Radius.circular(arcOffsets[i]),
          clockwise: true,
        );
      } else {
        newPath.lineTo(vertices[i].dx, vertices[i].dy);
      }
    }
    newPath.close();
    return newPath;
  }

  List<Offset> _extractVertices(Path path) {
    final List<Offset> points = [];
    for (final metric in path.computeMetrics()) {
      final int samples = (metric.length / 2).ceil();
      Offset? lastPoint;
      for (int i = 0; i <= samples; i++) {
        final double t = metric.length * i / samples;
        final tangent = metric.getTangentForOffset(t);
        if (tangent != null) {
          final point = tangent.position;
          if (lastPoint == null || (point - lastPoint).distance > 1.0) {
            points.add(point);
            lastPoint = point;
          }
        }
      }
    }
    return _removeCollinear(points, tolerance: 0.5);
  }

  List<Offset> _removeCollinear(List<Offset> points, {double tolerance = 0.5}) {
    if (points.length < 3) return points;
    final List<Offset> result = [];
    for (int i = 0; i < points.length; i++) {
      final prev = points[(i - 1 + points.length) % points.length];
      final current = points[i];
      final next = points[(i + 1) % points.length];
      final v1 = current - prev;
      final v2 = next - current;
      final cross = (v1.dx * v2.dy - v1.dy * v2.dx).abs();
      if (cross > tolerance || i == 0) {
        result.add(current);
      }
    }
    return result;
  }

  PuzzlePiece copyWith({
    Offset? newPosition,
    double? newRotation,
    bool? newIsFlipped,
    bool? newIsDraggable,
  }) {
    return PuzzlePiece(
      path: originalPath,
      color: color,
      id: id,
      position: newPosition ?? position,
      rotation: newRotation ?? rotation,
      centerPoint: centerPoint,
      isFlipped: newIsFlipped ?? isFlipped,
      borderRadius: borderRadius,
      isDraggable: newIsDraggable ?? isDraggable,
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
