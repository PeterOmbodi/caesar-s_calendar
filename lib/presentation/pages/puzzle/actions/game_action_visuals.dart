import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/actions/game_action.dart';
import 'package:flutter/material.dart';

extension GameActionIdVisuals on GameActionId {
  IconData get icon => switch (this) {
    GameActionId.history => Icons.history,
    GameActionId.showSolutions || GameActionId.closeSolutions => Icons.lightbulb,
    GameActionId.prevSolution => Icons.arrow_left,
    GameActionId.nextSolution => Icons.arrow_right,
    GameActionId.undo => Icons.undo,
    GameActionId.redo => Icons.redo,
    GameActionId.hint => Icons.tips_and_updates_outlined,
    GameActionId.howToPlay => Icons.info_outline_rounded,
    GameActionId.settings => Icons.settings,
    GameActionId.restart => Icons.refresh,
  };

  String get label => switch (this) {
    GameActionId.history => S.current.historyTitle,
    GameActionId.showSolutions || GameActionId.closeSolutions => S.current.searchSolution,
    GameActionId.prevSolution => S.current.prevSolution,
    GameActionId.nextSolution => S.current.nextSolution,
    GameActionId.undo => S.current.undo,
    GameActionId.redo => S.current.redo,
    GameActionId.hint => S.current.hint,
    GameActionId.howToPlay => S.current.howToPlayTitle,
    GameActionId.settings => S.current.settings,
    GameActionId.restart => S.current.reset,
  };
}
