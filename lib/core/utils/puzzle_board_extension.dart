import 'package:caesar_puzzle/domain/entities/puzzle_board_entity.dart';

import '../../presentation/pages/puzzle/bloc/puzzle_bloc.dart';

extension PuzzleBoardX on PuzzleBoardEntity {
  double initialX(final double cellSize) => origin.dx + cellSize / 4 - PuzzleBloc.boardExtraX * 2;

  double initialY(final double cellSize) => origin.dy + cellSize / 4;
}
