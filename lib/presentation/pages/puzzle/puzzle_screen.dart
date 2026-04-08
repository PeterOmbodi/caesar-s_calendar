import 'package:caesar_puzzle/application/models/puzzle_piece_snapshot.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/puzzle_history_use_case.dart';
import 'package:caesar_puzzle/application/solve_puzzle_use_case.dart';
import 'package:caesar_puzzle/core/models/move.dart';
import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/core/services/timer_service.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/injection.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_bloc.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_event.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_state.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_mode.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_step.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_step_policy.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/puzzle_local_snapshot.dart';
import 'package:caesar_puzzle/presentation/onboarding/utils/onboarding_target_resolver.dart';
import 'package:caesar_puzzle/presentation/onboarding/utils/puzzle_local_snapshot_mapper.dart';
import 'package:caesar_puzzle/presentation/onboarding/widgets/onboarding_overlay.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/confetti_view.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/puzzle_view.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/cubit_settings_query.dart';
import 'package:caesar_puzzle/presentation/pages/settings/settings_view.dart';
import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_entity_extension.dart';
import 'package:caesar_puzzle/presentation/widgets/floating_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import 'bloc/puzzle_bloc.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  static const sidePanelWidth = 340.0;
  static const wideScreenBreakpoint = 1124.0;

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  static final DateTime _tutorialDate = DateTime(2024);

  late final PuzzleBloc _puzzleBloc;
  late final OnboardingBloc _onboardingBloc;
  PuzzleLocalSnapshot? _preOnboardingSnapshot;
  PuzzleLocalSnapshot? _tutorialBaseSnapshot;
  String? _tutorialPShapeId;
  OnboardingState _lastOnboardingState = const OnboardingState.hidden();
  var _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) {
      return;
    }

    _puzzleBloc = PuzzleBloc(
      settings: CubitSettingsQuery(context.read<SettingsCubit>()),
      solvePuzzleUseCase: getIt<SolvePuzzleUseCase>(),
      historyUseCase: getIt<PuzzleHistoryUseCase>(),
    );
    _onboardingBloc = OnboardingBloc();
    _isInitialized = true;

    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (!mounted) {
        return;
      }
      _maybePresentOnboarding();
    });
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _puzzleBloc.close();
      _onboardingBloc.close();
    }
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final isWideScreen =
        MediaQuery
            .of(context)
            .size
            .width >= PuzzleScreen.wideScreenBreakpoint;
    return MultiBlocProvider(
      providers: [
        BlocProvider<PuzzleBloc>.value(value: _puzzleBloc),
        BlocProvider<OnboardingBloc>.value(value: _onboardingBloc),
      ],
      child: Scaffold(
        body: SafeArea(
          child: MultiBlocListener(
            listeners: [
              BlocListener<PuzzleBloc, PuzzleState>(
                listenWhen: (final ps, final cs) =>
                cs.moveIndex == ps.moveIndex + 1 &&
                    cs.isPieceInGrid(cs.moveHistory.last.pieceId),
                listener: (final context, final state) {
                  final settingsCubit = context.read<SettingsCubit>();
                  final settings = settingsCubit.state;
                  if (settings.unlockConfig && settings.autoLockConfig) {
                    settingsCubit.toggleUnlockConfig(false);
                  }
                },
              ),
              BlocListener<SettingsCubit, SettingsState>(
                listenWhen: (final previous, final current) =>
                    previous.solutionIndicator == SolutionIndicator.none &&
                    current.solutionIndicator != SolutionIndicator.none,
                listener: (final context, final state) {
                  context.read<PuzzleBloc>().markCurrentSessionEasy();
                },
              ),
              BlocListener<PuzzleBloc, PuzzleState>(
                listenWhen: (final previous, final current) => _didCompleteDragOnboardingStep(previous, current),
                listener: (final context, final state) {
                  context.read<OnboardingBloc>().add(const CompleteCurrentOnboardingStep());
                },
              ),
              BlocListener<PuzzleBloc, PuzzleState>(
                listenWhen: (final previous, final current) => _didCompleteRotateOnboardingStep(previous, current),
                listener: (final context, final state) {
                  context.read<OnboardingBloc>().add(const CompleteCurrentOnboardingStep());
                },
              ),
              BlocListener<PuzzleBloc, PuzzleState>(
                listenWhen: (final previous, final current) => _didCompleteFlipOnboardingStep(previous, current),
                listener: (final context, final state) {
                  context.read<OnboardingBloc>().add(const CompleteCurrentOnboardingStep());
                },
              ),
              BlocListener<OnboardingBloc, OnboardingState>(
                listener: (final context, final state) {
                  final previous = _lastOnboardingState;

                  if (!previous.isVisible && state.isVisible) {
                    _preOnboardingSnapshot ??= buildPuzzleLocalSnapshot(_puzzleBloc.state);
                    _tutorialBaseSnapshot = null;
                    _tutorialPShapeId = null;
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    _puzzleBloc.add(PuzzleEvent.setPuzzleDate(_tutorialDate, onboarding: true));
                  } else if (previous.isVisible && !state.isVisible) {
                    if (_didFinishOnboarding(previous)) {
                      context.read<SettingsCubit>().completeOnboarding(currentOnboardingVersion);
                    }
                    final snapshot = _preOnboardingSnapshot;
                    _preOnboardingSnapshot = null;
                    _tutorialBaseSnapshot = null;
                    _tutorialPShapeId = null;
                    if (snapshot != null) {
                      _puzzleBloc.add(PuzzleEvent.restoreLocalSnapshot(snapshot));
                    }
                  } else if (previous.isVisible &&
                      state.isVisible &&
                      state.currentStepIndex != previous.currentStepIndex &&
                      _tutorialBaseSnapshot != null) {
                    _applyTutorialStepSnapshot();
                  } else if (previous.isVisible &&
                      state.isVisible &&
                      state.currentStep?.id == OnboardingStepId.dragPiece &&
                      !previous.isCurrentStepInteractionEnabled &&
                      state.isCurrentStepInteractionEnabled &&
                      _tutorialBaseSnapshot != null) {
                    _applyTutorialStepSnapshot();
                  }

                  _lastOnboardingState = state;
                },
              ),
              BlocListener<PuzzleBloc, PuzzleState>(
                listenWhen: (final previous, final current) =>
                    _onboardingBloc.state.isVisible &&
                    _tutorialBaseSnapshot == null &&
                    current.selectedDate.year == _tutorialDate.year &&
                    current.selectedDate.month == _tutorialDate.month &&
                    current.selectedDate.day == _tutorialDate.day &&
                    current.moveIndex == 0 &&
                    !current.isDragging,
                listener: (final context, final state) {
                  _captureTutorialBaseSnapshot(state);
                  _applyTutorialStepSnapshot();
                },
              ),
              BlocListener<PuzzleBloc, PuzzleState>(
                listenWhen: (final ps, final cs) =>
                !cs.isRestoredSolvedSession &&
                    !cs.hasShownSolvedDialog &&
                    ps.status == GameStatus.playing &&
                    cs.status == GameStatus.solvedByUser,
                listener: (final context, final state) {
                  context.read<PuzzleBloc>().add(const PuzzleEvent.markSolvedDialogShown());
                  _showSolvedDialog(context, state);
                },
              ),
            ],
            child: Stack(
              children: [
                const PuzzleView(),
                Align(
                  alignment: Alignment.topCenter,
                  child: BlocBuilder<PuzzleBloc, PuzzleState>(
                    buildWhen: (final ps, final cs) =>
                    !cs.isRestoredSolvedSession &&
                        (ps.status == GameStatus.playing &&
                            cs.status == GameStatus.solvedByUser ||
                            ps.status == GameStatus.solvedByUser &&
                                ps.status != cs.status),
                    builder:
                        (final BuildContext context, final PuzzleState state) =>
                    !state.isRestoredSolvedSession &&
                        state.status == GameStatus.solvedByUser
                        ? const ConfettiView()
                        : SizedBox.shrink(),
                  ),
                ),
                Positioned(
                  bottom: 24,
                  right: 12 + (isWideScreen ? PuzzleScreen.sidePanelWidth : 0),
                  child: _BottomFAB(isSetupVisible: !isWideScreen),
                ),
                if (isWideScreen)
                  const Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: SizedBox(
                      width: PuzzleScreen.sidePanelWidth,
                      child: SettingsPanel(),
                    ),
                  ),
                const OnboardingOverlay(),
              ],
            ),
          ),
        ),
        endDrawer: isWideScreen
            ? null
            : const SizedBox(width: PuzzleScreen.sidePanelWidth, child: SettingsPanel()),
      ),
    );
  }

  Future<void> _showSolvedDialog(final BuildContext context,
      final PuzzleState state,) async {
    final spentSeconds = getIt<TimerService>().totalElapsedSeconds(
      startedAt: state.firstMoveAt,
      lastResumedAt: state.lastResumedAt,
      activeElapsedMs: state.activeElapsedMs,
      isPaused: state.isPaused,
    );
    final difficulty = context.read<PuzzleBloc>().currentSessionDifficulty;
    final difficultyLabel = _difficultyLabel(context, difficulty);
    final difficultyStars = _difficultyStars(difficulty);
    final configLabel = _configLabel(context, state);
    final configColor =
        state.isCustomConfig ? AppColors.current.customConfigAccent : null;
    final secondsText = '${spentSeconds % 60}'.padLeft(2, '0');
    final minutesText = '${spentSeconds ~/ 60}'.padLeft(2, '0');
    final spentTime = '$minutesText:$secondsText';
    final usedHints = state.gridPieces
        .where((final e) => !e.isUsersItem)
        .length;
    await showDialog(
      context: context,
      builder: (final context) => PlatformAlertDialog(
        title: Text(S.of(context).solvedAlertTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(S.current.solvedAlertSubTitle),
            Text('${S.current.solvedAlertLevelLabel}: $difficultyStars $difficultyLabel'),
            Text(
              '${S.current.solvedAlertConfigLabel}:  $configLabel',
              style: state.isCustomConfig
                  ? TextStyle(
                      color: configColor,
                      fontWeight: FontWeight.w600,
                    )
                  : null,
            ),
            Text('${S.current.timeSpent}: $spentTime'),
            Text('${S.current.hintUsed}: $usedHints'),
          ],
        ),
        actions: [
          PlatformDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(S
                .of(context)
                .ok),
          ),
        ],
      ),
    );
  }

  String _difficultyLabel(
    final BuildContext context,
    final PuzzleSessionDifficulty difficulty,
  ) =>
      difficulty == PuzzleSessionDifficulty.hard
      ? S.of(context).historyDifficultyHard
      : S.of(context).historyDifficultyEasy;

  String _difficultyStars(final PuzzleSessionDifficulty difficulty) =>
      difficulty == PuzzleSessionDifficulty.hard ? '★★' : '★';

  String _configLabel(final BuildContext context, final PuzzleState state) =>
      state.isCustomConfig
      ? S.of(context).historyConfigCustom
      : S.of(context).historyConfigStandard;

  bool _didCompleteDragOnboardingStep(
    final PuzzleState previous,
    final PuzzleState current,
  ) {
    final onboardingState = _onboardingBloc.state;
    if (!onboardingState.isVisible ||
        onboardingState.currentStep?.id != OnboardingStepId.dragPiece ||
        !onboardingState.isCurrentStepInteractionEnabled) {
      return false;
    }
    if (current.moveIndex != previous.moveIndex + 1 || current.moveHistory.isEmpty) {
      return false;
    }

    final move = current.moveHistory.last;
      if (move is! MovePiece) {
        return false;
      }
      final targetTopLeft = resolvePTargetTopLeft(current);
      final targetRelativePosition = current.gridConfig.relativePosition(targetTopLeft);
      final piece = current.pieces.firstWhere(
        (final candidate) => candidate.id == move.pieceId,
        orElse: () => current.pieces.first,
      );

      return piece.type == PieceType.pShape &&
          !piece.isConfigItem &&
          move.to.zone == PlaceZone.grid &&
          piece.placeZone == PlaceZone.grid &&
          move.to.position.dx == targetRelativePosition.dx &&
          move.to.position.dy == targetRelativePosition.dy;
    }

  bool _didCompleteRotateOnboardingStep(
    final PuzzleState previous,
    final PuzzleState current,
  ) {
    final onboardingState = _onboardingBloc.state;
    if (!onboardingState.isVisible ||
        onboardingState.currentStep?.id != OnboardingStepId.rotatePiece ||
        !onboardingState.isCurrentStepInteractionEnabled) {
      return false;
    }
    if (current.moveIndex != previous.moveIndex + 1 || current.moveHistory.isEmpty) {
      return false;
    }

    final move = current.moveHistory.last;
    if (move is! RotatePiece) {
      return false;
    }

    final piece = current.pieces.firstWhere(
      (final candidate) => candidate.id == move.pieceId,
      orElse: () => current.pieces.first,
    );
    return piece.type == PieceType.pShape && !piece.isConfigItem;
  }

  bool _didCompleteFlipOnboardingStep(
    final PuzzleState previous,
    final PuzzleState current,
  ) {
    final onboardingState = _onboardingBloc.state;
    if (!onboardingState.isVisible ||
        onboardingState.currentStep?.id != OnboardingStepId.flipPiece ||
        !onboardingState.isCurrentStepInteractionEnabled) {
      return false;
    }
    if (current.moveIndex != previous.moveIndex + 1 || current.moveHistory.isEmpty) {
      return false;
    }

    final move = current.moveHistory.last;
    if (move is! FlipPiece) {
      return false;
    }

    final piece = current.pieces.firstWhere(
      (final candidate) => candidate.id == move.pieceId,
      orElse: () => current.pieces.first,
    );
    return piece.type == PieceType.pShape && !piece.isConfigItem;
  }

  void _captureTutorialBaseSnapshot(final PuzzleState state) {
    _tutorialBaseSnapshot ??= buildPuzzleLocalSnapshot(state);
    _tutorialPShapeId ??= state.pieces
        .where((final piece) => piece.type == PieceType.pShape && !piece.isConfigItem)
        .map((final piece) => piece.id)
        .cast<String?>()
        .firstWhere((final id) => id != null, orElse: () => null);
  }

  void _applyTutorialStepSnapshot() {
    final baseSnapshot = _tutorialBaseSnapshot;
    final pShapeId = _tutorialPShapeId;
    final stepId = _onboardingBloc.state.currentStep?.id;
    if (baseSnapshot == null || pShapeId == null || stepId == null) {
      return;
    }

    final currentState = _puzzleBloc.state;
    final targetTopLeft = resolvePTargetTopLeft(currentState);
    final targetPosition = Position(dx: targetTopLeft.dx, dy: targetTopLeft.dy);

    final pieces = baseSnapshot.pieces.map((final piece) {
      if (piece.id != pShapeId) {
        return piece;
      }

      return switch (stepId.pShapeSetup) {
        OnboardingPShapeSetup.board => piece,
        OnboardingPShapeSetup.target => PuzzlePieceSnapshot(
            id: piece.id,
            placeZone: PlaceZone.grid,
            position: targetPosition,
            rotation: 0,
            isFlipped: false,
            isUsersItem: piece.isUsersItem,
            isConfigItem: piece.isConfigItem,
          ),
        OnboardingPShapeSetup.targetRotated90 => PuzzlePieceSnapshot(
            id: piece.id,
            placeZone: PlaceZone.grid,
            position: targetPosition,
            rotation: PuzzleBloc.rotationStep,
            isFlipped: false,
            isUsersItem: piece.isUsersItem,
            isConfigItem: piece.isConfigItem,
          ),
      };
    }).toList(growable: false);

    _puzzleBloc.add(
      PuzzleEvent.restoreLocalSnapshot(
        PuzzleLocalSnapshot(
          selectedDate: baseSnapshot.selectedDate,
          status: baseSnapshot.status,
          pieces: pieces,
          moveHistory: const [],
          moveIndex: 0,
          firstMoveAt: null,
          lastResumedAt: null,
          activeElapsedMs: 0,
          hasShownSolvedDialog: false,
          isRestoredSolvedSession: false,
        ),
        onboarding: true,
      ),
    );
  }

  void _maybePresentOnboarding() {
    final settingsCubit = context.read<SettingsCubit>();
    final settings = settingsCubit.state;
    if (settings.shouldAutoStartOnboarding(currentOnboardingVersion)) {
      settingsCubit.markOnboardingOffered(currentOnboardingVersion);
      _onboardingBloc.add(const StartOnboarding(OnboardingMode.short));
      return;
    }
    if (settings.shouldSuggestOnboardingReplay(currentOnboardingVersion)) {
      settingsCubit.markOnboardingOffered(currentOnboardingVersion);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.current.onboardingReplayPrompt),
          action: SnackBarAction(
            label: S.current.onboardingReplayAction,
            onPressed: _startOnboardingReplay,
          ),
        ),
      );
    }
  }

  bool _didFinishOnboarding(final OnboardingState previous) =>
      previous.currentStepIndex == previous.steps.length - 1 && previous.canGoNext;

  void _startOnboardingReplay() {
    context.read<SettingsCubit>().markOnboardingOffered(currentOnboardingVersion);
    _onboardingBloc.add(const StartOnboarding(OnboardingMode.short, isReplay: true));
  }

}

class _BottomFAB extends StatelessWidget {
  const _BottomFAB({required this.isSetupVisible});

  final bool isSetupVisible;

  @override
  Widget build(final BuildContext context) =>
      BlocBuilder<PuzzleBloc, PuzzleState>(
        builder: (final context, final state) {
          final solutionsCount = state.applicableSolutions.length;
          final puzzleBloc = context.read<PuzzleBloc>();
          final solutionIndicator = context
              .watch<SettingsCubit>()
              .state
              .solutionIndicator;
          final isSolvabilityInfoVisible =
              solutionIndicator != SolutionIndicator.none;
          final isSolveDisabled =
              state.isSolving ||
                  (isSolvabilityInfoVisible && solutionsCount == 0) ||
                  state.isShowSolutions;
          final isHintDisabled =
              state.isSolving || isSolveDisabled || state.isShowSolutions || state.isSolved;

          Future<void> onAssistPressed(final VoidCallback allowedEvent) async {
            if (solutionsCount == 0) {
              await showDialog(
                context: context,
                builder: (final context) =>
                    PlatformAlertDialog(
                      title: Text(S
                          .of(context)
                          .searchCompletedDialogTitle),
                      content: Text(S
                          .of(context)
                          .solutionsNotFoundDialogMessage),
                      actions: [
                        PlatformDialogAction(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(S
                              .of(context)
                              .ok),
                        ),
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
                builder: (final context) =>
                    PlatformAlertDialog(
                      title: Text(S
                          .of(context)
                          .searchCompletedDialogTitle),
                      content: Text(
                        S
                            .of(context)
                            .solutionsFoundDialogMessage(
                          state.applicableSolutions.length,
                        ),
                      ),
                      actions: [
                        PlatformDialogAction(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(S
                              .of(context)
                              .solutionsFoundDialogCancel),
                        ),
                        PlatformDialogAction(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(S
                              .of(context)
                              .solutionsFoundDialogOk),
                        ),
                      ],
                    ),
              );
              if (result == true) {
                puzzleBloc.markCurrentSessionEasy();
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
                    : () =>
                    onAssistPressed(
                          () => puzzleBloc.add(PuzzleEvent.showSolution(0)),
                    ),
                tooltip: S.current.searchSolution,
              ),
              IconButton(
                icon: Icon(Icons.tips_and_updates_outlined),
                onPressed: isHintDisabled
                    ? null
                    : () =>
                    onAssistPressed(
                          () => puzzleBloc.add(PuzzleEvent.showHint()),
                    ),
                tooltip: S.current.hint,
              ),
              if (state.isShowSolutions) ...[
                IconButton(
                  icon: Icon(Icons.arrow_left),
                  onPressed: () =>
                      puzzleBloc.add(
                        PuzzleEvent.showSolution(
                          (state.solutionIdx > 0
                              ? state.solutionIdx
                              : solutionsCount) -
                              1,
                        ),
                      ),
                  tooltip: S.current.prevSolution,
                ),
                IconButton(
                  icon: Icon(Icons.arrow_right),
                  onPressed: () =>
                      puzzleBloc.add(
                        PuzzleEvent.showSolution(
                          state.solutionIdx < solutionsCount - 1
                              ? state.solutionIdx + 1
                              : 0,
                        ),
                      ),
                  tooltip: S.current.nextSolution,
                ),
              ] else
                ...[
                  IconButton(
                    icon: Icon(Icons.undo),
                    onPressed: state.isUndoEnabled
                        ? () => puzzleBloc.add(PuzzleEvent.undo())
                        : null,
                    tooltip: S.current.undo,
                  ),
                  IconButton(
                    icon: Icon(Icons.redo),
                    onPressed: state.isRedoEnabled
                        ? () => puzzleBloc.add(PuzzleEvent.redo())
                        : null,
                    tooltip: S.current.redo,
                  ),
                ],
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
                icon: const Icon(Icons.refresh),
                onPressed: () =>
                    context.read<PuzzleBloc>().add(PuzzleEvent.reset()),
                tooltip: S.current.reset,
              ),
            ],
          );
        },
      );
}
