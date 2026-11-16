import 'package:caesar_puzzle/application/race/solver_level.dart';
import 'package:caesar_puzzle/generated/l10n.dart';

extension SolverLevelName on SolverLevel {
  String get label => switch (this) {
    SolverLevel.novice => S.current.raceSolverNovice,
    SolverLevel.confident => S.current.raceSolverConfident,
    SolverLevel.master => S.current.raceSolverMaster,
  };
}
