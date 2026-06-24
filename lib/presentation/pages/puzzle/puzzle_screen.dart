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
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/puzzle_bottom_controls.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/puzzle_view.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/cubit_settings_query.dart';
import 'package:caesar_puzzle/presentation/pages/settings/settings_view.dart';
import 'package:caesar_puzzle/presentation/pages/settings/solution_indicator_difficulty_x.dart';
import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_entity_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_session_difficulty_x.dart';
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
  static const Duration _onboardingActionCompletionDelay = Duration(milliseconds: 320);

  late final PuzzleBloc _puzzleBloc;
  late final OnboardingBloc _onboardingBloc;
  PuzzleLocalSnapshot? _preOnboardingSnapshot;
  PuzzleLocalSnapshot? _tutorialBaseSnapshot;
  String? _tutorialPShapeId;
  OnboardingState _lastOnboardingState = const OnboardingState.hidden();
  int _onboardingCompletionDelayGeneration = 0;
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
    _onboardingCompletionDelayGeneration++;
    if (_isInitialized) {
      _puzzleBloc.close();
      _onboardingBloc.close();
    }
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= PuzzleScreen.wideScreenBreakpoint;
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
                    cs.moveIndex == ps.moveIndex + 1 && cs.isPieceInGrid(cs.moveHistory.last.pieceId),
                listener: (final context, final state) {
                  final settingsCubit = context.read<SettingsCubit>();
                  final settings = settingsCubit.state;
                  if (settings.unlockConfig && settings.autoLockConfig) {
                    settingsCubit.toggleUnlockConfig(false);
                  }
                },
              ),
              BlocListener<SettingsCubit, SettingsState>(
                listenWhen: (final previous, final current) => previous.solutionIndicator != current.solutionIndicator,
                listener: (final context, final state) {
                  context.read<PuzzleBloc>().markCurrentSessionDifficulty(state.solutionIndicator.sessionDifficulty);
                },
              ),
              BlocListener<PuzzleBloc, PuzzleState>(
                listenWhen: (final previous, final current) => _didCompleteDragOnboardingStep(previous, current),
                listener: (final context, final state) {
                  _completeCurrentOnboardingStepAfterActionAnimation(OnboardingStepId.dragPiece);
                },
              ),
              BlocListener<PuzzleBloc, PuzzleState>(
                listenWhen: (final previous, final current) => _didCompleteDrawOnboardingStep(previous, current),
                listener: (final context, final state) {
                  _completeCurrentOnboardingStepAfterActionAnimation(OnboardingStepId.drawPiece);
                },
              ),
              BlocListener<PuzzleBloc, PuzzleState>(
                listenWhen: (final previous, final current) => _didCompleteRotateOnboardingStep(previous, current),
                listener: (final context, final state) {
                  _completeCurrentOnboardingStepAfterActionAnimation(OnboardingStepId.rotatePiece);
                },
              ),
              BlocListener<PuzzleBloc, PuzzleState>(
                listenWhen: (final previous, final current) => _didCompleteFlipOnboardingStep(previous, current),
                listener: (final context, final state) {
                  _completeCurrentOnboardingStepAfterActionAnimation(OnboardingStepId.flipPiece);
                },
              ),
              BlocListener<OnboardingBloc, OnboardingState>(
                listener: (final context, final state) {
                  final previous = _lastOnboardingState;

                  if (!previous.isVisible && state.isVisible) {
                    _onboardingCompletionDelayGeneration++;
                    _preOnboardingSnapshot ??= buildPuzzleLocalSnapshot(_puzzleBloc.state);
                    _tutorialBaseSnapshot = null;
                    _tutorialPShapeId = null;
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    _puzzleBloc.add(PuzzleEvent.setPuzzleDate(_tutorialDate, onboarding: true));
                  } else if (previous.isVisible && !state.isVisible) {
                    _onboardingCompletionDelayGeneration++;
                    final settingsCubit = context.read<SettingsCubit>();
                    final selectedDifficulty = state.selectedDifficulty;
                    if (selectedDifficulty != null) {
                      settingsCubit.setSolutionIndicator(selectedDifficulty);
                    }
                    if (_didFinishOnboarding(previous)) {
                      settingsCubit.completeOnboarding(currentOnboardingVersion);
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
                    _onboardingCompletionDelayGeneration++;
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
                    !current.isDragging &&
                    _isTutorialBaseLayoutReady(current),
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
                        (ps.status == GameStatus.playing && cs.status == GameStatus.solvedByUser ||
                            ps.status == GameStatus.solvedByUser && ps.status != cs.status),
                    builder: (final BuildContext context, final PuzzleState state) =>
                        !state.isRestoredSolvedSession && state.status == GameStatus.solvedByUser
                        ? const ConfettiView()
                        : SizedBox.shrink(),
                  ),
                ),
                Positioned(
                  bottom: 24,
                  right: 12 + (isWideScreen ? PuzzleScreen.sidePanelWidth : 0),
                  child: PuzzleBottomControls(isSetupVisible: !isWideScreen),
                ),
                if (isWideScreen)
                  const Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: SizedBox(width: PuzzleScreen.sidePanelWidth, child: SettingsPanel()),
                  ),
                const OnboardingOverlay(),
              ],
            ),
          ),
        ),
        endDrawer: isWideScreen ? null : const SizedBox(width: PuzzleScreen.sidePanelWidth, child: SettingsPanel()),
      ),
    );
  }

  Future<void> _showSolvedDialog(final BuildContext context, final PuzzleState state) async {
    final spentSeconds = getIt<TimerService>().totalElapsedSeconds(
      startedAt: state.firstMoveAt,
      lastResumedAt: state.lastResumedAt,
      activeElapsedMs: state.activeElapsedMs,
      isPaused: state.isPaused,
    );
    final difficulty = context.read<PuzzleBloc>().currentSessionDifficulty;
    final configLabel = _configLabel(context, state);
    final configColor = state.isCustomConfig ? AppColors.current.customConfigAccent : null;
    final secondsText = '${spentSeconds % 60}'.padLeft(2, '0');
    final minutesText = '${spentSeconds ~/ 60}'.padLeft(2, '0');
    final spentTime = '$minutesText:$secondsText';
    final usedHints = state.gridPieces.where((final e) => !e.isUsersItem).length;
    await showDialog(
      context: context,
      builder: (final context) => PlatformAlertDialog(
        title: Text(S.of(context).solvedAlertTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(S.current.solvedAlertSubTitle),
            Text('${S.current.solvedAlertLevelLabel}: ${difficulty.stars} ${difficulty.label}'),
            Text(
              '${S.current.solvedAlertConfigLabel}:  $configLabel',
              style: state.isCustomConfig ? TextStyle(color: configColor, fontWeight: FontWeight.w600) : null,
            ),
            Text('${S.current.timeSpent}: $spentTime'),
            Text('${S.current.hintUsed}: $usedHints'),
          ],
        ),
        actions: [PlatformDialogAction(onPressed: () => Navigator.of(context).pop(), child: Text(S.of(context).ok))],
      ),
    );
  }

  String _configLabel(final BuildContext context, final PuzzleState state) =>
      state.isCustomConfig ? S.of(context).historyConfigCustom : S.of(context).historyConfigStandard;

  bool _didCompleteDragOnboardingStep(final PuzzleState previous, final PuzzleState current) {
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

  bool _didCompleteDrawOnboardingStep(final PuzzleState previous, final PuzzleState current) {
    final onboardingState = _onboardingBloc.state;
    if (!onboardingState.isVisible ||
        onboardingState.currentStep?.id != OnboardingStepId.drawPiece ||
        !onboardingState.isCurrentStepInteractionEnabled) {
      return false;
    }
    if (previous.drawnGroup == null ||
        current.drawnGroup != null ||
        current.moveIndex != previous.moveIndex + 1 ||
        current.moveHistory.isEmpty) {
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

  bool _didCompleteRotateOnboardingStep(final PuzzleState previous, final PuzzleState current) {
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

  bool _didCompleteFlipOnboardingStep(final PuzzleState previous, final PuzzleState current) {
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

  Future<void> _completeCurrentOnboardingStepAfterActionAnimation(final OnboardingStepId stepId) async {
    final generation = ++_onboardingCompletionDelayGeneration;
    await Future<void>.delayed(_onboardingActionCompletionDelay);
    if (!mounted || generation != _onboardingCompletionDelayGeneration) {
      return;
    }

    final onboardingState = _onboardingBloc.state;
    if (!onboardingState.isVisible ||
        onboardingState.currentStep?.id != stepId ||
        onboardingState.isCurrentStepComplete ||
        !onboardingState.isCurrentStepInteractionEnabled) {
      return;
    }
    _onboardingBloc.add(const CompleteCurrentOnboardingStep());
  }

  void _captureTutorialBaseSnapshot(final PuzzleState state) {
    if (!_isTutorialBaseLayoutReady(state)) {
      return;
    }
    _tutorialBaseSnapshot ??= buildPuzzleLocalSnapshot(state);
    _tutorialPShapeId ??= state.pieces
        .where((final piece) => piece.type == PieceType.pShape && !piece.isConfigItem)
        .map((final piece) => piece.id)
        .cast<String?>()
        .firstWhere((final id) => id != null, orElse: () => null);
  }

  bool _isTutorialBaseLayoutReady(final PuzzleState state) =>
      state.status == GameStatus.initialized &&
      !state.gridPieces.any((final piece) => !piece.isConfigItem) &&
      state.boardPieces.any((final piece) => piece.type == PieceType.pShape && !piece.isConfigItem);

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

    final pieces = baseSnapshot.pieces
        .map((final piece) {
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
        })
        .toList(growable: false);

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
          action: SnackBarAction(label: S.current.onboardingReplayAction, onPressed: _startOnboardingUpdate),
        ),
      );
    }
  }

  bool _didFinishOnboarding(final OnboardingState previous) =>
      previous.currentStepIndex == previous.steps.length - 1 && previous.canGoNext;

  void _startOnboardingUpdate() {
    final settingsCubit = context.read<SettingsCubit>();
    final completedVersion = settingsCubit.state.completedOnboardingVersion;
    settingsCubit.markOnboardingOffered(currentOnboardingVersion);
    _onboardingBloc.add(StartOnboarding(OnboardingMode.short, completedVersion: completedVersion));
  }
}
