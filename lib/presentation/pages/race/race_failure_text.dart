import 'package:caesar_puzzle/application/contracts/race_room_repository.dart';
import 'package:caesar_puzzle/generated/l10n.dart';

extension RaceRoomFailureText on RaceRoomFailure {
  String get text => switch (this) {
    RaceRoomFailure.signInRequired => S.current.raceSignInRequired,
    RaceRoomFailure.offline => S.current.raceErrorOffline,
    RaceRoomFailure.noRoom => S.current.raceErrorNoRoom,
    RaceRoomFailure.full => S.current.raceErrorFull,
    RaceRoomFailure.started => S.current.raceErrorStarted,
    RaceRoomFailure.date => S.current.raceErrorDate,
    RaceRoomFailure.unknown => S.current.raceErrorUnknown,
  };
}
