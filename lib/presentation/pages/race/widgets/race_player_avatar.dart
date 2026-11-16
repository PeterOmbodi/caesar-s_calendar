import 'package:caesar_puzzle/application/race/race_player.dart';
import 'package:caesar_puzzle/application/race/solver_level.dart';
import 'package:caesar_puzzle/infrastructure/race/solver_race_repository.dart';
import 'package:caesar_puzzle/presentation/pages/race/solver_level_name.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_display.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/widgets/roman_head_icon.dart';
import 'package:flutter/material.dart';

/// A person shows the initials of the nickname; the solver shows the head of its level.
class RacePlayerAvatar extends StatelessWidget {
  const RacePlayerAvatar({super.key, required this.player, required this.radius, required this.solverLevel});

  final RacePlayer player;
  final double radius;

  /// Null in a race between people.
  final SolverLevel? solverLevel;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final level = solverLevel;
    if (level != null && player.uid == SolverRaceRepository.solverUid) {
      return RomanHeadAvatar(rank: level.rank, radius: radius);
    }
    return AccountAvatar(
      photoUrl: null,
      fallbackLabel: AccountDisplay.avatarInitials(player.nickname),
      radius: radius,
      backgroundColor: colors.player(player.colorIndex),
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
    );
  }
}
