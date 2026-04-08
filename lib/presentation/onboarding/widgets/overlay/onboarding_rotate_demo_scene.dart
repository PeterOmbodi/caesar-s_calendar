import 'dart:async';

import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/onboarding/widgets/overlay/onboarding_overlay_primitives.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:flutter/material.dart';

class OnboardingRotateDemoScene extends StatefulWidget {
  const OnboardingRotateDemoScene({
    super.key,
    required this.piece,
  });

  final PuzzlePieceUI piece;

  @override
  State<OnboardingRotateDemoScene> createState() => OnboardingRotateDemoSceneState();
}

class OnboardingRotateDemoSceneState extends State<OnboardingRotateDemoScene>
    with SingleTickerProviderStateMixin {
  static const Offset tapOffset = Offset(6, -18);
  static const Duration tapDuration = Duration(milliseconds: 240);

  late final AnimationController controller;
  late final Animation<double> rotation;
  late final Animation<double> highlightOpacity;
  late final Animation<double> handOpacity;
  Timer? loopTimer;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
    rotation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 18),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: PuzzleBloc.rotationStep).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 22,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(PuzzleBloc.rotationStep), weight: 16),
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 0.0001),
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 20),
    ]).animate(controller);
    highlightOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 40),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 18,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 24),
    ]).animate(controller);
    handOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 14),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 42),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 24),
    ]).animate(controller);
    startLoop();
  }

  @override
  void didUpdateWidget(covariant final OnboardingRotateDemoScene oldWidget) {
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
    loopTimer = Timer(const Duration(milliseconds: 1820), () {
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
      final piece = widget.piece.copyWith(rotation: widget.piece.rotation + rotation.value);
      final handAnchor = widget.piece.position + widget.piece.centerPoint + tapOffset;
      return Stack(
        children: [
          OnboardingPieceContourHighlight(piece: piece, opacity: highlightOpacity.value),
          Positioned(
            left: handAnchor.dx,
            top: handAnchor.dy,
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: tapDuration,
                opacity: handOpacity.value,
                curve: Curves.easeInOut,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1, end: controller.value < 0.16 ? 0.84 : 1),
                  duration: tapDuration,
                  curve: Curves.easeInOut,
                  builder: (final context, final scale, final child) =>
                      Transform.scale(scale: scale, child: child),
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
