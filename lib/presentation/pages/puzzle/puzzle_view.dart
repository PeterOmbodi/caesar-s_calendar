import 'package:caesar_puzzle/presentation/widgets/puzzle_board_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/puzzle_bloc.dart';

class PuzzleView extends StatelessWidget {
  const PuzzleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caesars calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<PuzzleBloc>().add(PuzzleEvent.reset()),
          ),
        ],
      ),
      body: BlocBuilder<PuzzleBloc, PuzzleState>(
        builder: (context, state) {
          final bloc = context.read<PuzzleBloc>();
          return Stack(
            children: [
              GestureDetector(
                onTapDown: (details) => bloc.add(PuzzleEvent.onTapDown(details.localPosition)),
                onTapUp: (details) => bloc.add(PuzzleEvent.onTapUp(details.localPosition)),
                onPanStart: (details) => bloc.add(PuzzleEvent.onPanStart(details.localPosition)),
                onPanUpdate: (details) => bloc.add(PuzzleEvent.onPanUpdate(details.localPosition)),
                onPanEnd: (details) => bloc.add(PuzzleEvent.onPanEnd(details.localPosition)),
                onDoubleTapDown: (details) => bloc.add(PuzzleEvent.onDoubleTapDown(details.localPosition)),
                child: Container(
                  color: Colors.grey[200],
                  width: double.infinity,
                  height: double.infinity,
                  child: CustomPaint(
                    painter: PuzzleBoardPainter(
                      pieces: [
                        ...state.pieces[PieceZone.grid]!,
                        ...state.pieces[PieceZone.board]!,
                      ],
                      grid: state.gridConfig,
                      board: state.boardConfig,
                      selectedPiece: state.selectedPiece,
                      previewPosition: state.previewPosition,
                      showPreview: state.showPreview,
                      previewCollision: state.previewCollision,
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
                    state.isSolving
                        ? CircularProgressIndicator()
                        : FloatingActionButton(
                            onPressed: () => bloc.add(PuzzleEvent.solve()),
                            backgroundColor: state.selectedPiece != null ? Colors.orange : Colors.grey,
                            child: const Icon(Icons.lightbulb),
                          ),
                    const SizedBox(height: 20),
                    // FloatingActionButton(
                    //   onPressed: () {
                    //     if (state.selectedPiece != null) {
                    //       bloc.add(PuzzleEvent.rotatePiece(state.selectedPiece!));
                    //     }
                    //   },
                    //   backgroundColor: state.selectedPiece != null ? Colors.orange : Colors.grey,
                    //   child: const Icon(Icons.rotate_right),
                    // ),
                    // const SizedBox(height: 10),
                    // FloatingActionButton(
                    //   onPressed: () {
                    //     if (state.selectedPiece != null) {
                    //       bloc.add(PuzzleEvent.onDoubleTapDown(state.selectedPiece!.position));
                    //     }
                    //   },
                    //   backgroundColor: state.selectedPiece != null ? Colors.blue : Colors.grey,
                    //   child: const Icon(Icons.flip),
                    // ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
