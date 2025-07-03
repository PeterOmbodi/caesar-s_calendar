part of 'puzzle_bloc.dart';

enum PieceZone { grid, board }

enum GameStatus {
  waiting,
  playing,
  solving,
  solved,
}

@freezed
abstract class PuzzleState with _$PuzzleState {
  factory PuzzleState.initial(final Size screenSize) {
    double calcCellSize(final Size screenSize) {
      final floored = (screenSize.width / 8).floor();
      return floored.isEven ? floored.toDouble() : floored - 1.0;
    }

    final cellSize = screenSize.width < 450 ? calcCellSize(screenSize) : 50.0;
    final gridLeftPadding = screenSize.width < 450 ? (screenSize.width - cellSize * 7) / 2 : 24.0;

    final gridConfig = PuzzleGrid(
      cellSize: cellSize,
      rows: 7,
      columns: 7,
      origin: Offset(gridLeftPadding, 16),
    );

    final boardConfig = PuzzleBoard(
      cellSize: cellSize + gridLeftPadding / 7,
      rows: 7,
      columns: 7,
      origin: Offset(gridLeftPadding / 2, gridConfig.origin.dy + gridConfig.cellSize * gridConfig.rows + 16),
    );

    final List<Color> pieceColors = [
      Colors.teal.withValues(alpha: 0.8),
      Colors.indigo.withValues(alpha: 0.8),
      Colors.brown.withValues(alpha: 0.8),
      Colors.blueGrey.withValues(alpha: 0.8),
      Colors.grey.withValues(alpha: 0.8),
      Colors.deepPurple.withValues(alpha: 0.8),
      Colors.blue.withValues(alpha: 0.8),
      Colors.cyan.withValues(alpha: 0.8),
    ];

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
      ..lineTo(2 * cellSize, 0)
      ..lineTo(2 * cellSize, 3 * cellSize)
      ..lineTo(0, 3 * cellSize)
      ..close();

    // square 3x2 with gap, P-shape
    final Path pShape = Path()
      ..moveTo(0, 0)
      ..lineTo(3 * cellSize, 0)
      ..lineTo(3 * cellSize, cellSize)
      ..lineTo(2 * cellSize, cellSize)
      ..lineTo(2 * cellSize, 2 * cellSize)
      ..lineTo(0, 2 * cellSize)
      ..lineTo(0, 0)
      ..close();

    // Z shape 2-3-2
    final Path zShape = Path()
      ..moveTo(0, cellSize)
      ..lineTo(2 * cellSize, cellSize)
      ..lineTo(2 * cellSize, 0)
      ..lineTo(3 * cellSize, 0)
      ..lineTo(3 * cellSize, 2 * cellSize)
      ..lineTo(cellSize, 2 * cellSize)
      ..lineTo(cellSize, 3 * cellSize)
      ..lineTo(0, 3 * cellSize)
      ..lineTo(0, cellSize)
      ..close();

    // Y shape
    final Path yShape = Path()
      ..moveTo(0, 0)
      ..lineTo(4 * cellSize, 0)
      ..lineTo(4 * cellSize, cellSize)
      ..lineTo(3 * cellSize, cellSize)
      ..lineTo(3 * cellSize, 2 * cellSize)
      ..lineTo(2 * cellSize, 2 * cellSize)
      ..lineTo(2 * cellSize, cellSize)
      ..lineTo(0, cellSize)
      ..lineTo(0, 0)
      ..close();

    // Lighting, N-Shape
    final Path nShape = Path()
      ..moveTo(0, cellSize)
      ..lineTo(cellSize, cellSize)
      ..lineTo(cellSize, 0)
      ..lineTo(4 * cellSize, 0)
      ..lineTo(4 * cellSize, cellSize)
      ..lineTo(2 * cellSize, cellSize)
      ..lineTo(2 * cellSize, 2 * cellSize)
      ..lineTo(0, 2 * cellSize)
      ..lineTo(0, cellSize)
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

    /// initial placement for shapes on board
    const extraX = 1.5;
    final initialX = boardConfig.origin.dx + cellSize / 4;
    final initialY = boardConfig.origin.dy + cellSize / 1.5;
    final cellXOffset = cellSize + extraX;

    final boardPieces = [
      PuzzlePiece(
        path: cornerLShape,
        color: pieceColors[0],
        id: 'L-Shape',
        position: Offset(initialX, initialY + cellSize * 4),
        centerPoint: Offset(cellSize, cellSize),
      ),
      PuzzlePiece(
        path: squareShape,
        color: pieceColors[1],
        id: 'Square',
        position: Offset(initialX + cellXOffset * 5 + extraX, initialY + cellSize * 2),
        centerPoint: Offset(cellSize, cellSize),
      ),
      PuzzlePiece(
        path: zShape,
        color: pieceColors[2],
        id: 'Z-Shape',
        position: Offset(initialX + cellXOffset * 4, initialY),
        centerPoint: Offset(cellSize, cellSize),
      ),
      PuzzlePiece(
        path: yShape,
        color: pieceColors[3],
        id: 'Y-Shape',
        position: Offset(initialX + 3, initialY + cellSize * 2),
        centerPoint: Offset(cellSize, cellSize),
      ),
      PuzzlePiece(
        path: uShape,
        color: pieceColors[4],
        id: 'U-Shape',
        position: Offset(initialX + cellXOffset+ extraX, initialY + cellSize * 3),
        centerPoint: Offset(cellSize, cellSize),
      ),
      PuzzlePiece(
        path: pShape,
        color: pieceColors[5],
        id: 'P-Shape',
        position: Offset(initialX, initialY),
        centerPoint: Offset(cellSize, cellSize),
      ),
      PuzzlePiece(
        path: nShape,
        color: pieceColors[6],
        id: 'N-Shape',
        position: Offset(initialX + 2 * cellXOffset, initialY),
        centerPoint: Offset(cellSize, cellSize),
      ),
      PuzzlePiece(
        path: vShape,
        color: pieceColors[7],
        id: 'V-Shape',
        position: Offset(initialX + cellXOffset * 4, initialY + cellSize * 3),
        centerPoint: Offset(cellSize, cellSize),
      ),
    ];

    final gridPieces = [
      PuzzlePiece(
        path: zone1,
        color: Colors.grey.shade300,
        id: 'zone1',
        position: Offset(gridConfig.origin.dx + cellSize * 6, gridConfig.origin.dy),
        centerPoint: Offset(cellSize, cellSize),
        borderRadius: 0,
        isDraggable: false,
      ),
      PuzzlePiece(
        path: zone2,
        color: Colors.grey.shade300,
        id: 'zone2',
        position: Offset(gridConfig.origin.dx + cellSize * 3, gridConfig.origin.dy + cellSize * 6),
        centerPoint: Offset(cellSize, cellSize),
        borderRadius: 0,
        isDraggable: false,
      ),
    ];
    return PuzzleState(
      status: GameStatus.waiting,
      gridConfig: gridConfig,
      boardConfig: boardConfig,
      pieces: {
        PieceZone.grid: gridPieces,
        PieceZone.board: boardPieces,
      },
      solutions: [],
      hints: 0,
      timer: 0,
      selectedPiece: null,
      isDragging: false,
      isSolving: false,
      showPreview: false,
      previewCollision: false,
    );
  }

  factory PuzzleState({
    required GameStatus status,
    required PuzzleGrid gridConfig,
    required PuzzleBoard boardConfig,
    required List<List<String>> solutions,
    required int hints,
    required int timer,
    required Map<PieceZone, List<PuzzlePiece>> pieces,
    required PuzzlePiece? selectedPiece,
    required bool isDragging,
    Offset? dragStartOffset,
    Offset? pieceStartPosition,
    Offset? previewPosition,
    PieceZone? dropZone,
    required bool isSolving,
    required bool showPreview,
    required bool previewCollision,
  }) = _PuzzleState;
}
