import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:flutter/material.dart';

extension PieceTypeExtension on PieceType {
  Color get colorForType {
    switch (this) {
      case PieceType.lShape:
        return Colors.teal.withValues(alpha: 0.8);
      case PieceType.square:
        return Colors.indigo.withValues(alpha: 0.8);
      case PieceType.zShape:
        return Colors.brown.withValues(alpha: 0.8);
      case PieceType.yShape:
        return Colors.blueGrey.withValues(alpha: 0.8);
      case PieceType.uShape:
        return Colors.grey.withValues(alpha: 0.8);
      case PieceType.pShape:
        return Colors.deepPurple.withValues(alpha: 0.8);
      case PieceType.nShape:
        return Colors.blue.withValues(alpha: 0.8);
      case PieceType.vShape:
        return Colors.cyan.withValues(alpha: 0.8);
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
