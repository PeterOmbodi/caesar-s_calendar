import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/actions/game_action.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/chrome/glass_chrome.dart';
import 'package:flutter/material.dart';

/// [anchor] is the pressed control in global coordinates.
typedef GameActionCallback = void Function(GameAction action, Rect anchor);

/// Draws the game actions for one visual family. Placement follows [ScreenSpec.toolbar].
abstract class GameChrome extends StatelessWidget {
  const GameChrome({super.key, required this.actions, required this.spec, required this.onInvoke});

  /// Only the glass chrome exists for now; Material and web chrome will plug in here.
  factory GameChrome.forSpec({
    final Key? key,
    required final List<GameAction> actions,
    required final ScreenSpec spec,
    required final GameActionCallback onInvoke,
  }) => GlassChrome(key: key, actions: actions, spec: spec, onInvoke: onInvoke);

  final List<GameAction> actions;
  final ScreenSpec spec;
  final GameActionCallback onInvoke;

  /// Space the chrome takes along the edges of the game area; the board is laid out in the rest.
  static EdgeInsets reservedInsets(final BuildContext context) => GlassChrome.reservedInsets(context);
}
