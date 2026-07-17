import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/models/drawn_group.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_bloc.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_state.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_step.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_step_policy.dart';
import 'package:caesar_puzzle/presentation/onboarding/widgets/overlay/onboarding_overlay_helpers.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/animated_pieces_overlay.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/info_display_3_cell.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/piece_paint_helper.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/puzzle_account_chip.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/puzzle_board_painter.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_grid_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_extension.dart';
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
        final onboardingState = context.watch<OnboardingBloc>().state;
        bloc.add(PuzzleEvent.setViewSize(constraints.biggest));
        final borderColorMode = context.watch<SettingsCubit>().state.separateMoveColors;

        final settings = context.watch<SettingsCubit>().state;
        final applicableCount = state.applicableSolutions.length;
        final isOnboardingVisible = onboardingState.isVisible;
        final indicatorMode = _PuzzleIndicatorMode.resolve(
          isOnboardingVisible: isOnboardingVisible,
          solutionIndicator: settings.solutionIndicator,
          isShowSolutions: state.isShowSolutions,
        );

        bool isInteractionAllowed(final Offset position, {required final OnboardingInputAction action}) {
          final step = onboardingState.currentStep;
          if (!onboardingState.isVisible) {
            return true;
          }
          final stepId = step?.id;
          if (stepId == null) {
            return true;
          }
          if (stepId == OnboardingStepId.drawPiece) {
            if (!onboardingState.isCurrentStepInteractionEnabled) {
              return false;
            }
            return _isDrawOnboardingInteractionAllowed(state, position, action: action);
          }
          if (stepId.allowedInputAction == null) {
            return false;
          }
          if (!onboardingState.isCurrentStepInteractionEnabled || stepId.allowedInputAction != action) {
            return false;
          }

          final selectedPiece = state.selectedPiece;
          if (action == OnboardingInputAction.drag && state.isDragging && selectedPiece != null) {
            return selectedPiece.type == PieceType.pShape && !selectedPiece.isConfigItem;
          }
          final tappedPiece = state.pieces.lastWhere(
            (final piece) => piece.containsPoint(position),
            orElse: () => state.pieces.first,
          );
          return tappedPiece.type == PieceType.pShape &&
              !tappedPiece.isConfigItem &&
              tappedPiece.containsPoint(position);
        }

        return state.status == GameStatus.initializing
            ? Center(child: CircularProgressIndicator())
            : SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (indicatorMode != _PuzzleIndicatorMode.hidden)
                      Positioned(
                        left: state.cfgCellOffset(1).dx,
                        top: state.cfgCellOffset(1).dy,
                        child: _PuzzleIndicatorCell(mode: indicatorMode, solutionsCount: applicableCount),
                      ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (final details) {
                        if (!isInteractionAllowed(details.localPosition, action: OnboardingInputAction.tap)) {
                          return;
                        }
                        bloc.add(PuzzleEvent.onTapDown(details.localPosition));
                      },
                      onTapUp: (final details) {
                        if (!isInteractionAllowed(details.localPosition, action: OnboardingInputAction.tap)) {
                          return;
                        }
                        bloc.add(PuzzleEvent.onTapUp(details.localPosition));
                      },
                      onPanStart: (final details) {
                        if (!isInteractionAllowed(details.localPosition, action: OnboardingInputAction.drag)) {
                          return;
                        }
                        bloc.add(PuzzleEvent.onPanStart(details.localPosition));
                      },
                      onPanUpdate: (final details) {
                        if (!isInteractionAllowed(details.localPosition, action: OnboardingInputAction.drag)) {
                          return;
                        }
                        bloc.add(PuzzleEvent.onPanUpdate(details.localPosition));
                      },
                      onPanEnd: (final details) {
                        if (onboardingState.isVisible &&
                            onboardingState.currentStep?.id == OnboardingStepId.dragPiece &&
                            onboardingState.isCurrentStepInteractionEnabled &&
                            state.isDragging &&
                            state.selectedPiece?.type != PieceType.pShape) {
                          return;
                        }
                        bloc.add(PuzzleEvent.onPanEnd(details.localPosition));
                      },
                      onDoubleTapDown: (final details) {
                        if (_shouldWarnAboutWrongDrawOnboardingGroup(state, onboardingState, details.localPosition)) {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(content: Text(S.current.onboardingDrawWrongShape)));
                          return;
                        }
                        if (!isInteractionAllowed(details.localPosition, action: OnboardingInputAction.doubleTap)) {
                          return;
                        }
                        bloc.add(PuzzleEvent.onDoubleTapDown(details.localPosition));
                      },
                      child: AnimatedPiecesOverlay(
                        pieces: state.pieces,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        borderColorMode: borderColorMode,
                        selectedPiece: state.selectedPiece,
                        childBuilder: (final hiddenIds) => CustomPaint(
                          painter: PuzzleBoardPainter(
                            pieces: state.pieces.where(
                              (final p) =>
                                  (!hiddenIds.contains(p.id) || p.isConfigItem) &&
                                  (!state.isDragging || p.id != state.selectedPiece?.id),
                            ),
                            grid: state.gridConfig,
                            board: state.boardConfig,
                            selectedPiece: state.selectedPiece,
                            previewPosition: state.previewPosition,
                            showPreview: state.showPreview,
                            previewCollision: state.previewCollision,
                            drawnGroup: state.drawnGroup,
                            drawnGroupCommitStatus: state.drawnGroupCommitStatus,
                            borderColorMode: borderColorMode,
                            selectedDate: state.selectedDate,
                          ),
                        ),
                      ),
                    ),
                    if (!isOnboardingVisible)
                      Positioned(
                        left: state.cfgCellOffset(0).dx,
                        top: state.cfgCellOffset(0).dy,
                        child: const PuzzleAccountChip(),
                      ),
                    if (!isOnboardingVisible && (state.isShowSolutions || settings.showTimer))
                      Positioned(
                        left: state.cfgCellOffset(3).dx,
                        top: state.cfgCellOffset(3).dy,
                        child: InfoDisplay3Cell(),
                      ),
                    if (state.isDragging && state.selectedPiece != null)
                      IgnorePointer(
                        child: CustomPaint(
                          painter: _DraggedPiecePainter(piece: state.selectedPiece!, borderColorMode: borderColorMode),
                        ),
                      ),
                  ],
                ),
              );
      },
    ),
  );
}

bool _isDrawOnboardingInteractionAllowed(
  final PuzzleState state,
  final Offset position, {
  required final OnboardingInputAction action,
}) {
  final cell = state.gridConfig.cellAt(position);
  if (cell == null) {
    return false;
  }
  if (action == OnboardingInputAction.tap) {
    return state.drawnGroup?.contains(cell) == true;
  }
  if (action != OnboardingInputAction.drag && action != OnboardingInputAction.doubleTap) {
    return false;
  }
  if (state.drawnGroup?.contains(cell) == true) {
    return true;
  }
  return _drawOnboardingAllowedCells(state).contains(cell);
}

bool _shouldWarnAboutWrongDrawOnboardingGroup(
  final PuzzleState state,
  final OnboardingState onboardingState,
  final Offset position,
) {
  if (!onboardingState.isVisible ||
      onboardingState.currentStep?.id != OnboardingStepId.drawPiece ||
      !onboardingState.isCurrentStepInteractionEnabled ||
      state.drawnGroupCommitStatus == DrawnGroupCommitStatus.committable) {
    return false;
  }
  final cell = state.gridConfig.cellAt(position);
  return cell != null && state.drawnGroup?.contains(cell) == true;
}

Set<Cell> _drawOnboardingAllowedCells(final PuzzleState state) {
  final targetPiece = buildDragDemoTargetPiece(state);
  if (targetPiece == null) {
    return const {};
  }

  final targetCells = targetPiece.cells(state.gridConfig.origin, state.gridConfig.cellSize);
  final allowedCells = <Cell>{...targetCells};
  for (final cell in targetCells) {
    allowedCells.addAll({
      Cell(cell.row - 1, cell.col),
      Cell(cell.row + 1, cell.col),
      Cell(cell.row, cell.col - 1),
      Cell(cell.row, cell.col + 1),
    });
  }
  allowedCells.removeWhere(
    (final cell) =>
        cell.row < 0 || cell.row >= state.gridConfig.rows || cell.col < 0 || cell.col >= state.gridConfig.columns,
  );
  return allowedCells;
}

class _DraggedPiecePainter extends CustomPainter {
  const _DraggedPiecePainter({required this.piece, required this.borderColorMode});

  final PuzzlePieceUI piece;
  final bool borderColorMode;

  @override
  void paint(final Canvas canvas, final Size size) {
    PiecePaintHelper.drawPiece(canvas, piece, true, borderColorMode);
    final centerPaint = Paint()
      ..color = AppColors.current.pieceCenterDot
      ..style = PaintingStyle.fill;
    canvas.drawCircle(piece.position + piece.centerPoint, 5.0, centerPaint);
  }

  @override
  bool shouldRepaint(covariant final _DraggedPiecePainter oldDelegate) =>
      oldDelegate.piece != piece || oldDelegate.borderColorMode != borderColorMode;
}

enum _PuzzleIndicatorMode {
  hidden,
  solvability,
  solutionsCount;

  static _PuzzleIndicatorMode resolve({
    required final bool isOnboardingVisible,
    required final SolutionIndicator solutionIndicator,
    required final bool isShowSolutions,
  }) {
    if (isOnboardingVisible) {
      return _PuzzleIndicatorMode.hidden;
    }
    if (solutionIndicator == SolutionIndicator.solvability) {
      return _PuzzleIndicatorMode.solvability;
    }
    if (solutionIndicator == SolutionIndicator.countSolutions || isShowSolutions) {
      return _PuzzleIndicatorMode.solutionsCount;
    }
    return _PuzzleIndicatorMode.hidden;
  }
}

class _PuzzleIndicatorCell extends StatelessWidget {
  const _PuzzleIndicatorCell({required this.mode, required this.solutionsCount});

  final _PuzzleIndicatorMode mode;
  final int solutionsCount;

  @override
  Widget build(final BuildContext context) => switch (mode) {
    _PuzzleIndicatorMode.hidden => const SizedBox.shrink(),
    _PuzzleIndicatorMode.solvability => const _SolvabilityMark(),
    _PuzzleIndicatorMode.solutionsCount => ConstrainedBox(
      constraints: context.read<PuzzleBloc>().state.gridConfig.cellConstraints(),
      child: FlipFlapDisplay.fromText(
        text: '$solutionsCount'.padLeft(2, '0'),
        unitsInPack: 4,
        unitConstraints: _solutionCounterConstraints(context, solutionsCount),
        unitType: UnitType.number,
        useShortestWay: false,
      ),
    ),
  };
}

BoxConstraints _solutionCounterConstraints(final BuildContext context, final int solutionsCount) {
  final cellSize = context.read<PuzzleBloc>().state.gridConfig.cellSize;
  return BoxConstraints(minWidth: solutionsCount < 100 ? cellSize * 0.4 : cellSize * 0.28, minHeight: cellSize * 0.64);
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
      final outerPadding = cellSize * 0.12;
      final innerPadding = cellSize * 0.08;
      return Padding(
        padding: EdgeInsets.all(outerPadding),
        child: FlipFlapDisplay(
          items: [
            FlipFlapWidgetItem.flip(
              flipAxis: Axis.horizontal,
              duration: const Duration(milliseconds: 1000),
              child: Padding(
                key: ValueKey(icon.codePoint),
                padding: EdgeInsets.all(innerPadding),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cellSize / 2),
                    color: Colors.grey.shade200,
                  ),
                  child: Center(
                    child: Icon(icon, size: cellSize * 0.48, color: iconColor),
                  ),
                ),
              ),
            ),
          ],
          unitConstraints: BoxConstraints.tightFor(height: cellSize * 0.76, width: cellSize * 0.76),
        ),
      );
    },
  );
}
