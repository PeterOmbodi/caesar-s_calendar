import 'package:flutter/foundation.dart';

enum GameActionId {
  history,
  hint,
  undo,
  redo,
  rotate,
  flip,
  prevSolution,
  solutionCounter,
  nextSolution,
  closeSolutions,
  showSolutions,
  howToPlay,
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
    this.count,
    this.total,
  });

  final GameActionId id;
  final ActionSlot slot;
  final bool enabled;
  final bool active;
  final bool busy;
  final AssistGate? assistGate;
  final int? count;
  final int? total;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is GameAction &&
          other.id == id &&
          other.slot == slot &&
          other.enabled == enabled &&
          other.active == active &&
          other.busy == busy &&
          other.assistGate == assistGate &&
          other.count == count &&
          other.total == total;

  @override
  int get hashCode => Object.hash(id, slot, enabled, active, busy, assistGate, count, total);

  @override
  String toString() =>
      'GameAction($id, $slot, enabled: $enabled, active: $active, busy: $busy, assistGate: $assistGate, '
      'count: $count, total: $total)';
}
