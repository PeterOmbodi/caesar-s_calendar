import 'package:caesar_puzzle/application/race/solver_level.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/widgets/roman_head_icon.dart';

extension SolverLevelName on SolverLevel {
  String get label => switch (this) {
    SolverLevel.novice => S.current.raceSolverNovice,
    SolverLevel.confident => S.current.raceSolverConfident,
    SolverLevel.master => S.current.raceSolverMaster,
  };

  RomanRank get rank => switch (this) {
    SolverLevel.novice => RomanRank.recruit,
    SolverLevel.confident => RomanRank.legionary,
    SolverLevel.master => RomanRank.centurion,
  };
}
