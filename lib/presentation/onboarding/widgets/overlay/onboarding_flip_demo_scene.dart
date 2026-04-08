import 'dart:async';

import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/onboarding/widgets/overlay/onboarding_overlay_primitives.dart';
import 'package:flutter/material.dart';

class OnboardingFlipDemoScene extends StatefulWidget {
  const OnboardingFlipDemoScene({
    super.key,
    required this.piece,
    required this.cellSize,
  });

  final PuzzlePieceUI piece;
  final double cellSize;

  @override
  State<OnboardingFlipDemoScene> createState() => OnboardingFlipDemoSceneState();
}

class OnboardingFlipDemoSceneState extends State<OnboardingFlipDemoScene>
    with SingleTickerProviderStateMixin {
  static const Offset tapOffset = Offset(6, -18);
  static const Duration tapDuration = Duration(milliseconds: 180);

  late final AnimationController controller;
  late final Animation<double> flipScale;
  late final Animation<double> highlightOpacity;
  late final Animation<double> handOpacity;
  late final Animation<double> handScale;
  Timer? loopTimer;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1540));
    flipScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 28),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0.001).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 14,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.001, end: -1).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 14,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(-1), weight: 16),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 0.0001),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 28),
    ]).animate(controller);
    highlightOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 56),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 14,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 14,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 16),
    ]).animate(controller);
    handOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 10),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 6,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 6,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 6),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 6,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 6,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 10),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 8,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 42),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 8,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 6),
    ]).animate(controller);
    handScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 6),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0.84).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.84, end: 1).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 5,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 6),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0.84).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.84, end: 1).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 5,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 4),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0.84).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.84, end: 1).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 5,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 70),
    ]).animate(controller);
    startLoop();
  }

  @override
  void didUpdateWidget(covariant final OnboardingFlipDemoScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.piece != widget.piece) {
      controller
        ..stop()
        ..reset();
      startLoop();
    }
  }

  @override
  void dispose() {
    loopTimer?.cancel();
    controller.dispose();
    super.dispose();
  }

  void startLoop() {
    loopTimer?.cancel();
    controller
      ..stop()
      ..reset()
      ..forward();
    loopTimer = Timer(const Duration(milliseconds: 2080), () {
      if (!mounted) {
        return;
      }
      startLoop();
    });
  }

  @override
  Widget build(final BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (final context, final child) {
      final handAnchor = widget.piece.position +
          widget.piece.centerPoint +
          tapOffset -
          Offset(widget.cellSize / 2, 0);
      return Stack(
        children: [
          OnboardingPieceContourFlipHighlight(
            piece: widget.piece,
            scaleX: flipScale.value,
            opacity: highlightOpacity.value,
          ),
          Positioned(
            left: handAnchor.dx,
            top: handAnchor.dy,
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: tapDuration,
                opacity: handOpacity.value,
                curve: Curves.easeInOut,
                child: Transform.scale(
                  scale: handScale.value,
                  child: const OnboardingDemoHandBubble(),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
