import 'dart:math' as math;

import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_piece.dart';
import 'package:flutter/material.dart';

/// Extension for PuzzlePiece to add the [relativeCells] getter.
/// This computes the grid cells (relative to the shape’s top-left in its default orientation)
/// covered by the piece based on its [originalPath].
extension PuzzlePieceX on PuzzlePiece {
  /// Returns the list of grid cells covered by this piece in its default orientation.
  /// It uses the bounding box of the original path and samples at the cell center.
  /// Assumes that the grid "unit" is the size of a cell.
  Set<Cell> relativeCells(final double unit) {
    // Get the bounding box of the original path.
    final Rect bounds = originalPath.getBounds();

    // Determine the starting row and column in grid units.
    final int startRow = (bounds.top - 0) ~/ unit; // 0 is an offset if needed
    final int startCol = (bounds.left - 0) ~/ unit;

    // Calculate how many grid units the bounding box spans.
    final int numRows = ((bounds.bottom - bounds.top) / unit).ceil();
    final int numCols = ((bounds.right - bounds.left) / unit).ceil();

    final Set<Cell> cells = {};

    // Iterate over each grid cell in the bounding box.
    for (int r = 0; r < numRows; r++) {
      for (int c = 0; c < numCols; c++) {
        // Calculate the center of the cell in absolute coordinates.
        final Offset cellCenter = Offset(
          (startCol + c) * unit + unit / 2,
          (startRow + r) * unit + unit / 2,
        );
        // Check if the original path contains the cell center.
        if (originalPath.contains(cellCenter)) {
          // Save the cell relative to the bounding box top-left.
          cells.add(Cell(r, c));
        }
      }
    }

    return cells;
  }

  /// Returns a set of grid cells (as [Cell]) that are covered by the given [originalPath].
  /// The [origin] represents the top-left corner of the grid and [cellSize] is the size of one grid cell.
  Set<Cell> cells(Offset origin, double cellSize) {
    final path = getTransformedPath();
    final Set<Cell> cells = {};
    final Rect bounds = path.getBounds();
    // Determine grid indices covering the path's bounding box.
    // We adjust by the grid's origin.
    final int startCol = ((bounds.left - origin.dx) / cellSize).floor();
    final int startRow = ((bounds.top - origin.dy) / cellSize).floor();
    final int endCol = ((bounds.right - origin.dx) / cellSize).ceil();
    final int endRow = ((bounds.bottom - origin.dy) / cellSize).ceil();

    // Loop over each grid cell index within the bounding box.
    for (int row = startRow; row < endRow; row++) {
      for (int col = startCol; col < endCol; col++) {
        // Compute the center point of the cell.
        final Offset cellCenter = Offset(
          origin.dx + col * cellSize + centerPoint.dx,
          origin.dy + row * cellSize + centerPoint.dy,
        );
        // If the cell center lies within the path, add the cell.
        if (path.contains(cellCenter)) {
          cells.add(Cell(row, col));
        }
      }
    }
    return cells;
  }

  Path getTransformedPath() {
    return path.transform(_getMatrix().storage);
  }

  bool containsPoint(Offset point) {
    final invertedMatrix = Matrix4.inverted(_getMatrix());
    final transformedPoint = Offset(
      invertedMatrix.storage[0] * point.dx + invertedMatrix.storage[4] * point.dy + invertedMatrix.storage[12],
      invertedMatrix.storage[1] * point.dx + invertedMatrix.storage[5] * point.dy + invertedMatrix.storage[13],
    );

    return path.contains(transformedPoint);
  }

  Path get path {
    return borderRadius > 0 ? _roundExternalCorners(originalPath, borderRadius) : originalPath;
  }

  Matrix4 _getMatrix() {
    final matrix = Matrix4.identity()
      ..translate(position.dx, position.dy)
      ..translate(centerPoint.dx, centerPoint.dy);

    if (isFlipped) {
      matrix.scale(-1.0, 1.0);
    }

    matrix
      ..rotateZ(rotation)
      ..translate(-centerPoint.dx, -centerPoint.dy);
    return matrix;
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
}
