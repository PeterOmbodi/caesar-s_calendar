import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/puzzle_view.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/cubit_settings_query.dart';
import 'package:caesar_puzzle/presentation/pages/settings/settings_view.dart';
import 'package:caesar_puzzle/presentation/widgets/floating_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
          child: Stack(
            children: [
              const PuzzleView(),
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
        endDrawer: isWideScreen ? null : const SizedBox(width: _sideWidth, child: SettingsPanel()),
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
        final bloc = context.read<PuzzleBloc>();
        return FloatingPanel(
          children: [
            if (isSetupVisible)
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                tooltip: S.current.settings,
              ),
            if (state.allowSolutionDisplay) ...[
              IconButton(
                icon: Icon(Icons.arrow_left),
                onPressed: () => bloc.add(
                  PuzzleEvent.showSolution((state.solutionIdx > 0 ? state.solutionIdx : state.solutions.length) - 1),
                ),
                tooltip: S.current.prevSolution,
              ),
              Text(S.of(context).solutionLabel(state.solutionIdx + 1, state.solutions.length)),
              IconButton(
                icon: Icon(Icons.arrow_right),
                onPressed: () => bloc.add(
                  PuzzleEvent.showSolution(state.solutionIdx < state.solutions.length - 1 ? state.solutionIdx + 1 : 0),
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
                      onPressed: () => bloc.add(PuzzleEvent.solve(keepUserMoves: true)),
                      tooltip: S.current.searchSolution,
                    ),
            if (state.allowHintDisplay)
              IconButton(
                icon: Icon(Icons.tips_and_updates_outlined),
                onPressed: () => bloc.add(PuzzleEvent.hint()),
                tooltip: S.current.hint,
              ),
            if (state.moveHistory.isNotEmpty) ...[
              IconButton(
                icon: Icon(Icons.undo),
                onPressed: state.isUndoEnabled ? () => bloc.add(PuzzleEvent.undo()) : null,
                tooltip: S.current.undo,
              ),
              //for debugging, temporary
              //Text('${state.moveIndex}\n${state.moveHistory.length}'),
              IconButton(
                icon: Icon(Icons.redo),
                onPressed: state.isRedoEnabled ? () => bloc.add(PuzzleEvent.redo()) : null,
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
