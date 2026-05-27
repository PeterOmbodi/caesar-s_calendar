import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_grid_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class PuzzleActionButtonStrip extends StatelessWidget {
  const PuzzleActionButtonStrip({super.key});

  @override
  Widget build(final BuildContext context) => BlocBuilder<PuzzleBloc, PuzzleState>(
    builder: (final context, final state) {
      final solutionsCount = state.applicableSolutions.length;
      final puzzleBloc = context.read<PuzzleBloc>();
      final solutionIndicator = context.watch<SettingsCubit>().state.solutionIndicator;
      final isSolvabilityInfoVisible = solutionIndicator != SolutionIndicator.none;
      final isSolveDisabled =
          state.isSolving || (isSolvabilityInfoVisible && solutionsCount == 0) || state.isShowSolutions;
      final isHintDisabled = state.isSolving || isSolveDisabled || state.isShowSolutions || state.isSolved;
      final axis = state.cfgCellOffset(2).dx == state.cfgCellOffset(3).dx ? Axis.vertical : Axis.horizontal;

      Future<void> onHintPressed() async {
        if (solutionsCount == 0) {
          await showDialog(
            context: context,
            builder: (final context) => PlatformAlertDialog(
              title: Text(S.of(context).searchCompletedDialogTitle),
              content: Text(S.of(context).solutionsNotFoundDialogMessage),
              actions: [
                PlatformDialogAction(onPressed: () => Navigator.of(context).pop(), child: Text(S.of(context).ok)),
              ],
            ),
          );
          return;
        }
        if (isSolvabilityInfoVisible) {
          puzzleBloc.add(PuzzleEvent.showHint());
          return;
        }

        final result = await showDialog<bool>(
          context: context,
          builder: (final context) => PlatformAlertDialog(
            title: Text(S.of(context).searchCompletedDialogTitle),
            content: Text(S.of(context).solutionsFoundDialogMessage(state.applicableSolutions.length)),
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
          puzzleBloc.markCurrentSessionEasy();
          puzzleBloc.add(PuzzleEvent.showHint());
        }
      }

      return Flex(
        direction: axis,
        children: [
          _ActionCell(
            icon: Icons.tips_and_updates_outlined,
            onPressed: isHintDisabled ? null : onHintPressed,
            tooltip: S.current.hint,
          ),
          if (state.isShowSolutions) ...[
            _ActionCell(
              icon: Icons.arrow_left,
              onPressed: () => puzzleBloc.add(
                PuzzleEvent.showSolution((state.solutionIdx > 0 ? state.solutionIdx : solutionsCount) - 1),
              ),
              tooltip: S.current.prevSolution,
            ),
            _ActionCell(
              icon: Icons.arrow_right,
              onPressed: () => puzzleBloc.add(
                PuzzleEvent.showSolution(state.solutionIdx < solutionsCount - 1 ? state.solutionIdx + 1 : 0),
              ),
              tooltip: S.current.nextSolution,
            ),
          ] else ...[
            _ActionCell(
              icon: Icons.undo,
              onPressed: state.isUndoEnabled ? () => puzzleBloc.add(PuzzleEvent.undo()) : null,
              tooltip: S.current.undo,
            ),
            _ActionCell(
              icon: Icons.redo,
              onPressed: state.isRedoEnabled ? () => puzzleBloc.add(PuzzleEvent.redo()) : null,
              tooltip: S.current.redo,
            ),
          ],
          state.isSolving
              ? const _ActionProgressCell()
              : _ActionCell(
                  icon: Icons.refresh,
                  onPressed: () => puzzleBloc.add(PuzzleEvent.reset()),
                  tooltip: S.current.reset,
                ),
        ],
      );
    },
  );
}

class _ActionCell extends StatelessWidget {
  const _ActionCell({required this.icon, required this.onPressed, required this.tooltip});

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(final BuildContext context) {
    final state = context.read<PuzzleBloc>().state;
    final cellSize = state.gridConfig.cellSize;
    final iconColor = onPressed == null ? Colors.grey.shade500 : Theme.of(context).colorScheme.primary;

    return ConstrainedBox(
      constraints: state.gridConfig.cellConstraints(),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: SizedBox.square(
          dimension: cellSize - 12,
          child: DecoratedBox(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(cellSize / 2), color: Colors.transparent),
            child: IconButton(
              icon: Icon(icon, size: cellSize / 2, color: iconColor),
              onPressed: onPressed,
              tooltip: tooltip,
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                foregroundColor: iconColor,
                disabledForegroundColor: Colors.grey.shade500,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionProgressCell extends StatelessWidget {
  const _ActionProgressCell();

  @override
  Widget build(final BuildContext context) {
    final state = context.read<PuzzleBloc>().state;
    final cellSize = state.gridConfig.cellSize;

    return ConstrainedBox(
      constraints: state.gridConfig.cellConstraints(),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: SizedBox.square(
          dimension: cellSize - 12,
          child: DecoratedBox(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(cellSize / 2), color: Colors.transparent),
            child: Padding(
              padding: EdgeInsets.all(cellSize / 5),
              child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
      ),
    );
  }
}
