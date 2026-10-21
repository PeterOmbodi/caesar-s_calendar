import 'dart:math' as math;

import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:flutter/material.dart';

typedef _Point = ({int x, int y});

/// Outline of a group of grid cells, shrunk by [inset] and with corners rounded by [radius].
///
/// Coordinates start at the top-left corner of cell (0, 0). Groups with holes or several
/// separate parts produce one closed contour per boundary.
Path cellOutlinePath(
  final Iterable<Cell> cells,
  final double cellSize, {
  final double inset = 0,
  final double radius = 0,
}) {
  final path = Path();
  for (final loop in _boundaryLoops(cells)) {
    _addRoundedContour(
      path,
      [for (final p in loop) Offset(p.x * cellSize, p.y * cellSize)],
      inset: inset,
      radius: radius,
    );
  }
  return path;
}

// Every cell contributes its four edges clockwise (y points down); an edge shared by two cells
// appears in both directions and cancels out, so only the boundary is left, with the cells on its right.
List<List<_Point>> _boundaryLoops(final Iterable<Cell> cells) {
  final edges = <(_Point, _Point)>{};
  void add(final _Point a, final _Point b) {
    if (!edges.remove((b, a))) {
      edges.add((a, b));
    }
  }

  for (final cell in cells) {
    final x = cell.col;
    final y = cell.row;
    add((x: x, y: y), (x: x + 1, y: y));
    add((x: x + 1, y: y), (x: x + 1, y: y + 1));
    add((x: x + 1, y: y + 1), (x: x, y: y + 1));
    add((x: x, y: y + 1), (x: x, y: y));
  }

  final outgoing = <_Point, List<_Point>>{};
  for (final (a, b) in edges) {
    outgoing.putIfAbsent(a, () => []).add(b);
  }

  final loops = <List<_Point>>[];
  while (outgoing.isNotEmpty) {
    final start = outgoing.keys.first;
    final loop = <_Point>[start];
    var prev = start;
    var current = _takeNext(outgoing, start, null);
    while (current != start) {
      loop.add(current);
      final next = _takeNext(outgoing, current, (dx: current.x - prev.x, dy: current.y - prev.y));
      prev = current;
      current = next;
    }
    loops.add(_withoutStraightVertices(loop));
  }
  return loops;
}

// Where two cells touch only by a corner, a vertex has two outgoing edges; turning right keeps
// each contour simple.
_Point _takeNext(
  final Map<_Point, List<_Point>> outgoing,
  final _Point from,
  final ({int dx, int dy})? incoming,
) {
  final candidates = outgoing[from]!;
  var index = 0;
  if (incoming != null && candidates.length > 1) {
    int turn(final _Point to) => incoming.dx * (to.y - from.y) - incoming.dy * (to.x - from.x);
    for (var i = 1; i < candidates.length; i++) {
      if (turn(candidates[i]) > turn(candidates[index])) {
        index = i;
      }
    }
  }
  final next = candidates.removeAt(index);
  if (candidates.isEmpty) {
    outgoing.remove(from);
  }
  return next;
}

List<_Point> _withoutStraightVertices(final List<_Point> loop) {
  final n = loop.length;
  return [
    for (var i = 0; i < n; i++)
      if (!_isStraight(loop[(i - 1 + n) % n], loop[i], loop[(i + 1) % n])) loop[i],
  ];
}

bool _isStraight(final _Point a, final _Point p, final _Point c) =>
    (a.x == p.x && p.x == c.x) || (a.y == p.y && p.y == c.y);

void _addRoundedContour(
  final Path path,
  final List<Offset> corners, {
  required final double inset,
  required final double radius,
}) {
  final n = corners.length;
  Offset dir(final Offset a, final Offset b) => Offset((b.dx - a.dx).sign, (b.dy - a.dy).sign);

  // Move every corner inwards; the inward normal of an edge with direction d is (-d.y, d.x).
  final inner = <Offset>[];
  for (var i = 0; i < n; i++) {
    final d1 = dir(corners[(i - 1 + n) % n], corners[i]);
    final d2 = dir(corners[i], corners[(i + 1) % n]);
    inner.add(corners[i] + Offset(-d1.dy - d2.dy, d1.dx + d2.dx) * inset);
  }

  final starts = <Offset>[];
  final ends = <Offset>[];
  final radii = <double>[];
  final clockwise = <bool>[];
  for (var i = 0; i < n; i++) {
    final a = inner[(i - 1 + n) % n];
    final p = inner[i];
    final c = inner[(i + 1) % n];
    final r = math.min(radius, math.min((p - a).distance / 2, (c - p).distance / 2));
    final d1 = dir(a, p);
    final d2 = dir(p, c);
    starts.add(p - d1 * r);
    ends.add(p + d2 * r);
    radii.add(r);
    clockwise.add(d1.dx * d2.dy - d1.dy * d2.dx > 0);
  }

  path.moveTo(ends[n - 1].dx, ends[n - 1].dy);
  for (var i = 0; i < n; i++) {
    path.lineTo(starts[i].dx, starts[i].dy);
    if (radii[i] > 0) {
      path.arcToPoint(ends[i], radius: Radius.circular(radii[i]), clockwise: clockwise[i]);
    }
  }
  path.close();
}
