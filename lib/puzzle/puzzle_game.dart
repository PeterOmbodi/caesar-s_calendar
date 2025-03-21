import 'dart:math' as math;

import 'package:caesar_puzzle/puzzle/puzzle_board_painter.dart';
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
  Offset? pieceStartPosition;
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
    final List<Color> pieceColors = [
      Colors.teal.withOpacity(0.8),
      Colors.indigo.withOpacity(0.8),
      Colors.brown.withOpacity(0.8),
      Colors.blueGrey.withOpacity(0.8),
      Colors.grey.withOpacity(0.8),
      Colors.deepPurple.withOpacity(0.8),
      Colors.blue.withOpacity(0.8),
      Colors.cyan.withOpacity(0.8),
    ];

    final double cellSize = grid.cellSize;

    // L shape 4-2
    final Path cornerLShape = Path()
      ..moveTo(0, 0)
      ..lineTo(cellSize, 0)
      ..lineTo(cellSize, cellSize)
      ..lineTo(4 * cellSize, cellSize)
      ..lineTo(4 * cellSize, 2 * cellSize)
      ..lineTo(0, 2 * cellSize)
      ..close();
    // square 3x2
    final Path squareShape = Path()
      ..moveTo(0, 0)
      ..lineTo(3 * cellSize, 0)
      ..lineTo(3 * cellSize, 2 * cellSize)
      ..lineTo(0, 2 * cellSize)
      ..close();

    // 7. Z shape 2-3-2
    final Path zShape = Path()
      ..moveTo(0, 0)
      ..lineTo(cellSize, 0)
      ..lineTo(cellSize, cellSize)
      ..lineTo(3 * cellSize, cellSize)
      ..lineTo(3 * cellSize, 3 * cellSize)
      ..lineTo(2 * cellSize, 3 * cellSize)
      ..lineTo(2 * cellSize, 2 * cellSize)
      ..lineTo(0, 2 * cellSize)
      ..close();

    pieces = [
      PuzzlePiece(
        path: cornerLShape,
        color: pieceColors[0],
        id: 'corner-l',
        position: Offset(50, 50),
        centerPoint: Offset(cellSize, cellSize),
      ),
      PuzzlePiece(
        path: squareShape,
        color: pieceColors[1],
        id: 'square',
        position: Offset(50, 200),
        centerPoint: Offset(cellSize, cellSize),
      ),
      PuzzlePiece(
        path: zShape,
        color: pieceColors[6],
        id: 'z-shape',
        position: Offset(350, 200),
        centerPoint: Offset(cellSize, cellSize),
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

        try {
          if (testPath.getBounds().overlaps(otherPath.getBounds())) {
            final combinedPath = Path.combine(PathOperation.intersect, testPath, otherPath);
            final bounds = combinedPath.getBounds();

            if (!bounds.isEmpty && bounds.width > 1 && bounds.height > 1) {
              debugPrint('Collision detected!');
              return true;
            }
          }
        } catch (e) {
          debugPrint('Checking collision exception: $e');
          return true;
        }
      }
    }
    if (!_isWithinGameBoard(testPiece)) {
      return true;
    }

    return false;
  }

  bool _isWithinGameBoard(PuzzlePiece piece) {
    final path = piece.getTransformedPath();
    final bounds = path.getBounds();

    final boardRect = Rect.fromLTWH(
      grid.origin.dx,
      grid.origin.dy,
      grid.cellSize * grid.columns,
      grid.cellSize * grid.rows,
    );

    return boardRect.contains(bounds.topLeft) &&
        boardRect.contains(bounds.topRight) &&
        boardRect.contains(bounds.bottomLeft) &&
        boardRect.contains(bounds.bottomRight);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caesars calendar'),
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
                  pieceStartPosition = selectedPiece!.position;
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
                final index = pieces.indexOf(selectedPiece!);
                final snappedPosition = grid.snapToGrid(selectedPiece!.position);

                // Check if new position would cause collision
                if (!_checkCollision(selectedPiece!, snappedPosition)) {
                  setState(() {
                    pieces[index] = selectedPiece!.copyWith(
                      newPosition: snappedPosition,
                    );
                    selectedPiece = null;
                    dragStartOffset = null;
                    pieceStartPosition = null;
                    isDragging = false;
                  });
                } else {
                  debugPrint('Collision detected, the piece will return to origin place');
                  setState(() {
                    pieces[index] = selectedPiece!.copyWith(
                      newPosition: pieceStartPosition!,
                    );
                    selectedPiece = null;
                    dragStartOffset = null;
                    pieceStartPosition = null;
                    isDragging = false;
                  });
                }
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

                  debugPrint('Flipping piece ${piece.id}: ${piece.isFlipped} -> ${flippedPiece.isFlipped}');

                  // Check if flipping would cause a collision
                  if (!_checkCollision(flippedPiece, flippedPiece.position)) {
                    pieces[index] = flippedPiece;
                    debugPrint('Flipped successfully');
                  } else {
                    debugPrint('Flipping would cause collision, aborting');
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
