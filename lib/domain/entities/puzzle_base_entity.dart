import 'package:caesar_puzzle/core/models/position.dart';

abstract class PuzzleBaseEntity {
  const PuzzleBaseEntity({required this.cellSize, required this.rows, required this.columns, required this.origin});

  final double cellSize;
  final int rows;
  final int columns;
  final Position origin;

  Position get topLeft => origin;
}
