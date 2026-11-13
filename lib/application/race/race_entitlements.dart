/// Room limits of the player's plan; the only place the UI and the room repository take them from.
class RaceEntitlements {
  const RaceEntitlements({
    required this.maxPlayers,
    required this.maxRounds,
    required this.randomLayout,
    required this.dateTier,
    required this.customGrace,
    required this.hints,
  });

  static const RaceEntitlements duel = RaceEntitlements(
    maxPlayers: 2,
    maxRounds: 1,
    randomLayout: false,
    dateTier: false,
    customGrace: false,
    hints: false,
  );

  final int maxPlayers;
  final int maxRounds;
  final bool randomLayout;
  final bool dateTier;
  final bool customGrace;
  final bool hints;
}
