import 'dart:math' as math;

import 'package:caesar_puzzle/puzzle/puzzle_grid.dart';
import 'package:caesar_puzzle/puzzle/puzzle_piece.dart';
import 'package:flutter/material.dart';

class PuzzleGame extends StatefulWidget {
  const PuzzleGame({super.key});

  @override
  PuzzleGameState createState() => PuzzleGameState();
}

class PuzzleGameState extends State<PuzzleGame> {
  List<PuzzlePiece> pieces = [];
  PuzzlePiece? selectedPiece;
  Offset? dragStartOffset;
  late PuzzleGrid grid;
  bool isDragging = false;

  @override
  void initState() {
    super.initState();
    grid = PuzzleGrid(
      cellSize: 50,
      rows: 7,
      columns: 7,
      origin: const Offset(50, 50),
    );
    _initializePieces();
  }

  void _initializePieces() {
    final Path lShape = Path()
      ..moveTo(0, 0)
      ..lineTo(50, 0)
      ..lineTo(50, 50)
      ..lineTo(100, 50)
      ..lineTo(100, 100)
      ..lineTo(0, 100)
      ..close();

    final Offset lCenter = const Offset(50, 50);

    final Path tShape = Path()
      ..moveTo(25, 0)
      ..lineTo(75, 0)
      ..lineTo(75, 50)
      ..lineTo(100, 50)
      ..lineTo(100, 100)
      ..lineTo(0, 100)
      ..lineTo(0, 50)
      ..lineTo(25, 50)
      ..close();

    final Offset tCenter = const Offset(50, 50);

    pieces = [
      PuzzlePiece(
        path: lShape,
        color: Colors.blue.withOpacity(0.7),
        id: 'L-shape',
        position: const Offset(50, 50),
        centerPoint: lCenter,
      ),
      PuzzlePiece(
        path: tShape,
        color: Colors.red.withOpacity(0.7),
        id: 'T-shape',
        position: const Offset(200, 50),
        centerPoint: tCenter,
      ),
    ];
  }

  PuzzlePiece? _findPieceAtPosition(Offset position) {
    for (int i = pieces.length - 1; i >= 0; i--) {
      if (pieces[i].containsPoint(position)) {
        return pieces[i];
      }
    }
    return null;
  }

  void _rotatePiece(PuzzlePiece piece) {
    setState(() {
      final index = pieces.indexOf(piece);
      if (index != -1) {
        final newRotation = (piece.rotation + math.pi / 2) % (math.pi * 2);
        pieces[index] = piece.copyWith(newRotation: newRotation);
      }
    });
  }

  bool _checkCollision(PuzzlePiece piece, Offset newPosition) {
    // Create a temporary piece with new position for collision testing
    final testPiece = piece.copyWith(newPosition: newPosition);
    final testPath = testPiece.getTransformedPath();

    // Check collision with other pieces
    for (var otherPiece in pieces) {
      if (otherPiece.id != piece.id) {
        final otherPath = otherPiece.getTransformedPath();

        // Use Path.combine to check for intersection
        final combinedPath = Path.combine(PathOperation.intersect, testPath, otherPath);

        // If combinedPath is not empty, there's a collision
        if (!combinedPath.getBounds().isEmpty) {
          return true;
        }
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Календарь Цезаря'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _initializePieces();
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTapDown: (details) {
              final piece = _findPieceAtPosition(details.localPosition);
              if (piece != null) {
                setState(() {
                  selectedPiece = piece;
                });
              }
            },
            onTapUp: (details) {
              // check isDragging
              if (selectedPiece != null && !isDragging) {
                _rotatePiece(selectedPiece!);
              }
              setState(() {
                selectedPiece = null;
                isDragging = false;
              });
            },
            onPanStart: (details) {
              final piece = _findPieceAtPosition(details.localPosition);
              if (piece != null) {
                setState(() {
                  // order item
                  pieces.remove(piece);
                  pieces.add(piece);

                  selectedPiece = pieces.last;
                  dragStartOffset = details.localPosition - selectedPiece!.position;
                  isDragging = true;
                });
              }
            },
            onPanUpdate: (details) {
              if (selectedPiece != null && dragStartOffset != null) {
                setState(() {
                  final index = pieces.indexOf(selectedPiece!);

                  final newPosition = details.localPosition - dragStartOffset!;
                  pieces[index] = selectedPiece!.copyWith(
                    newPosition: newPosition,
                  );

                  selectedPiece = pieces[index];
                });
              }
            },
            onPanEnd: (details) {
              if (selectedPiece != null) {
                setState(() {
                  final index = pieces.indexOf(selectedPiece!);
                  final snappedPosition = grid.snapToGrid(selectedPiece!.position);

                  // Check if new position would cause collision
                  if (!_checkCollision(selectedPiece!, snappedPosition)) {
                    pieces[index] = selectedPiece!.copyWith(
                      newPosition: snappedPosition,
                    );
                  } else {
                    // Return piece to original position on collision
                    pieces[index] = selectedPiece!;
                  }

                  selectedPiece = null;
                  dragStartOffset = null;
                  isDragging = false;
                });
              }
            },
            onDoubleTapDown: (details) {
              final piece = _findPieceAtPosition(details.localPosition);
              if (piece != null) {
                setState(() {
                  final index = pieces.indexOf(piece);
                  final flippedPiece = piece.copyWith(
                    newIsFlipped: !piece.isFlipped,
                  );

                  // Check if flipping would cause a collision
                  if (!_checkCollision(flippedPiece, flippedPiece.position)) {
                    pieces[index] = flippedPiece;
                  }
                });
              }
            },
            child: Container(
              color: Colors.grey[200],
              width: double.infinity,
              height: double.infinity,
              child: CustomPaint(
                painter: PuzzleBoardPainter(
                  pieces: pieces,
                  grid: grid,
                  selectedPiece: selectedPiece,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                if (selectedPiece != null) {
                  _rotatePiece(selectedPiece!);
                }
              },
              backgroundColor: selectedPiece != null ? Colors.orange : Colors.grey,
              child: const Icon(Icons.rotate_right),
            ),
          ),
        ],
      ),
    );
  }
}

class PuzzleBoardPainter extends CustomPainter {
  final List<PuzzlePiece> pieces;
  final PuzzleGrid grid;
  final PuzzlePiece? selectedPiece;

  PuzzleBoardPainter({
    required this.pieces,
    required this.grid,
    this.selectedPiece,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas);

    for (var piece in pieces) {
      final paint = Paint()
        ..color = piece == selectedPiece ? piece.color.withOpacity(0.9) : piece.color
        ..style = PaintingStyle.fill;

      final transformedPath = piece.getTransformedPath();
      canvas.drawPath(transformedPath, paint);

      final borderPaint = Paint()
        ..color = piece == selectedPiece ? Colors.yellow : Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = piece == selectedPiece ? 3.0 : 2.0;
      canvas.drawPath(transformedPath, borderPaint);

      if (piece == selectedPiece) {
        final centerPaint = Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;

        canvas.drawCircle(piece.position + piece.centerPoint, 5.0, centerPaint);
      }
    }
  }

  void _drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // horizontal lines
    for (int i = 0; i <= grid.rows; i++) {
      final y = grid.origin.dy + i * grid.cellSize;
      canvas.drawLine(
        Offset(grid.origin.dx, y),
        Offset(grid.origin.dx + grid.columns * grid.cellSize, y),
        paint,
      );
    }

    // vertical lines
    for (int i = 0; i <= grid.columns; i++) {
      final x = grid.origin.dx + i * grid.cellSize;
      canvas.drawLine(
        Offset(x, grid.origin.dy),
        Offset(x, grid.origin.dy + grid.rows * grid.cellSize),
        paint,
      );
    }

    // game board borders
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(
        Rect.fromLTWH(grid.origin.dx, grid.origin.dy, grid.cellSize * grid.columns, grid.cellSize * grid.rows),
        borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
