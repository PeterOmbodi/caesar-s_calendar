import 'dart:math' as math;

import 'package:caesar_puzzle/core/constants/standard_puzzle_config.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_entity_extension.dart';

class PuzzleConfigClassifier {
  const PuzzleConfigClassifier._();

  static bool isCustomConfig({
    required final Iterable<PuzzlePieceUI> pieces,
    required final PuzzleGridEntity gridConfig,
  }) {
    final configPieces = pieces.where((final piece) => piece.isConfigItem).toList();
    if (configPieces.length != StandardPuzzleConfig.placementsByPieceId.length) {
      return true;
    }

    for (final piece in configPieces) {
      final standard = StandardPuzzleConfig.placementsByPieceId[piece.id];
      if (standard == null) {
        return true;
      }

      final offset = gridConfig.relativePosition(piece.position);
      final row = offset.dy.round();
      final col = offset.dx.round();
      final rotationSteps = _normalizeRotationSteps((piece.rotation / _rotationStep).round());
      if (row != standard.row ||
          col != standard.col ||
          rotationSteps != standard.rotationSteps ||
          piece.isFlipped != standard.isFlipped) {
        return true;
      }
    }

    return false;
  }

  static int _normalizeRotationSteps(final int value) => ((value % 4) + 4) % 4;

  static const double _rotationStep = math.pi / 2;
}
