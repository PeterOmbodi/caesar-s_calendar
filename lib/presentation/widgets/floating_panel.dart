import 'dart:async';

import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/presentation/pages/history/history_screen.dart';
import 'package:caesar_puzzle/presentation/pages/history/models/history_screen_result.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/puzzle_screen.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:caesar_puzzle/presentation/widgets/how_to_play_hint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_flip_flap/flutter_flip_flap.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../../generated/l10n.dart';

class FloatingPanel extends StatefulWidget {
  const FloatingPanel({super.key, required this.children});

  static const double widgetSpacing = 0.2;
  static const double panelElevation = 8.0;
  static const double panelBorderRadius = 16.0;
  static const double panelAlpha = 0.5;
  static const double itemWidth = 48.0;
  static const double itemHeight = 40.0;
  static const double itemPadding = 4.0;
  static const double verticalPadding = 8.0;
  static const double horizontalPadding = 4.0;
  static const double screenMargin = 24.0;

  static const Duration openAnimationDelay = Duration(milliseconds: 80);
  static const Duration closeAnimationDelay = Duration(milliseconds: 80);
  static const Duration animationDuration = Duration(milliseconds: 100);
  static const Duration switcherDuration = Duration(milliseconds: 300);
  static const double swipeVelocityThreshold = 300;

  final List<Widget> children;

  @override
  FloatingPanelState createState() => FloatingPanelState();
}

class FloatingPanelState extends State<FloatingPanel> with TickerProviderStateMixin {
  bool _isPanelOpen = false;
  int _visibleChildren = 0;
  int _animationId = 0;
  bool _isPanelStateInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isPanelStateInitialized) {
      return;
    }
    final isWideScreen = MediaQuery.of(context).size.width >= PuzzleScreen.wideScreenBreakpoint - PuzzleScreen.sidePanelWidth;
    _isPanelOpen = isWideScreen;
    _visibleChildren = isWideScreen ? widget.children.length : 0;
    _isPanelStateInitialized = true;
  }

  @override
  void didUpdateWidget(final FloatingPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_visibleChildren > widget.children.length) {
      setState(() => _visibleChildren = widget.children.length);
    }
  }

  Future<void> _togglePanel() async {
    if (_isPanelOpen) {
      await _animateClose();
    } else {
      await _animateOpen();
    }
  }

  Future<void> _animateOpen() async {
    final id = ++_animationId;
    setState(() => _isPanelOpen = true);

    for (var i = _visibleChildren; i < widget.children.length; i++) {
      if (!mounted || id != _animationId) return;
      setState(() => _visibleChildren = i + 1);
      await Future<void>.delayed(FloatingPanel.openAnimationDelay);
    }
  }

  Future<void> _animateClose() async {
    final id = ++_animationId;
    setState(() => _isPanelOpen = false);

    for (var i = _visibleChildren; i > 0; i--) {
      if (!mounted || id != _animationId) return;
      setState(() => _visibleChildren = i - 1);
      await Future<void>.delayed(FloatingPanel.closeAnimationDelay);
    }
  }

  Future<void> _showHowToPlayDialog(final double viewWidth) async {
    await showDialog(
      context: context,
      builder: (final context) => PlatformAlertDialog(
        material: (final context, final platform) =>
            MaterialAlertDialogData(insetPadding: EdgeInsets.symmetric(horizontal: viewWidth < 600 ? 12 : 40)),
        title: Text(S.current.howToPlayTitle),
        content: const HowToPlayHint(),
        actions: [PlatformDialogAction(onPressed: () => Navigator.of(context).pop(), child: Text(S.current.ok))],
      ),
    );
  }

  Future<void> _showHistory() async {
    final result = await Navigator.of(context).push<HistoryScreenResult>(
      PageRouteBuilder<HistoryScreenResult>(
        pageBuilder: (final context, final animation, final secondaryAnimation) => const HistoryScreen(),
        transitionsBuilder: (final context, final animation, final secondaryAnimation, final child) {
          final offsetAnimation = animation.drive(
            Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic)),
          );
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    switch (result) {
      case ResumeHistorySessionResult(:final session):
        final settingsCubit = context.read<SettingsCubit>();
        final currentDifficulty = _difficultyFromSettings(settingsCubit.state.solutionIndicator);
        if (currentDifficulty != session.difficulty) {
          final shouldContinue = await _showDifficultyMismatchDialog(
            sessionDifficulty: session.difficulty,
            currentDifficulty: currentDifficulty,
          );
          if (shouldContinue != true || !mounted) {
            return;
          }
          settingsCubit.setSolutionIndicator(
            session.difficulty == PuzzleSessionDifficulty.easy
                ? SolutionIndicator.countSolutions
                : SolutionIndicator.none,
          );
        }
        if (!mounted) {
          return;
        }
        context.read<PuzzleBloc>().add(PuzzleEvent.restoreSession(session));
      case StartPuzzleForDateHistoryResult(:final date):
        context.read<PuzzleBloc>().add(PuzzleEvent.setPuzzleDate(date));
    }
  }

  PuzzleSessionDifficulty _difficultyFromSettings(final SolutionIndicator indicator) =>
      indicator == SolutionIndicator.none ? PuzzleSessionDifficulty.hard : PuzzleSessionDifficulty.easy;

  Future<bool?> _showDifficultyMismatchDialog({
    required final PuzzleSessionDifficulty sessionDifficulty,
    required final PuzzleSessionDifficulty currentDifficulty,
  }) => showDialog<bool>(
    context: context,
    builder: (final dialogContext) => PlatformAlertDialog(
      title: Text(S.current.historyDifficultyMismatchTitle),
      content: Text(
        S.current.historyDifficultyMismatchContent(
          _difficultyLabel(sessionDifficulty),
          _difficultyLabel(currentDifficulty),
        ),
      ),
      actions: [
        PlatformDialogAction(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(S.current.historySessionDialogCancel),
        ),
        PlatformDialogAction(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(S.current.historyDifficultyMismatchContinue),
        ),
      ],
    ),
  );

  String _difficultyLabel(final PuzzleSessionDifficulty difficulty) =>
      difficulty == PuzzleSessionDifficulty.hard
      ? S.current.historyDifficultyHard
      : S.current.historyDifficultyEasy;

  @override
  Widget build(final BuildContext context) {
    final viewWidth = MediaQuery.of(context).size.width;
    final isWideScreen = viewWidth >= PuzzleScreen.wideScreenBreakpoint - PuzzleScreen.sidePanelWidth;
    final showHistoryButton = !_isPanelOpen || isWideScreen;
    return GestureDetector(
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: viewWidth - FloatingPanel.screenMargin),
        child: Material(
          elevation: FloatingPanel.panelElevation,
          borderRadius: BorderRadius.circular(FloatingPanel.panelBorderRadius),
          color: AppColors.current.primary.withValues(alpha: FloatingPanel.panelAlpha),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: FloatingPanel.verticalPadding,
              horizontal: FloatingPanel.horizontalPadding,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: AnimatedSize(
                    duration: FloatingPanel.switcherDuration,
                    curve: Curves.easeInOut,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height: FloatingPanel.itemHeight,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(widget.children.length + 1, (final i) {
                            final isFirst = i == 0;
                            final item = isFirst
                                ? Row(
                                  children: [
                                    if (showHistoryButton)
                                      _PanelItemShell(
                                        child: IconButton(
                                          icon: const Icon(Icons.history),
                                          onPressed: _showHistory,
                                          tooltip: S.current.historyTitle,
                                        ),
                                      ),
                                    _PanelItemShell(
                                      child: IconButton(
                                        icon: const Icon(Icons.info_outline_rounded),
                                        onPressed: () => _showHowToPlayDialog(viewWidth),
                                        tooltip: S.current.howToPlayTitle,
                                      ),
                                    ),
                                  ],
                                )
                                : _AnimatedPanelItem(
                                    index: i,
                                    isVisible: i <= _visibleChildren,
                                    child: widget.children[i - 1],
                                  );
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: FloatingPanel.widgetSpacing),
                              child: item,
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
                FlipFlapDisplay(
                  items: [
                    FlipFlapWidgetItem.flip(
                      flipAxis: Axis.horizontal,
                      duration: const Duration(milliseconds: 800),
                      child: IconButton(
                        key: ValueKey(_isPanelOpen),
                        icon: Icon(_isPanelOpen ? Icons.close : Icons.menu),
                        onPressed: _togglePanel,
                        tooltip: _isPanelOpen ? S.current.hideControls : S.current.showControls,
                      ),
                    ),
                  ],
                  unitDecoration: const BoxDecoration(color: Colors.transparent),
                  unitConstraints: BoxConstraints.tightFor(
                    height: FloatingPanel.itemHeight,
                    width: FloatingPanel.itemHeight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleHorizontalDragEnd(final DragEndDetails details) {
    final velocity = details.primaryVelocity;
    if (velocity == null || velocity.abs() < FloatingPanel.swipeVelocityThreshold) {
      return;
    }
    if (velocity < 0 && !_isPanelOpen) {
      unawaited(_animateOpen());
    } else if (velocity > 0 && _isPanelOpen) {
      unawaited(_animateClose());
    }
  }
}

class _AnimatedPanelItem extends StatelessWidget {
  const _AnimatedPanelItem({required this.index, required this.isVisible, required this.child});

  final int index;
  final bool isVisible;
  final Widget child;

  @override
  Widget build(final BuildContext context) => AnimatedSize(
    duration: FloatingPanel.animationDuration,
    curve: Curves.easeInOut,
    alignment: Alignment.centerLeft,
    child: AnimatedSwitcher(
      duration: FloatingPanel.animationDuration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (final widgetChild, final animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: widgetChild),
      ),
      child: isVisible
          ? SizedBox(
              key: ValueKey('floating-panel-item-$index-visible'),
              width: FloatingPanel.itemWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: FloatingPanel.itemPadding),
                child: child,
              ),
            )
          : SizedBox(key: ValueKey('floating-panel-item-$index-hidden'), width: 0),
    ),
  );
}

class _PanelItemShell extends StatelessWidget {
  const _PanelItemShell({required this.child});

  final Widget child;

  @override
  Widget build(final BuildContext context) => SizedBox(
    width: FloatingPanel.itemWidth,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: FloatingPanel.itemPadding),
      child: child,
    ),
  );
}
