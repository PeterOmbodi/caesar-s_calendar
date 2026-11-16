import 'dart:async';
import 'dart:math';

import 'package:caesar_puzzle/application/race/noop_session_recorder.dart';
import 'package:caesar_puzzle/application/race/race_board.dart';
import 'package:caesar_puzzle/application/race/race_lights.dart';
import 'package:caesar_puzzle/application/race/race_result.dart';
import 'package:caesar_puzzle/application/race/race_room.dart';
import 'package:caesar_puzzle/application/race/race_rules.dart';
import 'package:caesar_puzzle/application/race/race_settings_query.dart';
import 'package:caesar_puzzle/application/race/solver_level.dart';
import 'package:caesar_puzzle/application/solve_puzzle_use_case.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/injection.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/actions/game_action.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/chrome/game_chrome.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/chrome/glass_chrome.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/puzzle_haptics.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/puzzle_screen.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/puzzle_sounds.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/confetti_view.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/puzzle_toolbar.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/puzzle_view.dart';
import 'package:caesar_puzzle/presentation/pages/race/bloc/race_room_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/race/widgets/countdown_overlay.dart';
import 'package:caesar_puzzle/presentation/pages/race/widgets/race_header.dart';
import 'package:caesar_puzzle/presentation/pages/race/widgets/race_result_sheet.dart';
import 'package:caesar_puzzle/presentation/pages/race/widgets/race_standings.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/theme/chrome_theme.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_entity_extension.dart';
import 'package:caesar_puzzle/presentation/widgets/confirm_dialog.dart';
import 'package:caesar_puzzle/presentation/widgets/game_background.dart';
import 'package:caesar_puzzle/presentation/widgets/max_width.dart';
import 'package:caesar_puzzle/presentation/widgets/measure_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shown by the room screen in place of the lobby; needs its [RaceRoomCubit].
class RaceGameScreen extends StatefulWidget {
  const RaceGameScreen({
    super.key,
    required this.room,
    required this.myUid,
    required this.startAtMs,
    required this.date,
    required this.solverLevel,
  });

  final RaceRoom room;
  final String myUid;
  final int startAtMs;
  final DateTime date;

  /// Null in a race between people.
  final SolverLevel? solverLevel;

  @override
  State<RaceGameScreen> createState() => _RaceGameScreenState();
}

class _RaceGameScreenState extends State<RaceGameScreen> {
  // Header and toolbar have fixed slots; larger text would not fit them.
  static const double _maxChromeTextScale = 1.3;

  late final RaceRoomCubit _cubit = context.read<RaceRoomCubit>();
  final PuzzleBloc _bloc = PuzzleBloc(
    settings: const RaceSettingsQuery(),
    solvePuzzleUseCase: getIt<SolvePuzzleUseCase>(),
    sessionRecorder: const NoopSessionRecorder(),
    mode: PuzzleMode.race,
  );
  late final StreamSubscription<PuzzleState> _subscription;
  final _sounds = PuzzleSounds();
  Timer? _phaseTimer;
  var _isStarted = false;
  var _isOver = false;
  var _isRaceLoaded = false;

  /// Server time when this player solved, gave up or the board closed.
  int? _stoppedAtMs;

  String? _shownBoardUid;
  var _hasRacedHere = false;
  double _headerHeight = 0;

  int get _nowMs => _cubit.serverNow().millisecondsSinceEpoch;

  bool get _isMyRaceDone => _stoppedAtMs != null;

  @override
  void initState() {
    super.initState();
    var previous = _bloc.state;
    _subscription = _bloc.stream.listen((final next) {
      _onPuzzle(previous, next);
      previous = next;
    });
    _updatePhase();
  }

  @override
  void didUpdateWidget(final RaceGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updatePhase();
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    unawaited(_subscription.cancel());
    unawaited(_bloc.close());
    unawaited(_sounds.dispose());
    super.dispose();
  }

  void _updatePhase() {
    _phaseTimer?.cancel();
    final room = widget.room;
    final now = _nowMs;
    final me = room.player(widget.myUid);
    _isStarted = now >= widget.startAtMs;
    _isOver = _isOver || RaceRules.isOver(room, nowMs: now);
    final duration = me?.durationMs;
    if (duration != null) {
      _stoppedAtMs = widget.startAtMs + duration;
    } else if (_stoppedAtMs == null && ((me?.gaveUp ?? false) || _isOver)) {
      _stoppedAtMs = min(now, RaceRules.endsAtMs(room) ?? now);
    }
    // After a restart the board here is new and empty; it must not replace the published one.
    if (_isStarted && !_isOver) {
      _hasRacedHere = true;
    }
    if (_isOver && _hasRacedHere && me != null && RaceRules.boardOf(me, startAtMs: room.startAt) == null) {
      unawaited(_cubit.publishBoard(_bloc.state.piecePlacements));
    }
    // No room update announces the start, the end of the time to finish or an offline player running out of time.
    final wakeAt = !_isStarted ? widget.startAtMs : (_isOver ? null : RaceRules.nextDeadlineMs(room, nowMs: now));
    if (wakeAt != null) {
      _phaseTimer = Timer(Duration(milliseconds: max(0, wakeAt - now)), () {
        if (mounted) {
          setState(_updatePhase);
        }
      });
    }
  }

  void _onPuzzle(final PuzzleState previous, final PuzzleState next) {
    if (!_isRaceLoaded) {
      // The bloc lays the board out for today first; the race date can only replace it after that.
      if (previous.status == GameStatus.initializing && next.status != GameStatus.initializing) {
        _isRaceLoaded = true;
        _bloc.add(PuzzleEvent.startRace(date: widget.date));
      }
      return;
    }
    final settings = context.read<SettingsCubit>().state;
    final haptic = hapticFor(previous, next);
    if (haptic != null) {
      if (settings.haptics) {
        unawaited(playHaptic(haptic));
      }
      if (settings.sounds) {
        unawaited(_sounds.playClick());
      }
    }
    if (_isMyRaceDone) {
      return;
    }
    final placed = _placed(next);
    if (placed != _placed(previous)) {
      _cubit.reportProgress(placed);
    }
    if (next.isSolved && !previous.isSolved) {
      setState(() => _stoppedAtMs = _nowMs);
      unawaited(_cubit.finish());
    }
  }

  static int _placed(final PuzzleState state) =>
      state.pieces.where((final p) => !p.isConfigItem && p.placeZone == PlaceZone.grid).length;

  Future<void> _onLeave() async {
    if (_shownBoardUid != null) {
      setState(() => _shownBoardUid = null);
      return;
    }
    if (_isMyRaceDone) {
      Navigator.of(context).pop();
      return;
    }
    await _giveUp();
  }

  Future<void> _giveUp() async {
    if (_isMyRaceDone) {
      return;
    }
    final confirmed = await ConfirmDialog.show(
      context,
      title: S.current.raceGiveUpTitle,
      message: S.current.raceGiveUpMessage,
      cancelLabel: S.current.raceKeepRacing,
      confirmLabel: S.current.raceGiveUp,
      destructive: true,
    );
    if (!confirmed || !mounted || _isMyRaceDone) {
      return;
    }
    setState(() => _stoppedAtMs = _nowMs);
    await _cubit.giveUp();
  }

  @override
  Widget build(final BuildContext context) {
    final room = widget.room;
    final chrome = ChromeTheme.of(context);
    final besideTray = ScreenSpec.of(context).toolbar == ToolbarPlacement.bottomBar;
    final isLocked = !_isStarted || _isMyRaceDone || _isOver;
    final standings = RaceStandings(
      players: room.players,
      myUid: widget.myUid,
      isStarted: _isStarted,
      totalPieces: _bloc.state.pieces.where((final p) => !p.isConfigItem).length,
      graceEndsAtMs: _isMyRaceDone || _isOver ? null : RaceRules.graceEndsAtMs(room),
      now: _cubit.serverNow,
      solverLevel: widget.solverLevel,
    );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (final didPop, final _) {
        if (!didPop) {
          unawaited(_onLeave());
        }
      },
      child: BlocProvider<PuzzleBloc>.value(
        value: _bloc,
        child: Scaffold(
          body: GameBackground(
            child: MaxWidth(
              maxWidth: PuzzleScreen.maxGameWidth,
              child: SafeArea(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AbsorbPointer(
                        absorbing: isLocked,
                        child: PuzzleView(
                          headerHeight: _headerHeight,
                          trayStartInset: besideTray ? chrome.barHeight + GlassChrome.edgeMargin : 0,
                        ),
                      ),
                    ),
                    if (!_isStarted)
                      Positioned.fill(
                        child: CountdownOverlay(
                          startAtMs: widget.startAtMs,
                          pauseMs: RaceLights.pauseMs(room.seed),
                          now: _cubit.serverNow,
                          haptics: context.select<SettingsCubit, bool>((final c) => c.state.haptics),
                        ),
                      ),
                    Positioned.fill(
                      child: MediaQuery.withClampedTextScaling(
                        maxScaleFactor: _maxChromeTextScale,
                        child: PuzzleToolbar(
                          race: RaceToolbarControls(
                            phase: _isOver
                                ? RacePhase.over
                                : isLocked
                                ? RacePhase.waiting
                                : RacePhase.racing,
                            isHost: room.hostUid == widget.myUid,
                            onNewRace: () => unawaited(_cubit.rematch()),
                            onLeave: () => Navigator.of(context).pop(),
                          ),
                          accessory: besideTray ? null : standings,
                        ),
                      ),
                    ),
                    if (besideTray) _StandingsSlot(child: standings),
                    if (_isOver)
                      _ResultSlot(
                        room: room,
                        myUid: widget.myUid,
                        nowMs: _nowMs,
                        myBoard: RaceBoard(_bloc.state.piecePlacements),
                        totalPieces: _bloc.state.pieces.where((final p) => !p.isConfigItem).length,
                        shownBoardUid: _shownBoardUid,
                        onShowBoard: (final uid) => setState(() => _shownBoardUid = uid),
                        solverLevel: widget.solverLevel,
                      ),
                    _HeaderSlot(
                      onHeight: (final height) {
                        if (mounted && height != _headerHeight) {
                          setState(() => _headerHeight = height);
                        }
                      },
                      child: MediaQuery.withClampedTextScaling(
                        maxScaleFactor: _maxChromeTextScale,
                        child: RaceHeader(
                          date: widget.date,
                          isStarted: _isStarted,
                          startAtMs: widget.startAtMs,
                          stoppedAtMs: _stoppedAtMs,
                          now: _cubit.serverNow,
                          onLeave: () => unawaited(_onLeave()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderSlot extends StatelessWidget {
  const _HeaderSlot({required this.onHeight, required this.child});

  final ValueChanged<double> onHeight;
  final Widget child;

  @override
  Widget build(final BuildContext context) => BlocSelector<PuzzleBloc, PuzzleState, double>(
    selector: (final state) => state.boardConfig.getBounds.left,
    builder: (final context, final trayLeft) {
      final spec = ScreenSpec.of(context);
      final beside = spec.window == WindowClass.compact && spec.isLandscape;
      final reserved = GameChrome.reservedInsets(context);
      return Positioned(
        left: beside ? trayLeft - 16 : reserved.left,
        top: 0,
        right: beside ? reserved.right : 0,
        child: MeasureSize(onChange: (final size) => onHeight(size.height), child: child),
      );
    },
  );
}

/// Left of the tray, in the room [PuzzleView.trayStartInset] leaves, down to the bottom bar.
class _StandingsSlot extends StatelessWidget {
  const _StandingsSlot({required this.child});

  final Widget child;

  @override
  Widget build(final BuildContext context) => BlocSelector<PuzzleBloc, PuzzleState, double>(
    selector: (final state) => state.boardConfig.getBounds.top,
    builder: (final context, final trayTop) {
      final chrome = ChromeTheme.of(context);
      return Positioned(
        left: GlassChrome.edgeMargin,
        top: trayTop,
        bottom: GlassChrome.edgeMargin + chrome.barHeight + 8,
        width: chrome.barHeight,
        // Nothing to stand beside until the board is laid out.
        child: trayTop > 0 ? child : const SizedBox.shrink(),
      );
    },
  );
}

class _ResultSlot extends StatelessWidget {
  const _ResultSlot({
    required this.room,
    required this.myUid,
    required this.nowMs,
    required this.myBoard,
    required this.totalPieces,
    required this.shownBoardUid,
    required this.onShowBoard,
    required this.solverLevel,
  });

  final RaceRoom room;
  final String myUid;
  final int nowMs;
  final RaceBoard myBoard;
  final int totalPieces;
  final String? shownBoardUid;
  final ValueChanged<String?> onShowBoard;
  final SolverLevel? solverLevel;

  @override
  Widget build(final BuildContext context) {
    final standings = RaceResult.of(room, nowMs: nowMs);
    final isWinner = standings.any((final s) => s.player.uid == myUid && s.isWinner);
    final hostCanStart = room.hostUid != myUid && (room.player(room.hostUid)?.online ?? false);
    final reserved = GameChrome.reservedInsets(context);
    return Positioned.fill(
      child: Stack(
        children: [
          Padding(
            padding: reserved + const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: RaceResultSheet(
                standings: standings,
                myUid: myUid,
                note: hostCanStart ? S.current.raceNewRaceByHost : null,
                myBoard: myBoard,
                startAtMs: room.startAt,
                totalPieces: totalPieces,
                shownUid: shownBoardUid,
                onShowBoard: onShowBoard,
                solverLevel: solverLevel,
              ),
            ),
          ),
          if (isWinner && !MediaQuery.disableAnimationsOf(context))
            const IgnorePointer(
              child: Align(alignment: Alignment.topCenter, child: ConfettiView()),
            ),
        ],
      ),
    );
  }
}
