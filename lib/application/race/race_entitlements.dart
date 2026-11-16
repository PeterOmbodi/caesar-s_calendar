/// Room limits of the player's plan; the only place the UI and the room repository take them from.
class RaceEntitlements {
  const RaceEntitlements({required this.maxPlayers});

  static const RaceEntitlements duel = RaceEntitlements(maxPlayers: 2);

  final int maxPlayers;
}
