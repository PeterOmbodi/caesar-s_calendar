import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:flutter/material.dart';

Offset resolvePTargetTopLeft(final PuzzleState state) => Offset(
  state.gridConfig.origin.dx + 3 * state.gridConfig.cellSize,
  state.gridConfig.origin.dy,
);
