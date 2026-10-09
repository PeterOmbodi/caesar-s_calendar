import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:flutter/material.dart';

// Values come from the game screen mockup: dark theme from concept A2, light theme from B2.
@immutable
class GameColors extends ThemeExtension<GameColors> {
  const GameColors({
    required this.background,
    required this.backgroundTop,
    required this.board,
    required this.gridLine,
    required this.boardBorder,
    required this.blockedCell,
    required this.target,
    required this.targetLine,
    required this.text,
    required this.textSecondary,
    required this.cellLabel,
    required this.accent,
    required this.active,
    required this.onActive,
    required this.glass,
    required this.glassLine,
    required this.glassHighlight,
    required this.menu,
    required this.shadow,
    required this.icon,
    required this.iconDisabled,
    required this.ok,
    required this.bad,
    required this.customConfig,
    required this.hintBadge,
    required this.selection,
    required this.pieces,
  });

  factory GameColors.of(final BuildContext context) => Theme.of(context).extension<GameColors>()!;

  static const _pieces = {
    PieceType.lShape: Color(0xFF14937F),
    PieceType.square: Color(0xFF3F51B5),
    PieceType.zShape: Color(0xFF7A5546),
    PieceType.yShape: Color(0xFF5A7385),
    PieceType.uShape: Color(0xFF9C9CA3),
    PieceType.pShape: Color(0xFF6B40C2),
    PieceType.nShape: Color(0xFF1F86E0),
    PieceType.vShape: Color(0xFF00ADC4),
  };

  static const dark = GameColors(
    background: Color(0xFF121017),
    backgroundTop: Color(0xFF1E1A28),
    board: Color(0xFF1C1A23),
    gridLine: Color(0xFF2F2B38),
    boardBorder: Color(0xFF3D3848),
    blockedCell: Color(0xFF262131),
    target: Color(0xFF0E2A42),
    targetLine: Color(0xFF3BA4F0),
    text: Color(0xFFF2F0F6),
    textSecondary: Color(0xFFA7A2B4),
    cellLabel: Color(0xFFDCD8E5),
    accent: Color(0xFF4DB6F6),
    active: Color(0xFF7C4DDB),
    onActive: Color(0xFFFFFFFF),
    glass: Color(0x942A2636),
    glassLine: Color(0x21FFFFFF),
    glassHighlight: Color(0x1AFFFFFF),
    menu: Color(0xD1262230),
    shadow: Color(0x73000000),
    icon: Color(0xFFECE9F2),
    iconDisabled: Color(0x47ECE9F2),
    ok: Color(0xFF62D68D),
    bad: Color(0xFFFF6B6B),
    customConfig: Color(0xFFF2B544),
    hintBadge: Color(0xFFFFFFFF),
    selection: Color(0xFFFFFFFF),
    pieces: _pieces,
  );

  static const light = GameColors(
    background: Color(0xFFF5F2EC),
    backgroundTop: Color(0xFFFBF9F5),
    board: Color(0xFFFCFAF6),
    gridLine: Color(0xFFE6DFD3),
    boardBorder: Color(0xFFD5CCBD),
    blockedCell: Color(0xFFE9E1D4),
    target: Color(0xFFFCE9BF),
    targetLine: Color(0xFFDF9A27),
    text: Color(0xFF1F1D26),
    textSecondary: Color(0xFF5E5A68),
    cellLabel: Color(0xFF2A2731),
    accent: Color(0xFFB06D07),
    active: Color(0xFF14A39F),
    onActive: Color(0xFFFFFFFF),
    glass: Color(0xA8FFFFFF),
    glassLine: Color(0xF2FFFFFF),
    glassHighlight: Color(0x99FFFFFF),
    menu: Color(0xDBFFFFFF),
    shadow: Color(0x383C280A),
    icon: Color(0xFF38353F),
    iconDisabled: Color(0x4738353F),
    ok: Color(0xFF2A9450),
    bad: Color(0xFFD23B3B),
    customConfig: Color(0xFFB26A00),
    hintBadge: Color(0xFF1F1D26),
    selection: Color(0xFFFFFFFF),
    pieces: _pieces,
  );

  final Color background;
  final Color backgroundTop;
  final Color board;
  final Color gridLine;
  final Color boardBorder;
  final Color blockedCell;
  final Color target;
  final Color targetLine;
  final Color text;
  final Color textSecondary;
  final Color cellLabel;
  final Color accent;
  final Color active;
  final Color onActive;
  final Color glass;
  final Color glassLine;
  final Color glassHighlight;
  final Color menu;
  final Color shadow;
  final Color icon;
  final Color iconDisabled;
  final Color ok;
  final Color bad;
  final Color customConfig;
  final Color hintBadge;
  final Color selection;
  final Map<PieceType, Color> pieces;

  Color piece(final PieceType type) => pieces[type] ?? blockedCell;

  @override
  GameColors copyWith({
    final Color? background,
    final Color? backgroundTop,
    final Color? board,
    final Color? gridLine,
    final Color? boardBorder,
    final Color? blockedCell,
    final Color? target,
    final Color? targetLine,
    final Color? text,
    final Color? textSecondary,
    final Color? cellLabel,
    final Color? accent,
    final Color? active,
    final Color? onActive,
    final Color? glass,
    final Color? glassLine,
    final Color? glassHighlight,
    final Color? menu,
    final Color? shadow,
    final Color? icon,
    final Color? iconDisabled,
    final Color? ok,
    final Color? bad,
    final Color? customConfig,
    final Color? hintBadge,
    final Color? selection,
    final Map<PieceType, Color>? pieces,
  }) => GameColors(
    background: background ?? this.background,
    backgroundTop: backgroundTop ?? this.backgroundTop,
    board: board ?? this.board,
    gridLine: gridLine ?? this.gridLine,
    boardBorder: boardBorder ?? this.boardBorder,
    blockedCell: blockedCell ?? this.blockedCell,
    target: target ?? this.target,
    targetLine: targetLine ?? this.targetLine,
    text: text ?? this.text,
    textSecondary: textSecondary ?? this.textSecondary,
    cellLabel: cellLabel ?? this.cellLabel,
    accent: accent ?? this.accent,
    active: active ?? this.active,
    onActive: onActive ?? this.onActive,
    glass: glass ?? this.glass,
    glassLine: glassLine ?? this.glassLine,
    glassHighlight: glassHighlight ?? this.glassHighlight,
    menu: menu ?? this.menu,
    shadow: shadow ?? this.shadow,
    icon: icon ?? this.icon,
    iconDisabled: iconDisabled ?? this.iconDisabled,
    ok: ok ?? this.ok,
    bad: bad ?? this.bad,
    customConfig: customConfig ?? this.customConfig,
    hintBadge: hintBadge ?? this.hintBadge,
    selection: selection ?? this.selection,
    pieces: pieces ?? this.pieces,
  );

  @override
  GameColors lerp(final GameColors? other, final double t) {
    if (other == null) {
      return this;
    }
    Color c(final Color a, final Color b) => Color.lerp(a, b, t)!;
    return GameColors(
      background: c(background, other.background),
      backgroundTop: c(backgroundTop, other.backgroundTop),
      board: c(board, other.board),
      gridLine: c(gridLine, other.gridLine),
      boardBorder: c(boardBorder, other.boardBorder),
      blockedCell: c(blockedCell, other.blockedCell),
      target: c(target, other.target),
      targetLine: c(targetLine, other.targetLine),
      text: c(text, other.text),
      textSecondary: c(textSecondary, other.textSecondary),
      cellLabel: c(cellLabel, other.cellLabel),
      accent: c(accent, other.accent),
      active: c(active, other.active),
      onActive: c(onActive, other.onActive),
      glass: c(glass, other.glass),
      glassLine: c(glassLine, other.glassLine),
      glassHighlight: c(glassHighlight, other.glassHighlight),
      menu: c(menu, other.menu),
      shadow: c(shadow, other.shadow),
      icon: c(icon, other.icon),
      iconDisabled: c(iconDisabled, other.iconDisabled),
      ok: c(ok, other.ok),
      bad: c(bad, other.bad),
      customConfig: c(customConfig, other.customConfig),
      hintBadge: c(hintBadge, other.hintBadge),
      selection: c(selection, other.selection),
      pieces: {for (final type in pieces.keys) type: c(piece(type), other.piece(type))},
    );
  }
}
