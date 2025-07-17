import 'package:caesar_puzzle/presentation/pages/puzzle/puzzle_view.dart';
import 'package:caesar_puzzle/presentation/widgets/floating_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../generated/l10n.dart';
import '../../theme/theme.dart';
import 'bloc/puzzle_bloc.dart';

class PuzzleScreen extends StatelessWidget {
  const PuzzleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocProvider(
          create: (_) => PuzzleBloc(),
          child: Stack(
            children: [
              const PuzzleView(),
              Positioned(
                bottom: 24,
                right: 24,
                child: BlocBuilder<PuzzleBloc, PuzzleState>(
                  builder: (context, state) {
                    final bloc = context.read<PuzzleBloc>();
                    return FloatingPanel(
                      children: [
                        IconButton(
                          icon: Icon(Icons.brightness_6),
                          onPressed: () => context.read<ThemeModeNotifier>().toggle(),
                          tooltip: S.current.switchTheme,
                        ),
                        if (state.allowSolutionDisplay) ...[
                          IconButton(
                            icon: Icon(Icons.arrow_left),
                            onPressed: () => bloc.add(
                              PuzzleEvent.showSolution(
                                (state.solutionIdx > 0 ? state.solutionIdx : state.solutions.length) - 1,
                              ),
                            ),
                          ),
                          Text(S.of(context).solutionLabel(state.solutionIdx + 1, state.solutions.length)),
                          IconButton(
                            icon: Icon(Icons.arrow_right),
                            onPressed: () => bloc.add(
                              PuzzleEvent.showSolution(
                                state.solutionIdx < state.solutions.length - 1 ? state.solutionIdx + 1 : 0,
                              ),
                            ),
                          ),
                        ] else
                          state.isSolving
                              ? SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : IconButton(
                                  icon: Icon(Icons.lightbulb),
                                  onPressed: () => bloc.add(PuzzleEvent.solve()),
                                ),
                        if (state.moveHistory.isNotEmpty) ...[
                          IconButton(
                            icon: Icon(Icons.undo),
                            onPressed: state.isUndoEnabled ? () => bloc.add(PuzzleEvent.undo()) : null,
                          ),
                          //for debugging, temporary
                          Text('${state.moveIndex}\n${state.moveHistory.length}'),
                          IconButton(
                            icon: Icon(Icons.redo),
                            onPressed: state.isRedoEnabled ? () => bloc.add(PuzzleEvent.redo()) : null,
                          ),
                        ],
                        if (!state.allowSolutionDisplay)
                          IconButton(
                            icon: Icon(state.isUnlockedForbiddenCells ? Icons.lock_open_outlined : Icons.lock_outlined),
                            onPressed: () => context.read<PuzzleBloc>().add(PuzzleEvent.changeForbiddenCellsMode()),
                          ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => context.read<PuzzleBloc>().add(PuzzleEvent.reset()),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
