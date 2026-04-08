import 'dart:async';

import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_bloc.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_step.dart';
import 'package:caesar_puzzle/presentation/onboarding/widgets/overlay/onboarding_overlay_primitives.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum DemoHandPhase { visible, hidden }

class OnboardingDragDemoScene extends StatefulWidget {
  const OnboardingDragDemoScene({super.key});

  @override
  State<OnboardingDragDemoScene> createState() => OnboardingDragDemoSceneState();
}

class OnboardingDragDemoSceneState extends State<OnboardingDragDemoScene> {
  DemoHandPhase phase = DemoHandPhase.visible;

  void hideHand() {
    if (!mounted || phase == DemoHandPhase.hidden) {
      return;
    }
    setState(() => phase = DemoHandPhase.hidden);
  }

  void showHand() {
    if (!mounted || phase == DemoHandPhase.visible) {
      return;
    }
    setState(() => phase = DemoHandPhase.visible);
  }

  @override
  Widget build(final BuildContext context) => Stack(
    children: [
      OnboardingDragDemoRunner(onReachedTarget: hideHand, onReturned: showHand),
      OnboardingDemoDragHandOverlay(phase: phase),
    ],
  );
}

class OnboardingDragDemoRunner extends StatefulWidget {
  const OnboardingDragDemoRunner({
    super.key,
    required this.onReachedTarget,
    required this.onReturned,
  });

  final VoidCallback onReachedTarget;
  final VoidCallback onReturned;

  @override
  State<OnboardingDragDemoRunner> createState() => OnboardingDragDemoRunnerState();
}

class OnboardingDragDemoRunnerState extends State<OnboardingDragDemoRunner> {
  Timer? timer;
  var isRunning = false;

  @override
  void initState() {
    super.initState();
    scheduleNextCycle(const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void scheduleNextCycle(final Duration delay) {
    timer?.cancel();
    timer = Timer(delay, runCycle);
  }

  Future<void> runCycle() async {
    if (!mounted || isRunning) {
      return;
    }
    final onboardingState = context.read<OnboardingBloc>().state;
    if (!onboardingState.isVisible ||
        onboardingState.currentStep?.id != OnboardingStepId.dragPiece ||
        onboardingState.isCurrentStepInteractionEnabled) {
      return;
    }

    final puzzleBloc = context.read<PuzzleBloc>();
    final puzzleState = puzzleBloc.state;
    final demoPiece = puzzleState.boardPieces.firstWhere(
      (final piece) => piece.type == PieceType.pShape && !piece.isConfigItem,
      orElse: () => puzzleState.pieces.first,
    );

    if (demoPiece.type != PieceType.pShape || demoPiece.isConfigItem) {
      scheduleNextCycle(const Duration(milliseconds: 1600));
      return;
    }

    final targetTopLeft = Offset(
      puzzleState.gridConfig.origin.dx + 3 * puzzleState.gridConfig.cellSize,
      puzzleState.gridConfig.origin.dy,
    );
    final dragAnchor = demoPiece.position + demoPiece.centerPoint;
    final targetDragPoint = targetTopLeft + demoPiece.centerPoint;

    isRunning = true;
    puzzleBloc.add(PuzzleEvent.onPanStart(dragAnchor));
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) {
      return;
    }
    puzzleBloc.add(PuzzleEvent.onPanUpdate(targetDragPoint));
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) {
      return;
    }
    widget.onReachedTarget();
    puzzleBloc.add(PuzzleEvent.onPanEnd(Offset.zero));
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) {
      return;
    }
    puzzleBloc.add(PuzzleEvent.undo());
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted) {
      return;
    }
    widget.onReturned();
    isRunning = false;
    scheduleNextCycle(const Duration(milliseconds: 1600));
  }

  @override
  Widget build(final BuildContext context) => BlocBuilder<PuzzleBloc, PuzzleState>(
    builder: (final context, final puzzleState) {
      final piece = puzzleState.boardPieces
          .where((final currentPiece) => currentPiece.type == PieceType.pShape && !currentPiece.isConfigItem)
          .cast<PuzzlePieceUI?>()
          .firstWhere((final currentPiece) => currentPiece != null, orElse: () => null);
      if (piece == null) {
        return const SizedBox.shrink();
      }
      return OnboardingPieceContourHighlight(piece: piece);
    },
  );
}

class OnboardingDemoDragHandOverlay extends StatefulWidget {
  const OnboardingDemoDragHandOverlay({
    super.key,
    required this.phase,
  });

  final DemoHandPhase phase;

  @override
  State<OnboardingDemoDragHandOverlay> createState() => OnboardingDemoDragHandOverlayState();
}

class OnboardingDemoDragHandOverlayState extends State<OnboardingDemoDragHandOverlay> {
  static const Offset handOffset = Offset(-14, -18);
  static const Duration moveDuration = Duration(milliseconds: 220);
  static const Duration visibilityDuration = Duration(milliseconds: 220);
  static const double handBoxSize = 40;
  static const double handVisualSize = 34;

  @override
  Widget build(final BuildContext context) => BlocBuilder<PuzzleBloc, PuzzleState>(
    builder: (final context, final puzzleState) {
      final pShape = puzzleState.pieces
          .where((final piece) => piece.type == PieceType.pShape && !piece.isConfigItem)
          .cast<PuzzlePieceUI?>()
          .firstWhere((final piece) => piece != null, orElse: () => null);
      if (pShape == null) {
        return const SizedBox.shrink();
      }

      final anchor = pShape.position + pShape.centerPoint + handOffset;
      return AnimatedPositioned(
        duration: moveDuration,
        curve: Curves.easeInOut,
        left: anchor.dx,
        top: anchor.dy,
        child: IgnorePointer(
          child: SizedBox(
            width: handBoxSize,
            height: handBoxSize,
            child: Center(
              child: AnimatedOpacity(
                duration: visibilityDuration,
                curve: widget.phase == DemoHandPhase.visible ? Curves.easeOutCubic : Curves.easeInCubic,
                opacity: widget.phase == DemoHandPhase.visible ? 1 : 0,
                child: AnimatedSize(
                  duration: visibilityDuration,
                  curve: widget.phase == DemoHandPhase.visible ? Curves.easeOutBack : Curves.easeInCubic,
                  child: SizedBox.square(
                    dimension: widget.phase == DemoHandPhase.visible ? handVisualSize : 0,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.92, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeInOut,
                      builder: (final context, final scale, final child) =>
                          Transform.scale(scale: scale, child: child),
                      child: const OnboardingDemoHandBubble(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
