import 'dart:async';

import 'package:caesar_puzzle/core/services/timer_service.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/injection.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/status/status_for.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:flutter/material.dart';

class PuzzleStatusLine extends StatelessWidget {
  const PuzzleStatusLine({super.key, required this.state, required this.indicator, required this.showTimer});

  static const double height = 20;

  final PuzzleState state;
  final SolutionIndicator indicator;
  final bool showTimer;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final status = statusFor(state, indicator);
    final toneColor = switch (status.tone) {
      StatusTone.neutral => colors.textSecondary,
      StatusTone.ok => colors.ok,
      StatusTone.bad => colors.bad,
    };
    const textStyle = TextStyle(fontSize: 15, height: height / 15);

    return SizedBox(
      height: height,
      child: Row(
        children: [
          if (status.tone != StatusTone.neutral) ...[
            DecoratedBox(
              decoration: BoxDecoration(color: toneColor, shape: BoxShape.circle),
              child: const SizedBox.square(dimension: 7),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              _text(status),
              style: textStyle.copyWith(color: toneColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showTimer) ...[
            Icon(Icons.schedule, size: 17, color: colors.textSecondary),
            const SizedBox(width: 5),
            DefaultTextStyle(
              style: textStyle.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              child: state.isShowSolutions || state.isEditingLayout ? const Text('—') : _ElapsedTime(state: state),
            ),
          ],
        ],
      ),
    );
  }

  static String _text(final PuzzleStatus status) => switch (status.message) {
    StatusMessage.readyToPlay => S.current.statusReadyToPlay,
    StatusMessage.searching => S.current.statusSearching,
    StatusMessage.solutionsCount => S.current.statusSolutionsCount(status.count!),
    StatusMessage.oneSolutionLeft => S.current.statusOneSolutionLeft,
    StatusMessage.solvable => S.current.statusSolvable,
    StatusMessage.piecesPlaced => S.current.statusPiecesPlaced(status.count!, status.total!),
    StatusMessage.noSolutions => S.current.statusNoSolutions,
    StatusMessage.deadEnd => S.current.statusDeadEnd,
    StatusMessage.releaseToPlace => S.current.statusReleaseToPlace,
    StatusMessage.doesNotFit => S.current.statusDoesNotFit,
    StatusMessage.keepDrawing => S.current.statusKeepDrawing(status.count!, status.total!),
    StatusMessage.doubleTapToPlace => S.current.statusDoubleTapToPlace,
    StatusMessage.noMatchingShape => S.current.statusNoMatchingShape,
    StatusMessage.solved => S.current.statusSolved,
    StatusMessage.viewingSolution => S.current.statusViewingSolution(status.count!, status.total!),
    StatusMessage.layoutSolutions => S.current.layoutsSolutionsToday(status.count!),
    StatusMessage.layoutNoSolution => S.current.layoutsNoSolutionToday,
  };
}

class _ElapsedTime extends StatefulWidget {
  const _ElapsedTime({required this.state});

  final PuzzleState state;

  @override
  State<_ElapsedTime> createState() => _ElapsedTimeState();
}

class _ElapsedTimeState extends State<_ElapsedTime> {
  final TimerService _timer = getIt<TimerService>();
  StreamSubscription<int>? _subscription;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(covariant final _ElapsedTime oldWidget) {
    super.didUpdateWidget(oldWidget);
    final a = oldWidget.state;
    final b = widget.state;
    if (a.firstMoveAt != b.firstMoveAt ||
        a.lastResumedAt != b.lastResumedAt ||
        a.activeElapsedMs != b.activeElapsedMs ||
        a.isPaused != b.isPaused) {
      _listen();
    }
  }

  void _listen() {
    _subscription?.cancel();
    final state = widget.state;
    _seconds = 0;
    _subscription = _timer
        .elapsedSeconds(
          startedAt: state.firstMoveAt,
          lastResumedAt: state.lastResumedAt,
          activeElapsedMs: state.activeElapsedMs,
          isPaused: state.isPaused,
        )
        .listen((final seconds) => setState(() => _seconds = seconds));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final minutes = '${_seconds ~/ 60}'.padLeft(2, '0');
    final seconds = '${_seconds % 60}'.padLeft(2, '0');
    return Text('$minutes:$seconds');
  }
}
