import 'package:caesar_puzzle/application/race/race_board.dart';

class RacePlayer {
  const RacePlayer({
    required this.uid,
    required this.nickname,
    required this.colorIndex,
    required this.joinedAt,
    this.online = true,
    this.lastSeen,
    this.ready = false,
    this.nonce,
    this.placed = 0,
    this.durationMs,
    this.gaveUp = false,
    this.gaveUpAt,
    this.outAt,
    this.board,
  });

  final String uid;
  final String nickname;
  final int colorIndex;

  /// Server time, epoch milliseconds.
  final int joinedAt;
  final bool online;

  /// Server time of the last disconnect, epoch milliseconds.
  final int? lastSeen;
  final bool ready;
  final int? nonce;
  final int placed;

  /// Server-clock time from the start to the solve; null until the player finishes.
  final int? durationMs;
  final bool gaveUp;

  /// Server time of the give-up; null from a client that did not write it.
  final int? gaveUpAt;

  /// When the player dropped out of the race by staying away too long, written on coming back, since being
  /// online again no longer shows it.
  final int? outAt;

  final RaceBoard? board;

  bool get hasFinished => durationMs != null;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is RacePlayer &&
          other.uid == uid &&
          other.nickname == nickname &&
          other.colorIndex == colorIndex &&
          other.joinedAt == joinedAt &&
          other.online == online &&
          other.lastSeen == lastSeen &&
          other.ready == ready &&
          other.nonce == nonce &&
          other.placed == placed &&
          other.durationMs == durationMs &&
          other.gaveUp == gaveUp &&
          other.gaveUpAt == gaveUpAt &&
          other.outAt == outAt &&
          other.board == board;

  @override
  int get hashCode => Object.hash(
    uid,
    nickname,
    colorIndex,
    joinedAt,
    online,
    lastSeen,
    ready,
    nonce,
    placed,
    durationMs,
    gaveUp,
    gaveUpAt,
    outAt,
    board,
  );
}
