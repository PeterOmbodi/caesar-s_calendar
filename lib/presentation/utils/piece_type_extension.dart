import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:flutter/material.dart';

extension PieceTypeExtension on PieceType {
  Color get colorForType => isConfigType ? AppColors.current.game.blockedCell : AppColors.current.game.piece(this);

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
