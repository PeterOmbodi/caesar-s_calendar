import 'package:caesar_puzzle/application/race/race_rules.dart';
import 'package:caesar_puzzle/application/race/solver_level.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/help/how_to_play_content.dart';
import 'package:caesar_puzzle/presentation/pages/race/solver_level_name.dart';
import 'package:material_ui/material_ui.dart';

HelpSection raceRulesSection() => HelpSection(
  title: S.current.raceTitle,
  items: [
    HelpItem(icon: Icons.traffic_outlined, title: S.current.helpRaceStartTitle, body: S.current.helpRaceStartBody),
    HelpItem(
      icon: Icons.account_tree_outlined,
      title: S.current.raceVsSolver,
      body: S.current.helpRaceSolverBody(
        SolverLevel.novice.label,
        SolverLevel.confident.label,
        SolverLevel.master.label,
      ),
    ),
    HelpItem(icon: Icons.rule, title: S.current.helpRaceRulesTitle, body: S.current.helpRaceRulesBody),
    HelpItem(
      icon: Icons.sports_score,
      title: S.current.helpRaceFinishTitle,
      body: S.current.helpRaceFinishBody(RaceRules.timeLimit.inMinutes),
    ),
    HelpItem(icon: Icons.flag_outlined, title: S.current.raceGiveUp, body: S.current.helpRaceGiveUpBody),
    HelpItem(
      icon: Icons.wifi_off,
      title: S.current.helpRaceConnectionTitle,
      body: S.current.helpRaceConnectionBody(RaceRules.reconnectTime.inSeconds),
    ),
  ],
  footer: S.current.raceNoEffectNote,
);
