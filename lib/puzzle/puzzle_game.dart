import 'dart:math' as math;

import 'package:caesar_puzzle/puzzle/puzzle_board.dart';
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
  List<PuzzlePiece> boardPieces = [];
  List<PuzzlePiece> gridPieces = [];
  PuzzlePiece? selectedPiece;
  Offset? dragStartOffset;
  Offset? pieceStartPosition;
  late PuzzleGrid grid;
  late PuzzleBoard board;
  bool isDragging = false;
  String? dropZone;
  Offset? previewPosition;
  bool showPreview = false;
  bool previewCollision = false;

  @override
  void initState() {
    super.initState();
    grid = PuzzleGrid(
      cellSize: 50,
      rows: 7,
      columns: 7,
      origin: const Offset(50, 50),
    );

    board = PuzzleBoard(
      cellSize: 50,
      rows: 8,
      columns: 8,
      origin: const Offset(50, 450),
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

    // Z shape 2-3-2
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

    // T shape
    final Path tShape = Path()
      ..moveTo(cellSize, 0)
      ..lineTo(2 * cellSize, 0)
      ..lineTo(2 * cellSize, 2 * cellSize)
      ..lineTo(3 * cellSize, 2 * cellSize)
      ..lineTo(3 * cellSize, 3 * cellSize)
      ..lineTo(0, 3 * cellSize)
      ..lineTo(0, 2 * cellSize)
      ..lineTo(cellSize, 2 * cellSize)
      ..close();

    boardPieces = [
      PuzzlePiece(
        path: cornerLShape,
        color: pieceColors[0],
        id: 'corner-l',
        position: Offset(board.origin.dx + 20, board.origin.dy + 30),
        centerPoint: Offset(cellSize, cellSize),
      ),
      PuzzlePiece(
        path: squareShape,
        color: pieceColors[1],
        id: 'square',
        position: Offset(board.origin.dx + 20, board.origin.dy + 130),
        centerPoint: Offset(cellSize, cellSize),
      ),
      PuzzlePiece(
        path: zShape,
        color: pieceColors[2],
        id: 'z-shape',
        position: Offset(board.origin.dx + 20, board.origin.dy + 230),
        centerPoint: Offset(cellSize, cellSize),
      ),
      PuzzlePiece(
        path: tShape,
        color: pieceColors[3],
        id: 't-shape',
        position: Offset(board.origin.dx + 150, board.origin.dy + 30),
        centerPoint: Offset(cellSize, cellSize),
      ),
    ];

    gridPieces = [];

    pieces = [
      ...boardPieces,
      ...gridPieces,
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

        _updatePieceInLists(piece, pieces[index]);
        selectedPiece = pieces[index];
      }
    });
  }

  void _updatePieceInLists(PuzzlePiece oldPiece, PuzzlePiece newPiece) {
    debugPrint('_updatePieceInLists, oldPiece: ${oldPiece.position}, newPiece: ${newPiece.position}, gridPieces: ${gridPieces.length}');
    final boardIndex = boardPieces.indexOf(oldPiece);
    if (boardIndex != -1) {
      boardPieces[boardIndex] = newPiece;
    }

    final gridIndex = gridPieces.indexOf(oldPiece);
    if (gridIndex != -1) {
      gridPieces[gridIndex] = newPiece;
    }
  }

  bool _checkCollision(PuzzlePiece piece, Offset newPosition, {String? zone}) {
    final testPiece = piece.copyWith(newPosition: newPosition);
    final testPath = testPiece.getTransformedPath();
    final testBounds = testPath.getBounds();

    List<PuzzlePiece> piecesToCheck = [];
    if (zone == 'grid') {
      piecesToCheck = gridPieces;
    } else if (zone == 'board') {
      piecesToCheck = boardPieces;
    } else {
      piecesToCheck = pieces;
    }

    piecesToCheck = piecesToCheck.where((p) => p.id != piece.id).toList();

    for (var otherPiece in piecesToCheck) {
      final otherPath = otherPiece.getTransformedPath();
      final otherBounds = otherPath.getBounds();

      if (!testBounds.overlaps(otherBounds)) {
        continue;
      }

      try {
        // Add some tolerance to avoid false positives
        // For grid-based placements, we want to allow pieces to be adjacent
        final combinedPath = Path.combine(PathOperation.intersect, testPath, otherPath);
        final intersectionBounds = combinedPath.getBounds();

        // If the intersection area is significant, it's a collision
        if (!intersectionBounds.isEmpty && intersectionBounds.width > 2 && intersectionBounds.height > 2) {
          debugPrint('Collision detected between ${piece.id} and ${otherPiece.id}, intersectionBounds: ${intersectionBounds.size}');
          debugPrint('Collision detected, otherPath: ${otherPath.getBounds()}, testPath: ${testPath.getBounds()}');

          return true;
        }
      } catch (e) {
        debugPrint('Checking collision exception: $e');
        return true;
      }
    }

    if (zone == 'grid') {
      final gridRect = grid.getBounds();

      // For grid, ensure the piece is mostly inside the grid
      // This is less strict than requiring all corners to be inside
      final centerX = testBounds.left + testBounds.width / 2;
      final centerY = testBounds.top + testBounds.height / 2;
      final pieceCenter = Offset(centerX, centerY);

      if (!gridRect.contains(pieceCenter)) {
        debugPrint('Piece center outside grid');
        return true;
      }

      // Allow some tolerance for pieces at edges
      final expandedGrid = Rect.fromLTRB(gridRect.left - 5, gridRect.top - 5, gridRect.right + 5, gridRect.bottom + 5);

      if (testBounds.left < expandedGrid.left ||
          testBounds.right > expandedGrid.right ||
          testBounds.top < expandedGrid.top ||
          testBounds.bottom > expandedGrid.bottom) {
        debugPrint('Piece partially outside grid');
        return true;
      }
    } else if (zone == 'board') {
      final boardRect = board.getBounds();

      // For board, just make sure the piece overlaps with the board area
      if (!boardRect.overlaps(testBounds)) {
        debugPrint('Piece not overlapping with board');
        return true;
      }
    }

    return false;
  }

  String? _getZoneAtPosition(Offset position) {
    if (grid.getBounds().contains(position)) {
      return 'grid';
    } else if (board.getBounds().contains(position)) {
      return 'board';
    }
    return null;
  }

  void _movePieceBetweenZones(PuzzlePiece piece, String newZone) {
    boardPieces.removeWhere((p) => p.id == piece.id);
    gridPieces.removeWhere((p) => p.id == piece.id);

    if (newZone == 'grid') {
      gridPieces.add(piece);
    } else if (newZone == 'board') {
      boardPieces.add(piece);
    }

    debugPrint('Board pieces: ${boardPieces.map((p) => p.id).join(', ')}');
    debugPrint('Grid pieces: ${gridPieces.map((p) => p.id).join(', ')}');
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
                  pieces.remove(piece);
                  pieces.add(piece);

                  selectedPiece = pieces.last;
                  dragStartOffset = details.localPosition - selectedPiece!.position;
                  pieceStartPosition = selectedPiece!.position;
                  dropZone = _getZoneAtPosition(selectedPiece!.position);
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

                  if (boardPieces.contains(selectedPiece!)) {
                    final boardIndex = boardPieces.indexOf(selectedPiece!);
                    boardPieces[boardIndex] = selectedPiece!;
                  } else if (gridPieces.contains(selectedPiece!)) {
                    final gridIndex = gridPieces.indexOf(selectedPiece!);
                    gridPieces[gridIndex] = selectedPiece!;
                  }
                  String? currentZone = _getZoneAtPosition(newPosition);
                  if (currentZone == 'grid') {
                    previewPosition = grid.snapToGrid(newPosition);
                    showPreview = true;

                    // Check for collision with the preview position
                    bool hasCollision = _checkCollision(selectedPiece!, previewPosition!, zone: 'grid');
                    previewCollision = hasCollision; // Store collision status
                  } else {
                    showPreview = false;
                    previewCollision = false;
                  }
                });
              }
            },
            onPanEnd: (details) {
              if (selectedPiece != null) {
                showPreview = false;
                previewPosition = null;
                final index = pieces.indexOf(selectedPiece!);

                final newZone = _getZoneAtPosition(selectedPiece!.position);
                Offset snappedPosition;
                bool collisionDetected = false;

                if (newZone == 'grid') {
                  snappedPosition = grid.snapToGrid(selectedPiece!.position);
                  collisionDetected = _checkCollision(selectedPiece!, snappedPosition, zone: 'grid');
                } else if (newZone == 'board') {
                  snappedPosition = selectedPiece!.position;
                  final boardBounds = board.getBounds();
                  final pieceBounds = selectedPiece!.getTransformedPath().getBounds();

                  if (pieceBounds.left < boardBounds.left) {
                    snappedPosition =
                        Offset(snappedPosition.dx + (boardBounds.left - pieceBounds.left), snappedPosition.dy);
                  }
                  if (pieceBounds.right > boardBounds.right) {
                    snappedPosition =
                        Offset(snappedPosition.dx - (pieceBounds.right - boardBounds.right), snappedPosition.dy);
                  }
                  if (pieceBounds.top < boardBounds.top) {
                    snappedPosition =
                        Offset(snappedPosition.dx, snappedPosition.dy + (boardBounds.top - pieceBounds.top));
                  }
                  if (pieceBounds.bottom > boardBounds.bottom) {
                    snappedPosition =
                        Offset(snappedPosition.dx, snappedPosition.dy - (pieceBounds.bottom - boardBounds.bottom));
                  }

                  collisionDetected = false;
                } else {
                  snappedPosition = pieceStartPosition!;
                  collisionDetected = true;
                  debugPrint('not over either zone, return to starting position');
                }
                debugPrint('snappedPosition, snappedPosition: ${snappedPosition}');
                if (!collisionDetected) {
                  setState(() {
                    pieces[index] = selectedPiece!.copyWith(
                      newPosition: snappedPosition,
                    );
                    selectedPiece = pieces[index];

                    if (newZone != null && newZone != dropZone) {
                      _movePieceBetweenZones(selectedPiece!, newZone);
                    }

                    _updatePieceInLists(selectedPiece!, selectedPiece!);

                    selectedPiece = null;
                    dragStartOffset = null;
                    pieceStartPosition = null;
                    dropZone = null;
                    isDragging = false;
                  });
                } else {
                  debugPrint('Collision detected, returning to original position');
                  setState(() {
                    pieces[index] = selectedPiece!.copyWith(
                      newPosition: pieceStartPosition!,
                    );

                    _updatePieceInLists(selectedPiece!, pieces[index]);

                    selectedPiece = null;
                    dragStartOffset = null;
                    pieceStartPosition = null;
                    dropZone = null;
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

                  final zone = _getZoneAtPosition(piece.position);

                  if (!_checkCollision(flippedPiece, flippedPiece.position, zone: zone)) {
                    pieces[index] = flippedPiece;
                    _updatePieceInLists(piece, flippedPiece);
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
                  board: board,
                  selectedPiece: selectedPiece,
                  previewPosition: previewPosition,
                  showPreview: showPreview,
                  previewCollision: previewCollision,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  onPressed: () {
                    if (selectedPiece != null) {
                      _rotatePiece(selectedPiece!);
                    }
                  },
                  backgroundColor: selectedPiece != null ? Colors.orange : Colors.grey,
                  child: const Icon(Icons.rotate_right),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: () {
                    if (selectedPiece != null) {
                      setState(() {
                        final index = pieces.indexOf(selectedPiece!);
                        final flippedPiece = selectedPiece!.copyWith(
                          newIsFlipped: !selectedPiece!.isFlipped,
                        );

                        final zone = _getZoneAtPosition(selectedPiece!.position);

                        if (!_checkCollision(flippedPiece, flippedPiece.position, zone: zone)) {
                          pieces[index] = flippedPiece;

                          _updatePieceInLists(selectedPiece!, flippedPiece);

                          selectedPiece = flippedPiece;
                        }
                      });
                    }
                  },
                  backgroundColor: selectedPiece != null ? Colors.blue : Colors.grey,
                  child: const Icon(Icons.flip),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
