import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/animated_pieces_overlay.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/info_display_3_cell.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/puzzle_board_painter.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_grid_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_flip_flap/flutter_flip_flap.dart';

class PuzzleView extends StatelessWidget {
  const PuzzleView({super.key});

  @override
  Widget build(final BuildContext context) => BlocBuilder<PuzzleBloc, PuzzleState>(
    builder: (final BuildContext context, final PuzzleState state) => LayoutBuilder(
      builder: (final context, final constraints) {
        final bloc = context.read<PuzzleBloc>();
        bloc.add(PuzzleEvent.setViewSize(constraints.biggest));
        final borderColorMode = context.watch<SettingsCubit>().state.separateMoveColors;

        int _showOrHide(final bool show, final int value) => show ? value : -1;

        final settings = context.watch<SettingsCubit>().state;
        final applicableCount = state.applicableSolutions.length;

        final solvabilityState = _showOrHide(
          settings.solutionIndicator == SolutionIndicator.solvability,
          applicableCount,
        );

        final solutionsCountState = _showOrHide(
          settings.solutionIndicator == SolutionIndicator.countSolutions || state.isShowSolutions,
          applicableCount,
        );

        return state.status == GameStatus.initializing
            ? Center(child: CircularProgressIndicator())
            : Container(
                color: Theme.of(context).colorScheme.primary.withAlpha(18),
                width: double.infinity,
                height: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _PuzzleInfoOverlays(
                      visible: state.isDragging,
                      state: state,
                      solvabilityState: solvabilityState,
                      solutionsCountState: solutionsCountState,
                      showInfoDisplay: state.isShowSolutions || settings.showTimer,
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (final details) => bloc.add(PuzzleEvent.onTapDown(details.localPosition)),
                      onTapUp: (final details) => bloc.add(PuzzleEvent.onTapUp(details.localPosition)),
                      onPanStart: (final details) => bloc.add(PuzzleEvent.onPanStart(details.localPosition)),
                      onPanUpdate: (final details) => bloc.add(PuzzleEvent.onPanUpdate(details.localPosition)),
                      onPanEnd: (final details) => bloc.add(PuzzleEvent.onPanEnd(details.localPosition)),
                      onDoubleTapDown: (final details) => bloc.add(PuzzleEvent.onDoubleTapDown(details.localPosition)),
                      child: AnimatedPiecesOverlay(
                        pieces: state.pieces,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        borderColorMode: borderColorMode,
                        selectedPiece: state.selectedPiece,
                        childBuilder: (final hiddenIds) => CustomPaint(
                          painter: PuzzleBoardPainter(
                            pieces: state.pieces.where((final p) => !hiddenIds.contains(p.id) || p.isConfigItem),
                            grid: state.gridConfig,
                            board: state.boardConfig,
                            selectedPiece: state.selectedPiece,
                            previewPosition: state.previewPosition,
                            showPreview: state.showPreview,
                            previewCollision: state.previewCollision,
                            borderColorMode: borderColorMode,
                            selectedDate: state.selectedDate,
                          ),
                        ),
                      ),
                    ),
                    _PuzzleInfoOverlays(
                      visible: !state.isDragging,
                      state: state,
                      solvabilityState: solvabilityState,
                      solutionsCountState: solutionsCountState,
                      showInfoDisplay: state.isShowSolutions || settings.showTimer,
                    ),
                  ],
                ),
              );
      },
    ),
  );
}

class _PuzzleInfoOverlays extends StatelessWidget {
  const _PuzzleInfoOverlays({
    required this.visible,
    required this.state,
    required this.solvabilityState,
    required this.solutionsCountState,
    required this.showInfoDisplay,
  });

  final bool visible;
  final PuzzleState state;
  final int solvabilityState;
  final int solutionsCountState;
  final bool showInfoDisplay;

  @override
  Widget build(final BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            if (solvabilityState >= 0 || solutionsCountState >= 0)
              Positioned(
                left: state.cfgCellOffset(0).dx,
                top: state.cfgCellOffset(0).dy,
                child: const _SolvabilityMark(),
              ),
            if (solutionsCountState >= 0)
              Positioned(
                left: state.cfgCellOffset(1).dx,
                top: state.cfgCellOffset(1).dy,
                child: ConstrainedBox(
                  constraints: state.gridConfig.cellConstraints(),
                  child: FlipFlapDisplay.fromText(
                    text: '$solutionsCountState'.padLeft(2, '0'),
                    unitsInPack: 4,
                    unitConstraints: BoxConstraints(minWidth: solutionsCountState < 100 ? 20 : 14, minHeight: 32),
                    unitType: UnitType.number,
                    useShortestWay: false,
                  ),
                ),
              ),
            if (showInfoDisplay)
              Positioned(
                left: state.cfgCellOffset(3).dx,
                top: state.cfgCellOffset(3).dy,
                child: const InfoDisplay3Cell(),
              ),
          ],
        ),
      ),
    );
  }
}

class _SolvabilityMark extends StatelessWidget {
  const _SolvabilityMark();

  @override
  Widget build(final BuildContext context) => BlocSelector<PuzzleBloc, PuzzleState, bool>(
    selector: (final s) => s.applicableSolutions.isNotEmpty,
    builder: (final context, final solvabilable) {
      final icon = solvabilable ? Icons.check_circle : Icons.cancel;
      final iconColor = solvabilable ? Colors.green : Colors.red;
      final cellSize = context.read<PuzzleBloc>().state.gridConfig.cellSize;
      return Padding(
        padding: const EdgeInsets.all(6),
        child: FlipFlapDisplay(
          items: [
            FlipFlapWidgetItem.flip(
              flipAxis: Axis.horizontal,
              duration: const Duration(milliseconds: 1000),
              child: Padding(
                key: ValueKey(icon.codePoint),
                padding: const EdgeInsets.all(4),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cellSize / 2),
                    color: Colors.grey.shade200,
                  ),
                  child: Center(
                    child: Baseline(
                      baseline: 24,
                      baselineType: TextBaseline.alphabetic,
                      child: Text(
                        String.fromCharCode(icon.codePoint),
                        style: TextStyle(
                          fontFamily: icon.fontFamily,
                          package: icon.fontPackage,
                          fontSize: 26,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          unitConstraints: BoxConstraints.tightFor(height: cellSize - 12, width: cellSize - 12),
        ),
      );
    },
  );
}
