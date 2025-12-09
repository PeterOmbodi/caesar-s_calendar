import 'package:caesar_puzzle/core/services/timer_service.dart';
import 'package:caesar_puzzle/core/utils/puzzle_grid_extension.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/injection.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_flip_flap/flutter_flip_flap.dart';

enum TripleInfoDisplay { blank, timer, solutionIndex }

extension TripleInfoDisplayX on TripleInfoDisplay {
  String get label => switch (this) {
    TripleInfoDisplay.blank => '',
    TripleInfoDisplay.timer => S.current.time,
    TripleInfoDisplay.solutionIndex => S.current.solutionShort,
  };

  Stream<String> cell2Stream({required final PuzzleState state, required final TimerService timerService}) {
    switch (this) {
      case TripleInfoDisplay.blank:
        return Stream<String>.value('  ');
      case TripleInfoDisplay.timer:
        return timerService
            .minutes(
              startedAt: state.firstMoveAt,
              lastResumedAt: state.lastResumedAt,
              activeElapsedMs: state.activeElapsedMs,
              isPaused: state.isPaused,
            )
            .map((final e) => e.toString().padLeft(2, '0'));
      case TripleInfoDisplay.solutionIndex:
        return Stream<String>.value(' #');
    }
  }

  Stream<String> cell3Stream({required final PuzzleBloc bloc, required final TimerService timerService}) {
    switch (this) {
      case TripleInfoDisplay.blank:
        return Stream<String>.value('  ');
      case TripleInfoDisplay.timer:
        return timerService
            .seconds(
              startedAt: bloc.state.firstMoveAt,
              lastResumedAt: bloc.state.lastResumedAt,
              activeElapsedMs: bloc.state.activeElapsedMs,
              isPaused: bloc.state.isPaused,
            )
            .map((final e) => e.toString().padLeft(2, '0'));
      case TripleInfoDisplay.solutionIndex:
        String formatState(final PuzzleState state) =>
            '${state.solutionIdx + 1}'.padLeft(state.applicableSolutions.length < 100 ? 2 : 3, '0');

        return Stream<String>.multi((final controller) {
          controller.add(formatState(bloc.state));
          final sub = bloc.stream.map(formatState).distinct().listen(controller.add);
          controller.onCancel = sub.cancel;
        });
    }
  }
}

class InfoDisplay3Cell extends StatelessWidget {
  const InfoDisplay3Cell({super.key});

  @override
  Widget build(final BuildContext context) => BlocBuilder<PuzzleBloc, PuzzleState>(
    builder: (final context, final state) {
      final displayMode = switch (state.status) {
        GameStatus.playing => TripleInfoDisplay.timer,
        GameStatus.solutionsReady => TripleInfoDisplay.timer,
        GameStatus.showingSolution => TripleInfoDisplay.solutionIndex,
        _ => TripleInfoDisplay.blank,
      };

      final timerService = getIt<TimerService>();

      final bloc = context.read<PuzzleBloc>();
      final cell2Stream = displayMode.cell2Stream(state: bloc.state, timerService: timerService);
      final cell3Stream = displayMode.cell3Stream(bloc: bloc, timerService: timerService);

      final cell3minWidth = displayMode == TripleInfoDisplay.solutionIndex && state.applicableSolutions.length > 99
          ? 14.0
          : 20.0;

      return Flex(
        direction: state.cfgCellOffset(3).dx == state.cfgCellOffset(4).dx ? Axis.vertical : Axis.horizontal,
        children: [
          ConstrainedBox(
            constraints: state.gridConfig.cellConstraints(),
            child: FlipFlapDisplay.fromText(
              key: const Key('unit#1'),
              text: displayMode.label,
              textStyle: FlipFlapTheme.of(context).textStyle.copyWith(fontSize: 16),
              unitConstraints: const BoxConstraints(minWidth: 46, minHeight: 32),
              cardsInPack: 1,
              unitType: UnitType.text,
            ),
          ),
          StreamBuilder<String>(
            stream: cell2Stream,
            initialData: '',
            builder: (final context, final snapshot) => ConstrainedBox(
              constraints: state.gridConfig.cellConstraints(),
              child: FlipFlapDisplay.fromText(
                text: snapshot.data ?? '',
                unitConstraints: const BoxConstraints(minWidth: 20, minHeight: 32),
              ),
            ),
          ),
          StreamBuilder<String>(
            stream: cell3Stream,
            initialData: '',
            builder: (final context, final snapshot) => ConstrainedBox(
              constraints: state.gridConfig.cellConstraints(),
              child: FlipFlapDisplay.fromText(
                text: snapshot.data ?? '',
                unitConstraints: BoxConstraints(minWidth: cell3minWidth, minHeight: 32),
              ),
            ),
          ),
        ],
      );
    },
  );
}
