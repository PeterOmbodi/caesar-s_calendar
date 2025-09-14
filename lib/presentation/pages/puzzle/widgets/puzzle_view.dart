import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/animated_pieces_overlay.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/puzzle_board_painter.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/puzzle_bloc.dart';

class PuzzleView extends StatelessWidget {
  const PuzzleView({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<PuzzleBloc, PuzzleState>(
    builder: (BuildContext context, PuzzleState state) => LayoutBuilder(
      builder: (context, constraints) {
        final bloc = context.read<PuzzleBloc>();
        bloc.add(PuzzleEvent.setViewSize(constraints.biggest));
        final borderColorMode = context.watch<SettingsCubit>().state.separateMoveColors;
        return state.status == GameStatus.initializing
            ? Center(child: CircularProgressIndicator())
            : GestureDetector(
                onTapDown: (details) => bloc.add(PuzzleEvent.onTapDown(details.localPosition)),
                onTapUp: (details) => bloc.add(PuzzleEvent.onTapUp(details.localPosition)),
                onPanStart: (details) => bloc.add(PuzzleEvent.onPanStart(details.localPosition)),
                onPanUpdate: (details) => bloc.add(PuzzleEvent.onPanUpdate(details.localPosition)),
                onPanEnd: (details) => bloc.add(PuzzleEvent.onPanEnd(details.localPosition)),
                onDoubleTapDown: (details) => bloc.add(PuzzleEvent.onDoubleTapDown(details.localPosition)),
                child: Container(
                  color: Theme.of(context).colorScheme.primary.withAlpha(18),
                  width: double.infinity,
                  height: double.infinity,
                  child: AnimatedPiecesOverlay(
                    pieces: state.pieces,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    borderColorMode: borderColorMode,
                    selectedPiece: state.selectedPiece,
                    childBuilder: (hiddenIds) => CustomPaint(
                      painter: PuzzleBoardPainter(
                        pieces: state.pieces.where((p) => !hiddenIds.contains(p.id) || p.isForbidden),
                        grid: state.gridConfig,
                        board: state.boardConfig,
                        selectedPiece: state.selectedPiece,
                        previewPosition: state.previewPosition,
                        showPreview: state.showPreview,
                        previewCollision: state.previewCollision,
                        borderColorMode: borderColorMode,
                      ),
                    ),
                  ),
                ),
              );
      },
    ),
  );
}
