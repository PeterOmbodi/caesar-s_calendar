import 'dart:async';

import 'package:caesar_puzzle/application/contracts/board_layout_repository.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/puzzle_history_use_case.dart';
import 'package:caesar_puzzle/application/solve_puzzle_use_case.dart';
import 'package:caesar_puzzle/core/services/timer_service.dart';
import 'package:caesar_puzzle/domain/services/calendar_cells.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/injection.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/chrome/game_chrome.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/layouts/board_layouts_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/layouts/board_layouts_sheet.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/puzzle_haptics.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/puzzle_settings_panel_controller.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/start_card.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/confetti_view.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/puzzle_header.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/puzzle_toolbar.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/puzzle_view.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/cubit_settings_query.dart';
import 'package:caesar_puzzle/presentation/pages/settings/settings_view.dart';
import 'package:caesar_puzzle/presentation/pages/settings/solution_indicator_difficulty_x.dart';
import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_entity_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_grid_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_session_difficulty_x.dart';
import 'package:caesar_puzzle/presentation/widgets/coach_mark.dart';
import 'package:caesar_puzzle/presentation/widgets/max_width.dart';
import 'package:caesar_puzzle/presentation/widgets/measure_size.dart';
import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import 'bloc/puzzle_bloc.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  static const sidePanelWidth = 340.0;
  static const maxGameWidth = 1600.0;

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  // Header and toolbar have fixed slots; larger text would not fit them.
  static const double _maxChromeTextScale = 1.3;
  static const int _introVersion = 3;

  late final PuzzleBloc _puzzleBloc;
  late final BoardLayoutsCubit _layoutsCubit;
  late final StreamSubscription<PuzzleState> _feedbackSubscription;
  PuzzleSettingsPanelController _settingsPanelController = const PuzzleSettingsPanelController();
  final _boardKey = GlobalKey();
  var _isInitialized = false;
  var _isStartCardOpen = false;
  var _isPieceTipRequested = false;
  double _headerHeight = 0;

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
    _layoutsCubit = BoardLayoutsCubit(getIt<BoardLayoutRepository>());
    final settings = context.read<SettingsCubit>();
    var previous = _puzzleBloc.state;
    _feedbackSubscription = _puzzleBloc.stream.listen((final next) {
      final haptic = hapticFor(previous, next);
      previous = next;
      if (haptic == null) {
        return;
      }
      if (settings.state.haptics) {
        playHaptic(haptic);
      }
      if (settings.state.sounds) {
        playClick();
      }
    });
    _isInitialized = true;
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _puzzleBloc.close();
      _feedbackSubscription.cancel();
      _layoutsCubit.close();
    }
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final settingsDocked = ScreenSpec.of(context).settingsDocked;
    _syncSettingsPanelWithWidth(settingsDocked);
    final gameplayInsets = _settingsPanelController.gameplayInsets(
      isWideScreen: settingsDocked,
      sidePanelWidth: PuzzleScreen.sidePanelWidth,
    );
    return MultiBlocProvider(
      providers: [
        BlocProvider<PuzzleBloc>.value(value: _puzzleBloc),
        BlocProvider<BoardLayoutsCubit>.value(value: _layoutsCubit),
      ],
      child: Scaffold(
        body: _GameBackground(
          colors: GameColors.of(context),
          child: SafeArea(
            child: MultiBlocListener(
              listeners: [
                BlocListener<PuzzleBloc, PuzzleState>(
                  listenWhen: (final ps, final cs) =>
                      ps.status == GameStatus.initializing && cs.status != GameStatus.initializing,
                  listener: (final context, final state) => _maybeShowStartCard(),
                ),
                BlocListener<PuzzleBloc, PuzzleState>(
                  listenWhen: (final ps, final cs) =>
                      !_isPieceTipRequested &&
                      cs.selectedPieceId != null &&
                      !cs.isDragging &&
                      !cs.isEditingLayout &&
                      (ps.selectedPieceId != cs.selectedPieceId || ps.isDragging),
                  listener: (final context, final state) => _showPieceTip(),
                ),
                BlocListener<SettingsCubit, SettingsState>(
                  listenWhen: (final previous, final current) => previous.solutionIndicator != current.solutionIndicator,
                  listener: (final context, final state) {
                    context.read<PuzzleBloc>().markCurrentSessionDifficulty(state.solutionIndicator.sessionDifficulty);
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
                    AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    left: gameplayInsets.left,
                    top: 0,
                    right: gameplayInsets.right,
                    bottom: 0,
                    child: PuzzleView(key: _boardKey, headerHeight: _headerHeight),
                  ),
                  BlocSelector<PuzzleBloc, PuzzleState, double>(
                    selector: (final state) => state.boardConfig.getBounds.left,
                    builder: (final context, final trayLeft) {
                      // Phone landscape: the header sits beside the board, above the tray.
                      final spec = ScreenSpec.of(context);
                      final beside = spec.window == WindowClass.compact && spec.isLandscape;
                      final reserved = GameChrome.reservedInsets(context);
                      // No animation on phones: a squeezed header wraps and reports a huge height.
                      return AnimatedPositioned(
                        duration: spec.window == WindowClass.compact ? Duration.zero : const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        left: gameplayInsets.left + (beside ? trayLeft - 16 : reserved.left),
                        top: 0,
                        right: gameplayInsets.right + (beside ? reserved.right : 0),
                        child: MeasureSize(
                          onChange: (final size) {
                            if (mounted && size.height != _headerHeight) {
                              setState(() => _headerHeight = size.height);
                            }
                          },
                          child: Builder(
                            builder: (final headerContext) => MediaQuery.withClampedTextScaling(
                              maxScaleFactor: _maxChromeTextScale,
                              child: PuzzleHeader(
                                onLayoutsPressed: () {
                                  if (!_puzzleBloc.state.isEditingLayout) {
                                    showBoardLayoutsSheet(headerContext);
                                  }
                                },
                                onSettingsPressed: () => _openSettings(headerContext, settingsDocked),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: BlocBuilder<PuzzleBloc, PuzzleState>(
                      buildWhen: (final ps, final cs) =>
                          !cs.isRestoredSolvedSession &&
                          (ps.status == GameStatus.playing && cs.status == GameStatus.solvedByUser ||
                              ps.status == GameStatus.solvedByUser && ps.status != cs.status),
                      builder: (final BuildContext context, final PuzzleState state) =>
                          !state.isRestoredSolvedSession &&
                              state.status == GameStatus.solvedByUser &&
                              !MediaQuery.disableAnimationsOf(context)
                          ? const ConfettiView()
                          : SizedBox.shrink(),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    left: gameplayInsets.left,
                    top: 0,
                    right: gameplayInsets.right,
                    bottom: 0,
                    child: MediaQuery.withClampedTextScaling(
                      maxScaleFactor: _maxChromeTextScale,
                      child: const PuzzleToolbar(),
                    ),
                  ),
                  if (settingsDocked)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      right: _settingsPanelController.isInlinePanelVisible ? 0 : -PuzzleScreen.sidePanelWidth,
                      top: 0,
                      bottom: 0,
                      child: const SizedBox(width: PuzzleScreen.sidePanelWidth, child: SettingsPanel()),
                    ),
                ],
              ),
            ),
          ),
        ),
        endDrawer: settingsDocked ? null : const SizedBox(width: PuzzleScreen.sidePanelWidth, child: SettingsPanel()),
      ),
    );
  }

  void _syncSettingsPanelWithWidth(final bool isWideScreen) {
    final next = _settingsPanelController.forScreenWidth(isWideScreen: isWideScreen);
    if (next == _settingsPanelController) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (mounted) {
        setState(() => _settingsPanelController = next);
      }
    });
  }

  void _openSettings(final BuildContext context, final bool isWideScreen) {
    if (!isWideScreen) {
      Scaffold.of(context).openEndDrawer();
      return;
    }
    setState(() {
      _settingsPanelController = _settingsPanelController.toggle(isWideScreen: true);
    });
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
    await showAdaptiveDialog(
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

  RenderBox? get _boardBox => _boardKey.currentContext?.findRenderObject() as RenderBox?;

  Future<void> _maybeShowStartCard() async {
    final settings = context.read<SettingsCubit>();
    if (_isStartCardOpen || settings.state.completedOnboardingVersion > 0) {
      return;
    }
    _isStartCardOpen = true;
    // Let the pieces settle first.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) {
      _isStartCardOpen = false;
      return;
    }
    final level = await showStartCard(
      context,
      dateCells: _dateCellRects,
      boardChanges: _puzzleBloc.stream,
      initial: settings.state.solutionIndicator,
    );
    settings
      ..setSolutionIndicator(level)
      ..completeOnboarding(_introVersion);
    _isStartCardOpen = false;
  }

  List<Rect> _dateCellRects() {
    final box = _boardBox;
    if (box == null || !box.hasSize) {
      return const [];
    }
    final state = _puzzleBloc.state;
    final grid = state.gridConfig;
    final cells = targetCells(
      rows: PuzzleBloc.gridRows,
      columns: PuzzleBloc.gridColumns,
      blocked: state.blockedCells,
      date: state.selectedDate,
    );
    return [for (final cell in cells) box.localToGlobal(grid.cellTopLeft(cell)) & Size.square(grid.cellSize)];
  }

  Future<void> _showPieceTip() async {
    _isPieceTipRequested = true;
    // Wait out a possible double tap.
    await Future<void>.delayed(kDoubleTapTimeout);
    final piece = _puzzleBloc.state.selectedPiece;
    final box = _boardBox;
    if (!mounted || box == null || piece == null || piece.isConfigItem || _puzzleBloc.state.isDragging) {
      _isPieceTipRequested = false;
      return;
    }
    await CoachMark.showOnce(
      context: context,
      storageKey: 'tip_seen_selected_piece',
      anchor: piece.getTransformedPath().getBounds().shift(box.localToGlobal(Offset.zero)),
      title: S.current.tipPieceTitle,
      message: S.current.tipPieceMessage,
      actionLabel: S.current.ok,
      canCancel: false,
    );
  }
}

class _GameBackground extends StatelessWidget {
  const _GameBackground({required this.colors, required this.child});

  final GameColors colors;
  final Widget child;

  @override
  Widget build(final BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [colors.backgroundTop, colors.background],
        stops: const [0, 0.45],
      ),
    ),
    // On wide monitors the game stays together in the middle; the background fills the window.
    child: MaxWidth(maxWidth: PuzzleScreen.maxGameWidth, child: child),
  );
}
