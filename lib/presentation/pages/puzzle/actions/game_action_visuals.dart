import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/actions/game_action.dart';
import 'package:flutter/material.dart';

extension GameActionIdVisuals on GameActionId {
  IconData get icon => switch (this) {
    GameActionId.history => Icons.history,
    GameActionId.hint => Icons.lightbulb_outline,
    GameActionId.undo => Icons.undo,
    GameActionId.redo => Icons.redo,
    GameActionId.rotate => Icons.rotate_right,
    GameActionId.flip => Icons.flip,
    GameActionId.prevSolution => Icons.chevron_left,
    GameActionId.solutionCounter => Icons.tag,
    GameActionId.nextSolution => Icons.chevron_right,
    GameActionId.closeSolutions => Icons.close,
    GameActionId.showSolutions => Icons.auto_awesome_motion,
    GameActionId.howToPlay => Icons.help_outline,
    GameActionId.restart => Icons.restart_alt,
  };

  /// Short label under the icon in the toolbar, or the item text in a menu.
  String get label => switch (this) {
    GameActionId.history => S.current.historyTitle,
    GameActionId.hint => S.current.toolbarHint,
    GameActionId.undo => S.current.undo,
    GameActionId.redo => S.current.redo,
    GameActionId.rotate => S.current.toolbarRotate,
    GameActionId.flip => S.current.toolbarFlip,
    GameActionId.prevSolution => S.current.toolbarPrevious,
    GameActionId.solutionCounter => '',
    GameActionId.nextSolution => S.current.toolbarNext,
    GameActionId.closeSolutions => S.current.toolbarClose,
    GameActionId.showSolutions => S.current.menuShowAllSolutions,
    GameActionId.howToPlay => S.current.howToPlayTitle,
    GameActionId.restart => S.current.menuStartOver,
  };

  String get tooltip => switch (this) {
    GameActionId.hint => S.current.hint,
    GameActionId.prevSolution => S.current.prevSolution,
    GameActionId.nextSolution => S.current.nextSolution,
    _ => label,
  };
}
