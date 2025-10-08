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
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= _breakpoint;
    return BlocProvider(
      create: (_) => PuzzleBloc(settings: CubitSettingsQuery(context.read<SettingsCubit>())),
      child: Scaffold(
        body: SafeArea(
          child: MultiBlocListener(
            listeners: [
              BlocListener<PuzzleBloc, PuzzleState>(
                listenWhen: (ps, cs) =>
                    cs.moveIndex == ps.moveIndex + 1 && cs.isPieceInGrid(cs.moveHistory.last.pieceId),
                listener: (context, state) {
                  final settingsCubit = context.read<SettingsCubit>();
                  final settings = settingsCubit.state;
                  if (settings.unlockConfig && settings.autoLockConfig) {
                    settingsCubit.toggleUnlockConfig(false);
                  }
                },
              ),
              BlocListener<PuzzleBloc, PuzzleState>(
                listenWhen: (ps, cs) => ps.status == GameStatus.playing && cs.status == GameStatus.solvedByUser,
                listener: _showSolvedDialog,
              ),
            ],
            child: Stack(
              children: [
                const PuzzleView(),
                Align(
                  alignment: Alignment.topCenter,
                  child: BlocBuilder<PuzzleBloc, PuzzleState>(
                    buildWhen: (ps, cs) =>
                        ps.status == GameStatus.playing && cs.status == GameStatus.solvedByUser ||
                        ps.status == GameStatus.solvedByUser && ps.status != cs.status,
                    builder: (BuildContext context, PuzzleState state) =>
                        state.status == GameStatus.solvedByUser ? const ConfettiView() : SizedBox.shrink(),
                  ),
                ),
                Positioned(
                  bottom: 24,
                  right: 24 + (isWideScreen ? _sideWidth : 0),
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

  void _showSolvedDialog(BuildContext context, PuzzleState state) async {
    await showDialog(
      context: context,
      builder: (context) => PlatformAlertDialog(
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
  Widget build(BuildContext context) {
    return BlocBuilder<PuzzleBloc, PuzzleState>(
      builder: (context, state) {

        final solutionsCount = state.applicableSolutions.length;
        final puzzleBloc = context.read<PuzzleBloc>();
        final solutionIndicator = context.watch<SettingsCubit>().state.solutionIndicator;
        final isSolvabilityInfoVisible = solutionIndicator != SolutionIndicator.none;
        final isAssistDisabled = isSolvabilityInfoVisible && solutionsCount == 0;

        void onAssistPressed(VoidCallback allowedEvent) async {
          if (solutionsCount == 0) {
            await showDialog(
              context: context,
              builder: (context) => PlatformAlertDialog(
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
              builder: (context) => PlatformAlertDialog(
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
            if (state.allowSolutionNavigation) ...[
              IconButton(
                icon: Icon(Icons.arrow_left),
                onPressed: () => puzzleBloc.add(
                  PuzzleEvent.showSolution((state.solutionIdx > 0 ? state.solutionIdx : solutionsCount) - 1),
                ),
                tooltip: S.current.prevSolution,
              ),
              Text(S.of(context).solutionLabel(state.solutionIdx + 1, solutionsCount)),
              IconButton(
                icon: Icon(Icons.arrow_right),
                onPressed: () => puzzleBloc.add(
                  PuzzleEvent.showSolution(state.solutionIdx < solutionsCount - 1 ? state.solutionIdx + 1 : 0),
                ),
                tooltip: S.current.nextSolution,
              ),
            ] else
              state.isSolving
                  ? SizedBox(
                      width: 48,
                      height: 48,
                      child: Padding(padding: const EdgeInsets.all(8), child: CircularProgressIndicator()),
                    )
                  : IconButton(
                      icon: Icon(Icons.lightbulb),
                      onPressed: isAssistDisabled
                          ? null
                          : () => onAssistPressed(() => puzzleBloc.add(PuzzleEvent.showSolution(0))),
                      tooltip: S.current.searchSolution,
                    ),
            if (state.allowHintDisplay)
              IconButton(
                icon: Icon(Icons.tips_and_updates_outlined),
                onPressed: isAssistDisabled ? null : () => onAssistPressed(() => puzzleBloc.add(PuzzleEvent.hint())),
                tooltip: S.current.hint,
              ),
            if (state.moveHistory.isNotEmpty) ...[
              IconButton(
                icon: Icon(Icons.undo),
                onPressed: state.isUndoEnabled ? () => puzzleBloc.add(PuzzleEvent.undo()) : null,
                tooltip: S.current.undo,
              ),
              //for debugging, temporary
              //Text('${state.moveIndex}\n${state.moveHistory.length}'),
              IconButton(
                icon: Icon(Icons.redo),
                onPressed: state.isRedoEnabled ? () => puzzleBloc.add(PuzzleEvent.redo()) : null,
                tooltip: S.current.redo,
              ),
            ],
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<PuzzleBloc>().add(PuzzleEvent.reset()),
              tooltip: S.current.reset,
            ),
          ],
        );
      },
    );
  }
}
