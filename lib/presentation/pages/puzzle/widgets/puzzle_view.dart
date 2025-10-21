import 'package:caesar_puzzle/core/utils/puzzle_grid_extension.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/animated_pieces_overlay.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/puzzle_board_painter.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_flip_flap/flutter_flip_flap.dart';

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
                    if (solvabilityState >= 0 || solutionsCountState >= 0)
                      Positioned(
                        left: state.cfgCellOffset(0).dx,
                        top: state.cfgCellOffset(0).dy,
                        child: _SolvabilityMark(
                          solvabilable: solvabilityState > 0 || solutionsCountState > 0,
                          cellSize: state.gridConfig.cellSize,
                        ),
                      ),
                    if (solutionsCountState >= 0)
                      Positioned(
                        left: state.cfgCellOffset(1).dx,
                        top: state.cfgCellOffset(1).dy,
                        child: ConstrainedBox(
                          constraints: state.gridConfig.cellconstraints(),
                          child: FlipFlapDisplay(
                            text: '$solutionsCountState'.padLeft(2, '0'),
                            cardsInPack: 4,
                            unitConstraints: BoxConstraints(
                              minWidth: solutionsCountState < 100 ? 20 : 14,
                              minHeight: 32,
                            ),
                          ),
                        ),
                      ),
                    if (state.isShowSolutions) ...[
                      Positioned(
                        left: state.cfgCellOffset(3).dx,
                        top: state.cfgCellOffset(3).dy,
                        child: ConstrainedBox(
                          constraints: state.gridConfig.cellconstraints(),
                          child: FlipFlapDisplay(
                            text: S.current.solutionShort,
                            unitConstraints: const BoxConstraints(minWidth: 46, minHeight: 32),
                            cardsInPack: 1,
                            displayType: UnitType.text,
                          ),
                        ),
                      ),
                      Positioned(
                        left: state.cfgCellOffset(4).dx,
                        top: state.cfgCellOffset(4).dy,
                        child: ConstrainedBox(
                          constraints: state.gridConfig.cellconstraints(),
                          child: FlipFlapDisplay(
                            text: ' #',
                            unitConstraints: const BoxConstraints(minWidth: 20, minHeight: 32),
                            cardsInPack: 1,
                          ),
                        ),
                      ),
                      Positioned(
                        left: state.cfgCellOffset(5).dx,
                        top: state.cfgCellOffset(5).dy,
                        child: ConstrainedBox(
                          constraints: state.gridConfig.cellconstraints(),
                          child: FlipFlapDisplay(
                            text: '${state.solutionIdx + 1}'.padLeft(solutionsCountState < 100 ? 2 : 3, '0'),
                            unitConstraints: BoxConstraints(
                              minWidth: solutionsCountState < 100 ? 20 : 14,
                              minHeight: 32,
                            ),
                            cardsInPack: 2,
                          ),
                        ),
                      ),
                    ],
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
