import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/actions/game_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  /// [apple] uses ⌘ instead of Ctrl.
  ShortcutActivator? shortcut({required final bool apple}) => switch (this) {
    GameActionId.history => const SingleActivator(LogicalKeyboardKey.keyH),
    GameActionId.hint => const CharacterActivator('?'),
    GameActionId.undo => SingleActivator(LogicalKeyboardKey.keyZ, meta: apple, control: !apple),
    GameActionId.redo => SingleActivator(LogicalKeyboardKey.keyZ, meta: apple, control: !apple, shift: true),
    GameActionId.rotate => const SingleActivator(LogicalKeyboardKey.keyR),
    GameActionId.flip => const SingleActivator(LogicalKeyboardKey.keyF),
    GameActionId.prevSolution => const SingleActivator(LogicalKeyboardKey.arrowLeft),
    GameActionId.nextSolution => const SingleActivator(LogicalKeyboardKey.arrowRight),
    GameActionId.closeSolutions => const SingleActivator(LogicalKeyboardKey.escape),
    GameActionId.showSolutions => const SingleActivator(LogicalKeyboardKey.keyS),
    GameActionId.restart => SingleActivator(LogicalKeyboardKey.backspace, meta: apple, control: !apple),
    GameActionId.solutionCounter || GameActionId.howToPlay => null,
  };

  String? shortcutLabel({required final bool apple}) => switch (this) {
    GameActionId.history => 'H',
    GameActionId.hint => '?',
    GameActionId.undo => apple ? '⌘Z' : 'Ctrl+Z',
    GameActionId.redo => apple ? '⇧⌘Z' : 'Ctrl+Shift+Z',
    GameActionId.rotate => 'R',
    GameActionId.flip => 'F',
    GameActionId.prevSolution => '←',
    GameActionId.nextSolution => '→',
    GameActionId.closeSolutions => 'Esc',
    GameActionId.showSolutions => 'S',
    GameActionId.restart => apple ? '⌘⌫' : 'Ctrl+⌫',
    GameActionId.solutionCounter || GameActionId.howToPlay => null,
  };
}
