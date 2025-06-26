import 'dart:math' as math;

import 'package:caesar_puzzle/application/solve_puzzle_use_case.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_board.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_piece.dart';
import 'package:caesar_puzzle/presentation/widgets/puzzle_board_painter.dart';
import 'package:flutter/material.dart';

class PuzzleGame extends StatefulWidget {
  const PuzzleGame({super.key, required this.screenSize});

  final Size screenSize;

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
  bool isSolving = false;
  String? dropZone;
  Offset? previewPosition;
  bool showPreview = false;
  bool previewCollision = false;

  @override
  void initState() {
    super.initState();
    final cellSize = widget.screenSize.width < 450 ? _calcCellSize() : 50.0;
    grid = PuzzleGrid(
      cellSize: cellSize,
      rows: 7,
      columns: 7,
      origin: Offset((widget.screenSize.width - cellSize * 7) / 2, 50),
    );

    board = PuzzleBoard(
      cellSize: cellSize,
      rows: 8,
      columns: 9,
      origin: Offset(5, cellSize * 9),
    );

    _initializePieces();
  }

  double _calcCellSize() {
    final floored = (widget.screenSize.width / 8).floor();
    return floored.isEven ? floored.toDouble() : floored - 1.0;
  }

  void _initializePieces() {
    isSolving = false;
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

    // U shape
    final Path uShape = Path()
      ..moveTo(0, 0)
      ..lineTo(cellSize, 0)
      ..lineTo(cellSize, cellSize)
      ..lineTo(2 * cellSize, cellSize)
      ..lineTo(2 * cellSize, 0)
      ..lineTo(3 * cellSize, 0)
      ..lineTo(3 * cellSize, 2 * cellSize)
      ..lineTo(0, 2 * cellSize)
      ..close();

    // square 3x2
    final Path squareShape = Path()
      ..moveTo(0, 0)
      ..lineTo(3 * cellSize, 0)
      ..lineTo(3 * cellSize, 2 * cellSize)
      ..lineTo(0, 2 * cellSize)
      ..close();

    // square 3x2 with gap, P-shape
    final Path pShape = Path()
      ..moveTo(0, 0)
      ..lineTo(3 * cellSize, 0)
      ..lineTo(3 * cellSize, 2 * cellSize)
      ..lineTo(cellSize, 2 * cellSize)
      ..lineTo(cellSize, cellSize)
      ..lineTo(0, 1 * cellSize)
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

    // Y shape
    final Path yShape = Path()
      ..moveTo(cellSize, 0)
      ..lineTo(2 * cellSize, 0)
      ..lineTo(2 * cellSize, 1 * cellSize)
      ..lineTo(4 * cellSize, 1 * cellSize)
      ..lineTo(4 * cellSize, 2 * cellSize)
      ..lineTo(0, 2 * cellSize)
      ..lineTo(0, 1 * cellSize)
      ..lineTo(cellSize, 1 * cellSize)
      ..close();

    // Lighting, N-Shape
    final Path nShape = Path()
      ..moveTo(0, 0)
      ..lineTo(cellSize, 0)
      ..lineTo(cellSize, 1 * cellSize)
      ..lineTo(2 * cellSize, 1 * cellSize)
      ..lineTo(2 * cellSize, 4 * cellSize)
      ..lineTo(1 * cellSize, 4 * cellSize)
      ..lineTo(1 * cellSize, 2 * cellSize)
      ..lineTo(0 * cellSize, 2 * cellSize)
      ..close();
    // Corner, V-Shape
    final Path vShape = Path()
      ..moveTo(0, 0)
      ..lineTo(cellSize, 0)
      ..lineTo(cellSize, 2 * cellSize)
      ..lineTo(3 * cellSize, 2 * cellSize)
      ..lineTo(3 * cellSize, 3 * cellSize)
      ..lineTo(0, 3 * cellSize)
      ..close();

    // zone1
    final Path zone1 = Path()
      ..moveTo(0, 0)
      ..lineTo(1 * cellSize, 0)
      ..lineTo(1 * cellSize, 2 * cellSize)
      ..lineTo(0, 2 * cellSize)
      ..close();

    final Path zone2 = Path()
      ..moveTo(0, 0)
      ..lineTo(4 * cellSize, 0)
      ..lineTo(4 * cellSize, 1 * cellSize)
      ..lineTo(0, 1 * cellSize)
      ..close();

    boardPieces = [
      PuzzlePiece(
        path: cornerLShape,
        color: pieceColors[0],
        id: 'L-Shape',
        position: Offset(board.origin.dx + 5, board.origin.dy + 30),
        centerPoint: Offset(cellSize, cellSize),
      ),
      PuzzlePiece(
        path: squareShape,
        color: pieceColors[1],
        id: 'Square',
        position: Offset(board.origin.dx + 5, board.origin.dy + 130),
        centerPoint: Offset(cellSize, cellSize),
      ),
      PuzzlePiece(
        path: zShape,
        color: pieceColors[2],
        id: 'Z-Shape',
        position: Offset(board.origin.dx + 5, board.origin.dy + 200),
        centerPoint: Offset(cellSize, cellSize),
      ),
      PuzzlePiece(
        path: yShape,
        color: pieceColors[3],
        id: 'Y-Shape',
        position: Offset(board.origin.dx + 165, board.origin.dy + 230),
        centerPoint: Offset(cellSize, cellSize),
      ),
      PuzzlePiece(
        path: uShape,
        color: pieceColors[4],
        id: 'U-Shape',
        position: Offset(board.origin.dx + 165, board.origin.dy + 130),
        centerPoint: Offset(cellSize, cellSize),
      ),
      PuzzlePiece(
        path: pShape,
        color: pieceColors[5],
        id: 'P-Shape',
        position: Offset(board.origin.dx + 165, board.origin.dy + 20),
        centerPoint: Offset(cellSize, cellSize),
      ),
      PuzzlePiece(
        path: nShape,
        color: pieceColors[6],
        id: 'N-Shape',
        position: Offset(board.origin.dx + 305, board.origin.dy + 20),
        centerPoint: Offset(cellSize, cellSize),
      ),
      PuzzlePiece(
        path: vShape,
        color: pieceColors[7],
        id: 'V-Shape',
        position: Offset(board.origin.dx + 325, board.origin.dy + 180),
        centerPoint: Offset(cellSize, cellSize),
      ),
    ];

    gridPieces = [
      PuzzlePiece(
        path: zone1,
        color: Colors.grey.shade300,
        id: 'zone1',
        position: Offset(grid.origin.dx + cellSize * 6, grid.origin.dy),
        centerPoint: Offset(cellSize, cellSize),
        borderRadius: 0,
        isDraggable: false,
      ),
      PuzzlePiece(
        path: zone2,
        color: Colors.grey.shade300,
        id: 'zone2',
        position: Offset(grid.origin.dx + cellSize * 3, grid.origin.dy + cellSize * 6),
        centerPoint: Offset(cellSize, cellSize),
        borderRadius: 0,
        isDraggable: false,
      ),
    ];

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
      final index = pieces.indexWhere((item) => item.id == piece.id);
      if (index != -1) {
        final newRotation = (piece.rotation + math.pi / 2) % (math.pi * 2);

        debugPrint('newRotation: $newRotation');

        pieces[index] = piece.copyWith(newRotation: newRotation);

        _updatePieceInLists(piece, pieces[index]);
        selectedPiece = pieces[index];
      }
    });
  }

  void _updatePieceInLists(PuzzlePiece oldPiece, PuzzlePiece newPiece) {
    final boardIndex = boardPieces.indexWhere((item) => item.id == oldPiece.id);
    if (boardIndex != -1) {
      boardPieces[boardIndex] = newPiece;
    }

    final gridIndex = gridPieces.indexWhere((item) => item.id == oldPiece.id);
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
          debugPrint(
              'Collision detected between ${piece.id} and ${otherPiece.id}, intersectionBounds: ${intersectionBounds.size}');
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

  Future<void> _solvePuzzle() async {
    setState(() {
      isSolving = true;
    });

    SolvePuzzleUseCase(pieces, grid).call().then((solution) {
      debugPrint('solving finished, solutions: ${solution.length}');
      isSolving = false;
      if (solution.isNotEmpty) {
        loadSolution(solution);
      }
    });
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
              if (piece != null && piece.isDraggable) {
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
                  final index = pieces.indexWhere((item) => item.id == selectedPiece!.id);
                  final newPosition = details.localPosition - dragStartOffset!;
                  pieces[index] = selectedPiece!.copyWith(
                    newPosition: newPosition,
                  );
                  selectedPiece = pieces[index];

                  final boardIndex = boardPieces.indexWhere((item) => item.id == selectedPiece!.id);
                  if (boardIndex >= 0) {
                    boardPieces[boardIndex] = selectedPiece!;
                  } else {
                    final gridIndex = gridPieces.indexWhere((item) => item.id == selectedPiece!.id);
                    if (gridIndex >= 0) {
                      gridPieces[gridIndex] = selectedPiece!;
                    }
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
                final index = pieces.indexWhere((item) => item.id == selectedPiece!.id);
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
                // debugPrint('snappedPosition, x: ${snappedPosition.dx}, y: ${snappedPosition.dy}');
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
                  final index = pieces.indexWhere((item) => item.id == piece.id);
                  final flippedPiece = piece.copyWith(
                    newIsFlipped: !piece.isFlipped,
                  );

                  debugPrint('Flipping piece ${piece.id}: ${piece.isFlipped} -> ${flippedPiece.isFlipped}');

                  // final zone = _getZoneAtPosition(piece.position);

                  //if (!_checkCollision(flippedPiece, flippedPiece.position, zone: zone)) {
                  pieces[index] = flippedPiece;
                  _updatePieceInLists(piece, flippedPiece);
                  debugPrint('Flipped successfully');
                  // } else {
                  //   debugPrint('Flipping would cause collision, aborting');
                  // }
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
                isSolving
                    ? CircularProgressIndicator()
                    : FloatingActionButton(
                        onPressed: () => _solvePuzzle(),
                        backgroundColor: selectedPiece != null ? Colors.orange : Colors.grey,
                        child: const Icon(Icons.lightbulb),
                      ),
                const SizedBox(height: 20),
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
                        final index = pieces.indexWhere((item) => item.id == selectedPiece!.id);
                        final flippedPiece = selectedPiece!.copyWith(
                          newIsFlipped: !selectedPiece!.isFlipped,
                        );

                        // final zone = _getZoneAtPosition(selectedPiece!.position);

                        //if (!_checkCollision(flippedPiece, flippedPiece.position, zone: zone)) {
                        pieces[index] = flippedPiece;

                        _updatePieceInLists(selectedPiece!, flippedPiece);

                        selectedPiece = flippedPiece;
                        //}
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

  void loadSolution(List<String> solutionIds) {
    setState(() {
      for (var id in solutionIds) {
        final params = _parsePlacementId(id);
        if (params == null) continue;
        final idx = pieces.indexWhere((p) => p.id == params.pieceId);
        pieces[idx] = _placePiece(pieces[idx], params);
      }
    });
  }

  PuzzlePiece _placePiece(PuzzlePiece piece, _PlacementParams params) {
    final dx = params.col * grid.cellSize;
    final dy = params.row * grid.cellSize;
    final targetOffset = Offset(grid.origin.dx + dx, grid.origin.dy + dy);

    final updatedPiece = piece.copyWith(
      newIsFlipped: params.isFlipped,
      newPosition: targetOffset,
      newRotation: params.rotationSteps * math.pi / 2,
    );
    return updatedPiece;
  }
}

class _PlacementParams {
  final String pieceId;
  final int row, col, rotationSteps;
  final bool isFlipped;

  _PlacementParams(this.pieceId, this.row, this.col, this.rotationSteps, this.isFlipped);
}

_PlacementParams? _parsePlacementId(String id) {
  final match = RegExp(r'^(.+)_r(\d+)_c(\d+)_rot(\d+)(_F)?$').firstMatch(id);
  if (match == null) return null;

  final pieceId = match.group(1)!;
  final row = int.parse(match.group(2)!);
  final col = int.parse(match.group(3)!);
  final rotSteps = int.parse(match.group(4)!);
  final flipped = match.group(5) != null;

  return _PlacementParams(pieceId, row, col, rotSteps, flipped);
}
