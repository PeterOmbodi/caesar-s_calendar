import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/widgets/puzzle_board_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import 'bloc/puzzle_bloc.dart';

class PuzzleView extends StatelessWidget {
  const PuzzleView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PuzzleBloc, PuzzleState>(
      listenWhen: (previous, current) =>
          current.moveIndex == previous.moveIndex + 1 && current.isPieceInGrid(current.moveHistory.last.pieceId),
      listener: (context, state) {
        final settingsCubit = context.read<SettingsCubit>();
        final settings = settingsCubit.state;
        if (settings.unlockConfig && settings.autoLockConfig) {
          settingsCubit.toggleUnlockConfig(false);
        }
      },
      child: BlocConsumer<PuzzleBloc, PuzzleState>(
        listenWhen: (previous, current) =>
            previous.status == GameStatus.searchingAllSolutions && current.status == GameStatus.solutionsReady ||
            previous.status == GameStatus.searchingHint && current.status == GameStatus.hintReady,
        listener: _showResultDialog,
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
                      child: CustomPaint(
                        painter: PuzzleBoardPainter(
                          pieces: state.pieces,
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
                  );
          },
        ),
      ),
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
        bloc.add(state.status == GameStatus.solutionsReady ? PuzzleEvent.showSolution(0) : PuzzleEvent.showHint(0));
      }
    } else {
      await showDialog(
        context: context,
        builder: (context) => PlatformAlertDialog(
          title: Text(S.of(context).searchCompletedDialogTitle),
          content: Text(S.of(context).solutionsNotFoundDialogMessage),
          actions: [PlatformDialogAction(onPressed: () => Navigator.of(context).pop(), child: Text(S.of(context).ok))],
        ),
      );
    }
  }
}
