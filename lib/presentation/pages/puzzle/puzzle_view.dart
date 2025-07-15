import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/widgets/puzzle_board_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import 'bloc/puzzle_bloc.dart';

class PuzzleView extends StatelessWidget {
  const PuzzleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).calendarTitle),
        actions: [
          IconButton(
            icon: BlocBuilder<PuzzleBloc, PuzzleState>(
                builder: (context, state) =>
                    Icon(state.isUnlockedForbiddenCells ? Icons.lock_open_outlined : Icons.lock_outlined)),
            onPressed: () => context.read<PuzzleBloc>().add(PuzzleEvent.changeForbiddenCellsMode()),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<PuzzleBloc>().add(PuzzleEvent.reset()),
          ),
        ],
      ),
      body: BlocConsumer<PuzzleBloc, PuzzleState>(
          listenWhen: (previous, current) =>
              previous.status == GameStatus.solving && current.status == GameStatus.solved,
          listener: _showResultDialog,
          builder: (BuildContext context, PuzzleState state) => LayoutBuilder(builder: (context, constraints) {
                final bloc = context.read<PuzzleBloc>();
                bloc.add(PuzzleEvent.setViewSize(constraints.biggest));
                return Stack(
                  children: [
                    state.status == GameStatus.initializing
                        ? Center(child: CircularProgressIndicator())
                        : GestureDetector(
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
                                  pieces: state.pieces,
                                  grid: state.gridConfig,
                                  board: state.boardConfig,
                                  selectedPiece: state.selectedPiece,
                                  previewPosition: state.previewPosition,
                                  showPreview: state.showPreview,
                                  previewCollision: state.previewCollision,
                                  boardLabel: S.current.boardLabel,
                                ),
                              ),
                            ),
                          ),
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (state.allowSolutionDisplay) ...[
                            FloatingActionButton(
                              onPressed: () => bloc.add(
                                PuzzleEvent.showSolution(
                                  (state.solutionIdx > 0 ? state.solutionIdx : state.solutions.length) - 1,
                                ),
                              ),
                              backgroundColor: state.selectedPiece != null ? Colors.orange : Colors.grey,
                              child: const Icon(Icons.arrow_left),
                            ),
                            const SizedBox(width: 8),
                            Text(S.of(context).solutionLabel(state.solutionIdx + 1, state.solutions.length)),
                            const SizedBox(width: 8),
                            FloatingActionButton(
                              onPressed: () => bloc.add(
                                PuzzleEvent.showSolution(
                                  state.solutionIdx < state.solutions.length - 1 ? state.solutionIdx + 1 : 0,
                                ),
                              ),
                              backgroundColor: state.selectedPiece != null ? Colors.orange : Colors.grey,
                              child: const Icon(Icons.arrow_right),
                            ),
                            const SizedBox(width: 8),
                          ],
                          state.isSolving
                              ? CircularProgressIndicator()
                              : FloatingActionButton(
                                  onPressed: () => bloc.add(PuzzleEvent.solve()),
                                  backgroundColor: state.selectedPiece != null ? Colors.orange : Colors.grey,
                                  child: const Icon(Icons.lightbulb),
                                ),
                          const SizedBox(width: 8),
                          FloatingActionButton(
                            onPressed: state.isUndoEnabled ? () => bloc.add(PuzzleEvent.undo()) : null,
                            backgroundColor: state.isUndoEnabled ? Colors.grey : Colors.grey[400],
                            child: Icon(Icons.undo, color: state.isUndoEnabled ? Colors.black : Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          //for debugging, temporary
                          Text('${state.moveIndex}\n${state.moveHistory.length}'),
                          const SizedBox(width: 8),
                          FloatingActionButton(
                            onPressed: state.isRedoEnabled ? () => bloc.add(PuzzleEvent.redo()) : null,
                            backgroundColor: state.isRedoEnabled ? Colors.grey : Colors.grey[400],
                            child: Icon(Icons.redo, color: state.isRedoEnabled ? Colors.black : Colors.grey),
                          ),
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
              })),
    );
  }

  void _showResultDialog(BuildContext context, PuzzleState state) async {
    if (state.solutions.isNotEmpty) {
      final bloc = context.read<PuzzleBloc>();
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => PlatformAlertDialog(
          title: Text(S.of(context).searchCompletedDialogTitle),
          content: Text(S.of(context).solutionsFoundDialogMessage(state.solutions.length)),
          actions: [
            PlatformDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(S.of(context).solutionsFoundDialogCancel),
            ),
            PlatformDialogAction(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(S.of(context).solutionsFoundDialogOk),
            ),
          ],
        ),
      );
      if (result == true) {
        bloc.add(PuzzleEvent.showSolution(0));
      }
    } else {
      await showDialog<bool>(
        context: context,
        builder: (context) => PlatformAlertDialog(
          title: Text(S.of(context).searchCompletedDialogTitle),
          content: Text(S.of(context).solutionsNotFoundDialogMessage),
          actions: [
            PlatformDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(S.of(context).ok),
            ),
          ],
        ),
      );
    }
  }
}
