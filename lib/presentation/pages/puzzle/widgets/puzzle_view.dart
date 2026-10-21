import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/chrome/game_chrome.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/animated_pieces_overlay.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/piece_paint_helper.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/pointer_controls.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/puzzle_board_painter.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/puzzle_status_line.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/services/layout_service.dart';
import 'package:caesar_puzzle/presentation/utils/month_label.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_entity_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PuzzleView extends StatelessWidget {
  const PuzzleView({super.key, this.headerHeight = 0});

  static const double statusGap = LayoutService.statusLineGap;

  final double headerHeight;

  @override
  Widget build(final BuildContext context) => BlocBuilder<PuzzleBloc, PuzzleState>(
    builder: (final BuildContext context, final PuzzleState state) => LayoutBuilder(
      builder: (final context, final constraints) {
        final bloc = context.read<PuzzleBloc>();
        final spec = ScreenSpec.of(context);
        // A phone in landscape gives the board the full height; header and status line sit beside it.
        final headerBesideBoard = spec.window == WindowClass.compact && spec.isLandscape;
        final contentInsets =
            (headerBesideBoard
                ? EdgeInsets.zero
                : EdgeInsets.only(top: headerHeight, bottom: statusGap + PuzzleStatusLine.height)) +
            GameChrome.reservedInsets(context);
        bloc.add(
          PuzzleEvent.setViewSize(
            constraints.biggest,
            maxCell: spec.maxCell,
            trayScale: spec.trayScale,
            contentInsets: contentInsets,
            trayTopInset: headerBesideBoard ? headerHeight : 0,
          ),
        );
        final settings = context.watch<SettingsCubit>().state;
        final borderColorMode = settings.separateMoveColors;
        final grid = state.gridConfig.getBounds;
        final tray = state.boardConfig.getBounds;
        final contentRect = contentInsets.deflateRect(Offset.zero & constraints.biggest);
        final isPortrait = contentRect.height > contentRect.width;
        final (statusLeft, statusWidth) = switch ((isPortrait, spec.window)) {
          (true, _) => (grid.left, grid.width),
          (false, WindowClass.compact) => (
            state.trayArea.left + statusGap,
            (state.trayArea.width - statusGap * 2).clamp(0.0, double.infinity),
          ),
          (false, _) => (tray.left, tray.width),
        };

        final shownPieces = state.isEditingLayout
            ? state.shownPieces.where((final p) => p.isConfigItem)
            : state.shownPieces;
        return state.status == GameStatus.initializing
            ? const Center(child: CircularProgressIndicator.adaptive())
            : SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PointerControls(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (final details) => bloc.add(PuzzleEvent.onTapDown(details.localPosition)),
                        onTapUp: (final details) => bloc.add(PuzzleEvent.onTapUp(details.localPosition)),
                        onPanStart: (final details) => bloc.add(PuzzleEvent.onPanStart(details.localPosition)),
                        onPanUpdate: (final details) => bloc.add(PuzzleEvent.onPanUpdate(details.localPosition)),
                        onPanEnd: (final details) => bloc.add(PuzzleEvent.onPanEnd(details.localPosition)),
                        onDoubleTapDown: (final details) =>
                            bloc.add(PuzzleEvent.onDoubleTapDown(details.localPosition)),
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
                    ),
                    Positioned.fromRect(
                      rect: state.gridConfig.getBounds,
                      child: IgnorePointer(
                        child: Semantics(container: true, label: _boardLabel(state), child: const SizedBox.expand()),
                      ),
                    ),
                    Positioned(
                      left: statusLeft,
                      top: isPortrait ? tray.bottom + statusGap : grid.bottom - PuzzleStatusLine.height,
                      width: statusWidth,
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

String _boardLabel(final PuzzleState state) {
  final date = state.selectedDate;
  final pieces = state.pieces.where((final p) => !p.isConfigItem);
  final placed = pieces.where((final p) => p.placeZone == PlaceZone.grid).length;
  return '${S.current.headerGoal(shortMonthName(date.month), '${date.day}')}. '
      '${S.current.statusPiecesPlaced(placed, pieces.length)}';
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
