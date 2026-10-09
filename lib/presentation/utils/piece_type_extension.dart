import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:flutter/material.dart';

extension PieceTypeExtension on PieceType {
  Color get colorForType {
    switch (this) {
      case PieceType.lShape:
        return AppColors.current.game.piece(PieceType.lShape).withValues(alpha: 0.8);
      case PieceType.square:
        return AppColors.current.game.piece(PieceType.square).withValues(alpha: 0.8);
      case PieceType.zShape:
        return AppColors.current.game.piece(PieceType.zShape).withValues(alpha: 0.8);
      case PieceType.yShape:
        return AppColors.current.game.piece(PieceType.yShape).withValues(alpha: 0.8);
      case PieceType.uShape:
        return AppColors.current.game.piece(PieceType.uShape).withValues(alpha: 0.8);
      case PieceType.pShape:
        return AppColors.current.game.piece(PieceType.pShape).withValues(alpha: 0.8);
      case PieceType.nShape:
        return AppColors.current.game.piece(PieceType.nShape).withValues(alpha: 0.8);
      case PieceType.vShape:
        return AppColors.current.game.piece(PieceType.vShape).withValues(alpha: 0.8);
      case PieceType.zone1:
      case PieceType.zone2:
        return AppColors.current.primary.withAlpha(50);
    }
  }

  String get idForType {
    switch (this) {
      case PieceType.lShape:
        return 'L-Shape';
      case PieceType.square:
        return 'Square';
      case PieceType.zShape:
        return 'Z-Shape';
      case PieceType.yShape:
        return 'Y-Shape';
      case PieceType.uShape:
        return 'U-Shape';
      case PieceType.pShape:
        return 'P-Shape';
      case PieceType.nShape:
        return 'N-Shape';
      case PieceType.vShape:
        return 'V-Shape';
      case PieceType.zone1:
        return 'zone1';
      case PieceType.zone2:
        return 'zone2';
    }
  }

  bool get isConfigType => this == PieceType.zone1 || this == PieceType.zone2;

  double get borderRadiusForType => isConfigType ? 0 : 8.0;
}
