import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/animated_pieces_overlay.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/puzzle_board_painter.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:caesar_puzzle/presentation/widgets/flip_flap/split_flap_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/puzzle_bloc.dart';

class PuzzleView extends StatelessWidget {
  const PuzzleView({super.key});

  @override
  Widget build(final BuildContext context) => BlocBuilder<PuzzleBloc, PuzzleState>(
    builder: (final BuildContext context, final PuzzleState state) => LayoutBuilder(
      builder: (final context, final constraints) {
        final bloc = context.read<PuzzleBloc>();
        bloc.add(PuzzleEvent.setViewSize(constraints.biggest));
        final borderColorMode = context.watch<SettingsCubit>().state.separateMoveColors;

        final solutionIndicator = context.watch<SettingsCubit>().state.solutionIndicator;
        final solvability = solutionIndicator == SolutionIndicator.solvability
            ? context.watch<PuzzleBloc>().state.applicableSolutions.length
            : -1;
        final solutionsCount = solutionIndicator == SolutionIndicator.countSolutions || state.allowSolutionNavigation
            ? context.watch<PuzzleBloc>().state.applicableSolutions.length
            : -1;
        //todo solvability && solutionsCount not clear, need to simplify
        return state.status == GameStatus.initializing
            ? Center(child: CircularProgressIndicator())
            : Container(
                color: Theme.of(context).colorScheme.primary.withAlpha(18),
                width: double.infinity,
                height: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (solvability >= 0 || solutionsCount >= 0)
                      Positioned(
                        left: state.cfgCellOffset(0).dx,
                        top: state.cfgCellOffset(0).dy,
                        child: _SolvabilityMark(solvabilable: solvability>0 || solutionsCount > 0, cellSize: state.gridConfig.cellSize),
                      ),
                    if (solutionsCount >= 0)
                      Positioned(
                        left: state.cfgCellOffset(1).dx,
                        top: state.cfgCellOffset(1).dy,
                        child: Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: ConstrainedBox(
                            constraints: BoxConstraints.tightFor(
                              height: state.gridConfig.cellSize,
                              width: state.gridConfig.cellSize,
                            ),
                            child: SplitFlapRow(
                              text: '$solutionsCount'.padLeft(2, '0'),
                              cardsInPack: 2,
                              tileConstraints: BoxConstraints(minWidth: 20, minHeight: 32),
                              symbolStyle: Theme.of(
                                context,
                              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                              tileDecoration: BoxDecoration(
                                color: AppColors.current.boardBorder,
                                border: Border.all(color: AppColors.current.boardBackground),
                                borderRadius: BorderRadius.all(Radius.circular(4)),
                              ),
                              panelDecoration: BoxDecoration(
                                color: AppColors.current.boardBackground,
                                border: Border.all(color: AppColors.current.boardBackground),
                                borderRadius: BorderRadius.all(Radius.circular(2)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (state.allowSolutionNavigation)
                      Positioned(
                        left: state.cfgCellOffset(2).dx,
                        top: state.cfgCellOffset(2).dy,
                        child: Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: ConstrainedBox(
                            constraints: BoxConstraints.tightFor(
                              height: state.gridConfig.cellSize,
                              width: state.gridConfig.cellSize,
                            ),
                            child: SplitFlapRow(
                              text: '${state.solutionIdx + 1}'.padLeft('$solutionsCount'.length, '0'),
                              tileConstraints: BoxConstraints(minWidth: 20, minHeight: 32),
                              symbolStyle: Theme.of(
                                context,
                              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                              tileDecoration: BoxDecoration(
                                color: AppColors.current.boardBorder,
                                border: Border.all(color: AppColors.current.boardBackground),
                                borderRadius: BorderRadius.all(Radius.circular(4)),
                              ),
                              panelDecoration: BoxDecoration(
                                color: AppColors.current.boardBackground,
                                border: Border.all(color: AppColors.current.boardBackground),
                                borderRadius: BorderRadius.all(Radius.circular(2)),
                              ),
                            ),
                          ),
                        ),
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
                  ],
                ),
              );
      },
    ),
  );
}

class _SolvabilityMark extends StatelessWidget {
  const _SolvabilityMark({required this.solvabilable, required this.cellSize});

  final bool solvabilable;
  final double cellSize;

  @override
  Widget build(final BuildContext context) {
    final icon = solvabilable ? Icons.check_circle : Icons.cancel;
    final iconColor = solvabilable ? Colors.green : Colors.red;

    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(height: cellSize, width: cellSize),
      child: Center(
        child: Text(
          String.fromCharCode(icon.codePoint),
          style: TextStyle(fontFamily: icon.fontFamily, package: icon.fontPackage, fontSize: 20, color: iconColor),
        ),
      ),
    );
  }
}
