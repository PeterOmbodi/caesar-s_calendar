import 'package:flutter/foundation.dart';

enum GameActionId {
  history,
  showSolutions,
  closeSolutions,
  prevSolution,
  nextSolution,
  undo,
  redo,
  hint,
  howToPlay,
  settings,
  restart,
}

enum ActionSlot { primary, overflow }

// What has to happen before an assist action (hint, all solutions) may run.
enum AssistGate {
  open,
  noSolutions,
  // Hard level: the player confirms first, and the session then counts as Easy.
  confirmEasy,
}

@immutable
class GameAction {
  const GameAction(
    this.id, {
    required this.slot,
    this.enabled = true,
    this.active = false,
    this.busy = false,
    this.assistGate,
  });

  final GameActionId id;
  final ActionSlot slot;
  final bool enabled;
  final bool active;
  final bool busy;
  final AssistGate? assistGate;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is GameAction &&
          other.id == id &&
          other.slot == slot &&
          other.enabled == enabled &&
          other.active == active &&
          other.busy == busy &&
          other.assistGate == assistGate;

  @override
  int get hashCode => Object.hash(id, slot, enabled, active, busy, assistGate);

  @override
  String toString() =>
      'GameAction($id, $slot, enabled: $enabled, active: $active, busy: $busy, assistGate: $assistGate)';
}
