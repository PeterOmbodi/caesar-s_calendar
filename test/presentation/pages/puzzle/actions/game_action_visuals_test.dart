import 'package:caesar_puzzle/presentation/pages/puzzle/actions/game_action.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/actions/game_action_visuals.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const withoutShortcut = {GameActionId.solutionCounter, GameActionId.howToPlay};

  for (final apple in [true, false]) {
    test('every action but the counter and How to play has a shortcut and a label (apple: $apple)', () {
      for (final id in GameActionId.values) {
        final hasShortcut = !withoutShortcut.contains(id);
        expect(id.shortcut(apple: apple) != null, hasShortcut, reason: '$id');
        expect(id.shortcutLabel(apple: apple) != null, hasShortcut, reason: '$id');
      }
    });
  }

  test('undo and redo use the platform command key', () {
    final appleUndo = GameActionId.undo.shortcut(apple: true)! as SingleActivator;
    final otherRedo = GameActionId.redo.shortcut(apple: false)! as SingleActivator;
    expect((appleUndo.trigger, appleUndo.meta, appleUndo.control), (LogicalKeyboardKey.keyZ, true, false));
    expect((otherRedo.trigger, otherRedo.meta, otherRedo.control, otherRedo.shift), (LogicalKeyboardKey.keyZ, false, true, true));
  });
}
