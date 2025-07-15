import 'package:caesar_puzzle/domain/entities/puzzle_board.dart';

extension PuzzleBoardX on PuzzleBoard {
  double initialX(double cellSize) => origin.dx + cellSize / 4;

  double initialY(double cellSize) => origin.dy + cellSize;
}
