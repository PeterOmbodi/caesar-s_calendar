import 'dart:async';

import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_bloc.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_event.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_state.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_step.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_step_policy.dart';
import 'package:caesar_puzzle/presentation/onboarding/utils/onboarding_board_target_resolver.dart';
import 'package:caesar_puzzle/presentation/onboarding/widgets/overlay/onboarding_card.dart';
import 'package:caesar_puzzle/presentation/onboarding/widgets/overlay/onboarding_drag_demo_scene.dart';
import 'package:caesar_puzzle/presentation/onboarding/widgets/overlay/onboarding_flip_demo_scene.dart';
import 'package:caesar_puzzle/presentation/onboarding/widgets/overlay/onboarding_overlay_helpers.dart';
import 'package:caesar_puzzle/presentation/onboarding/widgets/overlay/onboarding_overlay_primitives.dart';
import 'package:caesar_puzzle/presentation/onboarding/widgets/overlay/onboarding_rotate_demo_scene.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_entity_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OnboardingOverlay extends StatefulWidget {
  const OnboardingOverlay({super.key});

  @override
  State<OnboardingOverlay> createState() => OnboardingOverlayState();
}

class OnboardingOverlayState extends State<OnboardingOverlay> {
  Rect? cachedDragInteractionHole;
  OnboardingStepId? pendingInteractionStepId;

  @override
  Widget build(final BuildContext context) => BlocBuilder<OnboardingBloc, OnboardingState>(
    builder: (final context, final onboardingState) {
      if (!onboardingState.isVisible || onboardingState.currentStep == null) {
        cachedDragInteractionHole = null;
        return const SizedBox.shrink();
      }

      return BlocBuilder<PuzzleBloc, PuzzleState>(
        builder: (final context, final puzzleState) {
          final step = onboardingState.currentStep!;
          final highlightedRects = step.highlightedLabelIndices
              .map((final index) => resolveLabelCellRect(puzzleState, index))
              .whereType<Rect>()
              .toList(growable: true);
          if (step.highlightGrid) {
            highlightedRects.add(puzzleState.gridConfig.getBounds);
          }

          final spotlightHoles = step.id == OnboardingStepId.dateGoal
              ? highlightedRects.map((final rect) => rect.inflate(6)).toList(growable: false)
              : const <Rect>[];

          if (step.id == OnboardingStepId.dragPiece &&
              onboardingState.isCurrentStepInteractionEnabled) {
            cachedDragInteractionHole ??= buildDragInteractionHole(puzzleState);
          } else {
            cachedDragInteractionHole = null;
          }

          final interactionHole = switch (step.id) {
            OnboardingStepId.dragPiece when onboardingState.isCurrentStepInteractionEnabled => cachedDragInteractionHole,
            OnboardingStepId.rotatePiece when onboardingState.isCurrentStepInteractionEnabled => puzzleState.gridConfig.getBounds.inflate(8),
            OnboardingStepId.flipPiece when onboardingState.isCurrentStepInteractionEnabled => puzzleState.gridConfig.getBounds.inflate(8),
            _ => null,
          };

          final targetHighlightPiece = step.id == OnboardingStepId.dragPiece &&
                  !onboardingState.isCurrentStepInteractionEnabled &&
                  !onboardingState.isCurrentStepComplete
              ? buildDragDemoTargetPiece(puzzleState)
              : null;
          final rotatePiece = step.id == OnboardingStepId.rotatePiece
              ? puzzleState.gridPieces
                    .where((final piece) => piece.type == PieceType.pShape && !piece.isConfigItem)
                    .cast<PuzzlePieceUI?>()
                    .firstWhere((final piece) => piece != null, orElse: () => null)
              : null;
          final flipPiece = step.id == OnboardingStepId.flipPiece
              ? puzzleState.gridPieces
                    .where((final piece) => piece.type == PieceType.pShape && !piece.isConfigItem)
                    .cast<PuzzlePieceUI?>()
                    .firstWhere((final piece) => piece != null, orElse: () => null)
              : null;
          final isPreparingInteraction = pendingInteractionStepId == step.id;
          final canTapToTry = step.id.supportsTry &&
              !isPreparingInteraction &&
              !onboardingState.isCurrentStepInteractionEnabled &&
              !onboardingState.isCurrentStepComplete;

          return Positioned.fill(
            child: Stack(
              children: [
                OnboardingOverlayDimmer(
                  interactionHole: interactionHole,
                  spotlightHoles: spotlightHoles,
                ),
                if (canTapToTry)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) => startCurrentStepInteraction(step),
                    ),
                  ),
                ...highlightedRects.map(
                  (final rect) => OnboardingHighlightFrame(
                    rect: rect.inflate(6),
                    showGlow: step.id != OnboardingStepId.dateGoal,
                  ),
                ),
                if (targetHighlightPiece != null)
                  OnboardingPieceContourHighlight(piece: targetHighlightPiece),
                if (step.id == OnboardingStepId.dragPiece &&
                    !onboardingState.isCurrentStepInteractionEnabled &&
                    !isPreparingInteraction)
                  const OnboardingDragDemoScene(),
                if (step.id == OnboardingStepId.rotatePiece && rotatePiece != null)
                  !onboardingState.isCurrentStepInteractionEnabled &&
                          !onboardingState.isCurrentStepComplete &&
                          !isPreparingInteraction
                      ? OnboardingRotateDemoScene(piece: rotatePiece)
                      : const SizedBox.shrink(),
                if (step.id == OnboardingStepId.flipPiece && flipPiece != null)
                  !onboardingState.isCurrentStepInteractionEnabled &&
                          !onboardingState.isCurrentStepComplete &&
                          !isPreparingInteraction
                      ? OnboardingFlipDemoScene(
                          piece: flipPiece,
                          cellSize: puzzleState.gridConfig.cellSize,
                        )
                      : const SizedBox.shrink(),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    minimum: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: OnboardingCard(
                      step: step,
                      state: onboardingState,
                      onTryPressed: step.id.supportsTry &&
                              !onboardingState.isCurrentStepInteractionEnabled &&
                              !onboardingState.isCurrentStepComplete
                          ? () => startCurrentStepInteraction(step)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  Future<void> startCurrentStepInteraction(final OnboardingStep step) async {
    if (pendingInteractionStepId != null) {
      return;
    }

    setState(() => pendingInteractionStepId = step.id);
    try {
      if (step.id == OnboardingStepId.dragPiece) {
        final puzzleBloc = context.read<PuzzleBloc>();
        final pShape = findOnboardingPShape(puzzleBloc.state);
        if (pShape.type == PieceType.pShape && pShape.placeZone == PlaceZone.grid) {
          puzzleBloc.add(PuzzleEvent.undo());
          await puzzleBloc.stream.firstWhere((final state) {
            final currentPShape = findOnboardingPShape(state);
            return currentPShape.type == PieceType.pShape &&
                currentPShape.placeZone == PlaceZone.board &&
                !state.isDragging;
          }).timeout(const Duration(milliseconds: 1200));
        }
      }
      if (!mounted) {
        return;
      }
      context.read<OnboardingBloc>().add(const StartCurrentOnboardingInteraction());
    } on TimeoutException {
      return;
    } finally {
      if (mounted) {
        setState(() => pendingInteractionStepId = null);
      }
    }
  }
}
