import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/confetti_view.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/puzzle_view.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/cubit_settings_query.dart';
import 'package:caesar_puzzle/presentation/pages/settings/settings_view.dart';
import 'package:caesar_puzzle/presentation/widgets/floating_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import 'bloc/puzzle_bloc.dart';

const _sideWidth = 340.0;
const _breakpoint = 1124.0;

class PuzzleScreen extends StatelessWidget {
  const PuzzleScreen({super.key});

  @override
  Widget build(final BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= _breakpoint;
    return BlocProvider(
      create: (_) => PuzzleBloc(settings: CubitSettingsQuery(context.read<SettingsCubit>())),
      child: Scaffold(
        body: SafeArea(
          child: MultiBlocListener(
            listeners: [
              BlocListener<PuzzleBloc, PuzzleState>(
                listenWhen: (final ps, final cs) =>
                    cs.moveIndex == ps.moveIndex + 1 && cs.isPieceInGrid(cs.moveHistory.last.pieceId),
                listener: (final context, final state) {
                  final settingsCubit = context.read<SettingsCubit>();
                  final settings = settingsCubit.state;
                  if (settings.unlockConfig && settings.autoLockConfig) {
                    settingsCubit.toggleUnlockConfig(false);
                  }
                },
              ),
              BlocListener<PuzzleBloc, PuzzleState>(
                listenWhen: (final ps, final cs) =>
                    ps.status == GameStatus.playing && cs.status == GameStatus.solvedByUser,
                listener: _showSolvedDialog,
              ),
            ],
            child: Stack(
              children: [
                const PuzzleView(),
                Align(
                  alignment: Alignment.topCenter,
                  child: BlocBuilder<PuzzleBloc, PuzzleState>(
                    buildWhen: (final ps, final cs) =>
                        ps.status == GameStatus.playing && cs.status == GameStatus.solvedByUser ||
                        ps.status == GameStatus.solvedByUser && ps.status != cs.status,
                    builder: (final BuildContext context, final PuzzleState state) =>
                        state.status == GameStatus.solvedByUser ? const ConfettiView() : SizedBox.shrink(),
                  ),
                ),
                Positioned(
                  bottom: 24,
                  right: 12 + (isWideScreen ? _sideWidth : 0),
                  child: _BottomFAB(isSetupVisible: !isWideScreen),
                ),
                if (isWideScreen)
                  const Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: SizedBox(width: _sideWidth, child: SettingsPanel()),
                  ),
              ],
            ),
          ),
        ),
        endDrawer: isWideScreen ? null : const SizedBox(width: _sideWidth, child: SettingsPanel()),
      ),
    );
  }

  Future<void> _showSolvedDialog(final BuildContext context, final PuzzleState state) async {
    await showDialog(
      context: context,
      builder: (final context) => PlatformAlertDialog(
        title: Text(S.of(context).solvedAlertTitle),
        content: Text(S.of(context).solvedAlertSubTitle),
        actions: [PlatformDialogAction(onPressed: () => Navigator.of(context).pop(), child: Text(S.of(context).ok))],
      ),
    );
  }
}

class _BottomFAB extends StatelessWidget {
  const _BottomFAB({required this.isSetupVisible});

  final bool isSetupVisible;

  @override
  Widget build(final BuildContext context) => BlocBuilder<PuzzleBloc, PuzzleState>(
    builder: (final context, final state) {
      final solutionsCount = state.applicableSolutions.length;
      final puzzleBloc = context.read<PuzzleBloc>();
      final solutionIndicator = context.watch<SettingsCubit>().state.solutionIndicator;
      final isSolvabilityInfoVisible = solutionIndicator != SolutionIndicator.none;
      final isSolveDisabled =
          state.isSolving || (isSolvabilityInfoVisible && solutionsCount == 0) || state.isShowSolutions;
      final isHintDisabled = state.isSolving || isSolveDisabled || state.isShowSolutions;

      Future<void> onAssistPressed(final VoidCallback allowedEvent) async {
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
          allowedEvent.call();
        } else {
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
            allowedEvent.call();
          }
        }
      }

      return FloatingPanel(
        children: [
          if (isSetupVisible)
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              tooltip: S.current.settings,
            ),
          IconButton(
                icon: Icon(Icons.lightbulb),
                onPressed: isSolveDisabled
                    ? null
                    : () => onAssistPressed(() => puzzleBloc.add(PuzzleEvent.showSolution(0))),
                tooltip: S.current.searchSolution,
              ),
              IconButton(
                icon: Icon(Icons.tips_and_updates_outlined),
                onPressed: isHintDisabled ? null : () => onAssistPressed(() => puzzleBloc.add(PuzzleEvent.showHint())),
                tooltip: S.current.hint,
              ),
              if (state.isShowSolutions) ...[
                IconButton(
                  icon: Icon(Icons.arrow_left),
                  onPressed: () => puzzleBloc.add(
                    PuzzleEvent.showSolution((state.solutionIdx > 0 ? state.solutionIdx : solutionsCount) - 1),
                  ),
                  tooltip: S.current.prevSolution,
                ),
                IconButton(
                  icon: Icon(Icons.arrow_right),
                  onPressed: () => puzzleBloc.add(
                    PuzzleEvent.showSolution(state.solutionIdx < solutionsCount - 1 ? state.solutionIdx + 1 : 0),
                  ),
                  tooltip: S.current.nextSolution,
                ),
              ] else ...[
                IconButton(
                  icon: Icon(Icons.undo),
                  onPressed: state.isUndoEnabled ? () => puzzleBloc.add(PuzzleEvent.undo()) : null,
                  tooltip: S.current.undo,
                ),
                IconButton(
                  icon: Icon(Icons.redo),
                  onPressed: state.isRedoEnabled ? () => puzzleBloc.add(PuzzleEvent.redo()) : null,
                  tooltip: S.current.redo,
                ),
              ],
          state.isSolving
              ? SizedBox(
                  width: 48,
                  height: 48,
                  child: Padding(padding: const EdgeInsets.all(8), child: CircularProgressIndicator()),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => context.read<PuzzleBloc>().add(PuzzleEvent.reset()),
                  tooltip: S.current.reset,
                ),
        ],
      );
    },
  );
}
