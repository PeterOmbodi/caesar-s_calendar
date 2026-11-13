import 'package:caesar_puzzle/application/contracts/settings_query.dart';

/// Every racer plays by the same rules, whatever their own settings are.
class RaceSettingsQuery implements SettingsQuery {
  const RaceSettingsQuery();

  @override
  bool get preventOverlap => true;

  @override
  bool get separateMoveColors => true;

  @override
  bool get snapToGridOnTransform => true;

  @override
  bool get requireSolutions => false;

  @override
  bool get showSolutionCount => false;
}
