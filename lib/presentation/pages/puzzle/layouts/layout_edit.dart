import 'package:caesar_puzzle/core/models/move.dart';
import 'package:caesar_puzzle/core/models/placement.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:flutter/foundation.dart';

/// Cancel restores from it what block moves changed in the game.
@immutable
class LayoutEdit {
  const LayoutEdit({
    required this.start,
    this.status = GameStatus.solutionsReady,
    this.layoutId,
    this.name,
    this.moveHistory = const [],
    this.moveIndex = 0,
    this.solutions = const [],
    this.applicableSolutions = const [],
    this.wasTimerRunning = false,
  });

  final List<PlacementParams> start;
  final GameStatus status;

  /// Set when a saved layout is edited: Save keeps its name and replaces it.
  final String? layoutId;
  final String? name;

  final List<Move> moveHistory;
  final int moveIndex;
  final List<Map<String, PlacementParams>> solutions;
  final List<Map<String, PlacementParams>> applicableSolutions;
  final bool wasTimerRunning;
}
