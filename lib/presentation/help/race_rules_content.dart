import 'package:caesar_puzzle/application/race/race_rules.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/help/how_to_play_content.dart';
import 'package:flutter/material.dart';

HelpSection raceRulesSection() => HelpSection(
  title: S.current.raceTitle,
  items: [
    HelpItem(icon: Icons.traffic_outlined, title: S.current.helpRaceStartTitle, body: S.current.helpRaceStartBody),
    HelpItem(icon: Icons.rule, title: S.current.helpRaceRulesTitle, body: S.current.helpRaceRulesBody),
    HelpItem(
      icon: Icons.sports_score,
      title: S.current.helpRaceFinishTitle,
      body: S.current.helpRaceFinishBody(RaceRules.graceSec, RaceRules.timeLimit.inMinutes),
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
