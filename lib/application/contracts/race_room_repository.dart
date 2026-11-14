import 'package:caesar_puzzle/application/race/race_room.dart';

enum RaceRoomFailure {
  signInRequired,
  offline,
  noRoom,
  full,
  started,

  /// The date this client draws from the room differs from the host's.
  date,
  unknown,
}

class RaceRoomException implements Exception {
  const RaceRoomException(this.failure, [this.cause]);

  final RaceRoomFailure failure;
  final Object? cause;

  @override
  String toString() => 'RaceRoomException($failure${cause == null ? '' : ', $cause'})';
}

/// How the player appears to the others in a room.
class RaceProfile {
  const RaceProfile({required this.nickname, required this.colorIndex});

  final String nickname;
  final int colorIndex;
}

/// Methods throw [RaceRoomException]. The connection to the server is open only between [create] or [join] and
/// [leave].
abstract class RaceRoomRepository {
  String? get uid;

  /// Returns the code of the new room.
  Future<String> create(final RaceProfile profile);

  /// Also brings a player back into a room they are already in.
  Future<void> join(final String code, final RaceProfile profile);

  /// In the lobby the host closes the room and a guest frees the place; in a race the player goes offline.
  Future<void> leave(final String code);

  /// Null once the room is gone.
  Stream<RaceRoom?> watchRoom(final String code);

  Future<void> setReady(final String code, {required final bool ready, required final int round});

  /// Host only.
  Future<void> start(final String code, {required final RaceRoomPuzzle puzzle, required final DateTime startAt});

  Future<void> reportProgress(final String code, final int placed);

  Future<void> finish(final String code, {required final int durationMs});

  Future<void> giveUp(final String code);

  /// Host only: back to the lobby for the next round.
  Future<void> rematch(final String code, {required final int round});

  DateTime serverNow();
}
