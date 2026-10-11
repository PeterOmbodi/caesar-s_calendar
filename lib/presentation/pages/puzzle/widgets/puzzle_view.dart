import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/models/drawn_group.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_bloc.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_state.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_step.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_step_policy.dart';
import 'package:caesar_puzzle/presentation/onboarding/widgets/overlay/onboarding_overlay_helpers.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/chrome/game_chrome.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/animated_pieces_overlay.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/piece_paint_helper.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/puzzle_board_painter.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/puzzle_status_line.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_entity_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_grid_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PuzzleView extends StatelessWidget {
  const PuzzleView({super.key, this.headerHeight = 0});

  static const double statusGap = 8;

  final double headerHeight;

  @override
  Widget build(final BuildContext context) => BlocBuilder<PuzzleBloc, PuzzleState>(
    builder: (final BuildContext context, final PuzzleState state) => LayoutBuilder(
      builder: (final context, final constraints) {
        final bloc = context.read<PuzzleBloc>();
        final onboardingState = context.watch<OnboardingBloc>().state;
        final spec = ScreenSpec.of(context);
        final contentInsets =
            EdgeInsets.only(top: headerHeight, bottom: statusGap + PuzzleStatusLine.height) +
            GameChrome.reservedInsets(context);
        bloc.add(
          PuzzleEvent.setViewSize(
            constraints.biggest,
            maxCell: spec.maxCell,
            trayScale: spec.trayScale,
            contentInsets: contentInsets,
          ),
        );
        final settings = context.watch<SettingsCubit>().state;
        final borderColorMode = settings.separateMoveColors;
        final tray = state.boardConfig.getBounds;

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

          final pointerPiece = state.pointerPiece;
          if (action == OnboardingInputAction.drag && state.isDragging && pointerPiece != null) {
            return pointerPiece.type == PieceType.pShape && !pointerPiece.isConfigItem;
          }
          final tappedPiece = state.pieces.lastWhere(
            (final piece) => piece.containsPoint(position),
            orElse: () => state.pieces.first,
          );
          return tappedPiece.type == PieceType.pShape &&
              !tappedPiece.isConfigItem &&
              tappedPiece.containsPoint(position);
        }

        final shownPieces = state.isEditingLayout
            ? state.shownPieces.where((final p) => p.isConfigItem)
            : state.shownPieces;
        return state.status == GameStatus.initializing
            ? Center(child: CircularProgressIndicator())
            : SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
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
                            state.pointerPiece?.type != PieceType.pShape) {
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
                        pieces: shownPieces,
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        borderColorMode: borderColorMode,
                        cellSize: state.gridConfig.cellSize,
                        instantIds: {if (state.isDragging && state.pointerPiece != null) state.pointerPiece!.id},
                        selectedPiece: state.pointerPiece ?? state.selectedPiece,
                        pinnedId: state.isDragging ? null : state.selectedPieceId,
                        dimTray: state.isTrayPieceSelected,
                        childBuilder: (final hiddenIds, final trayDim) => CustomPaint(
                          painter: PuzzleBoardPainter(
                            pieces: shownPieces.where(
                              (final p) =>
                                  (!hiddenIds.contains(p.id) || p.isConfigItem) &&
                                  (!state.isDragging || p.id != state.pointerPiece?.id),
                            ),
                            grid: state.gridConfig,
                            selectedPiece: state.pointerPiece ?? state.selectedPiece,
                            previewPosition: state.previewPosition,
                            showPreview: state.showPreview,
                            previewCollision: state.previewCollision,
                            drawnGroup: state.drawnGroup,
                            drawnGroupCommitStatus: state.drawnGroupCommitStatus,
                            borderColorMode: borderColorMode,
                            selectedDate: state.selectedDate,
                            isSolved: state.isSolved,
                            trayDim: trayDim,
                            editingLayout: state.isEditingLayout,
                          ),
                        ),
                      ),
                    ),
                    if (!onboardingState.isVisible)
                      Positioned(
                        left: tray.left,
                        top: tray.bottom + statusGap,
                        width: tray.width,
                        child: IgnorePointer(
                          child: PuzzleStatusLine(
                            state: state,
                            indicator: settings.solutionIndicator,
                            showTimer: settings.showTimer,
                          ),
                        ),
                      ),
                    if (state.isDragging && state.pointerPiece != null)
                      IgnorePointer(
                        child: CustomPaint(
                          painter: _DraggedPiecePainter(piece: state.pointerPiece!, cellSize: state.gridConfig.cellSize),
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
  const _DraggedPiecePainter({required this.piece, required this.cellSize});

  final PuzzlePieceUI piece;
  final double cellSize;

  @override
  void paint(final Canvas canvas, final Size size) =>
      PiecePaintHelper.drawPiece(canvas, piece, cellSize: cellSize, look: PieceLook.lifted, hatched: piece.isConfigItem);

  @override
  bool shouldRepaint(covariant final _DraggedPiecePainter oldDelegate) =>
      oldDelegate.piece != piece || oldDelegate.cellSize != cellSize;
}
