import 'package:caesar_puzzle/application/race/race_board.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/puzzle_board_painter.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_entity_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Needs the race [PuzzleBloc] above it.
class RaceBoardPreview extends StatelessWidget {
  const RaceBoardPreview({super.key, required this.board});

  final RaceBoard board;

  @override
  Widget build(final BuildContext context) {
    final state = context.watch<PuzzleBloc>().state;
    final grid = state.gridConfig.getBounds;
    if (grid.isEmpty) {
      return const SizedBox.shrink();
    }
    // The painter draws the board's border just outside the grid.
    final bounds = grid.inflate(2);
    final total = state.pieces.where((final p) => !p.isConfigItem).length;
    return FittedBox(
      child: SizedBox.fromSize(
        size: bounds.size,
        child: CustomPaint(
          painter: _ShiftedPainter(
            shift: bounds.topLeft,
            board: PuzzleBoardPainter(
              pieces: state.boardWith(board.pieces),
              grid: state.gridConfig,
              borderColorMode: false,
              selectedDate: state.selectedDate,
              isSolved: board.pieces.length == total,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShiftedPainter extends CustomPainter {
  const _ShiftedPainter({required this.shift, required this.board});

  final Offset shift;
  final PuzzleBoardPainter board;

  @override
  void paint(final Canvas canvas, final Size size) {
    canvas
      ..save()
      ..translate(-shift.dx, -shift.dy);
    board.paint(canvas, size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant final _ShiftedPainter oldDelegate) => true;
}
