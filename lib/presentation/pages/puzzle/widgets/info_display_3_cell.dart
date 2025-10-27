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

  Stream<String> cell2Stream({
    required final PuzzleBloc bloc,
    required final TimerService timerService,
    required final ({int start, bool running}) timer,
  }) {
    switch (this) {
      case TripleInfoDisplay.blank:
        return Stream<String>.value('  ');
      case TripleInfoDisplay.timer:
        return timerService
            .minutes(start: timer.start, running: timer.running)
            .map((final e) => e.toString().padLeft(2, '0'));
      case TripleInfoDisplay.solutionIndex:
        return Stream<String>.value(' #');
    }
  }

  Stream<String> cell3Stream({
    required final PuzzleBloc bloc,
    required final TimerService timerService,
    required final ({int start, bool running}) timer,
  }) {
    switch (this) {
      case TripleInfoDisplay.blank:
        return Stream<String>.value('  ');
      case TripleInfoDisplay.timer:
        return timerService
            .seconds(start: timer.start, running: timer.running)
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

      final timer = context.select<PuzzleBloc, ({int start, bool running})>(
        (final b) => (
          start: b.state.firstMoveAt ?? 0,
          running: b.state.status == GameStatus.playing || b.state.status == GameStatus.solutionsReady,
        ),
      );

      final timerService = getIt<TimerService>();

      final bloc = context.read<PuzzleBloc>();
      final cell2 = displayMode.cell2Stream(bloc: bloc, timerService: timerService, timer: timer);
      final cell3 = displayMode.cell3Stream(bloc: bloc, timerService: timerService, timer: timer);

      final cell3minWidth = displayMode == TripleInfoDisplay.solutionIndex && state.applicableSolutions.length > 99
          ? 14.0
          : 20.0;

      return Flex(
        direction: state.cfgCellOffset(3).dx == state.cfgCellOffset(4).dx ? Axis.vertical : Axis.horizontal,
        children: [
          ConstrainedBox(
            constraints: state.gridConfig.cellConstraints(),
            child: FlipFlapDisplay(
              key: const Key('unit#1'),
              text: displayMode.label,
              textStyle: FlipFlapTheme.of(context).textStyle.copyWith(fontSize: 16),
              unitConstraints: const BoxConstraints(minWidth: 46, minHeight: 32),
              cardsInPack: 1,
              displayType: UnitType.text,
            ),
          ),
          StreamBuilder<String>(
            stream: cell2,
            initialData: '',
            builder: (final context, final snapshot) => ConstrainedBox(
              constraints: state.gridConfig.cellConstraints(),
              child: FlipFlapDisplay(
                key: const Key('unit#2'),
                text: snapshot.data ?? '',
                unitConstraints: const BoxConstraints(minWidth: 20, minHeight: 32),
                cardsInPack: 2,
              ),
            ),
          ),
          StreamBuilder<String>(
            stream: cell3,
            initialData: '',
            builder: (final context, final snapshot) => ConstrainedBox(
              constraints: state.gridConfig.cellConstraints(),
              child: FlipFlapDisplay(
                key: const Key('unit#3'),
                text: snapshot.data ?? '',
                unitConstraints: BoxConstraints(minWidth: cell3minWidth, minHeight: 32),
                cardsInPack: 2,
              ),
            ),
          ),
        ],
      );
    },
  );
}
