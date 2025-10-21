import 'package:caesar_puzzle/application/contracts/settings_query.dart';

import 'bloc/settings_cubit.dart';

class CubitSettingsQuery implements SettingsQuery {
  CubitSettingsQuery(this.cubit);

  final SettingsCubit cubit;

  @override
  bool get unlockConfig => cubit.state.unlockConfig;

  @override
  bool get preventOverlap => cubit.state.preventOverlap;

  @override
  bool get autoLockConfig => cubit.state.autoLockConfig;

  @override
  bool get separateMoveColors => cubit.state.separateMoveColors;

  @override
  bool get snapToGridOnTransform => cubit.state.snapToGridOnTransform;

  @override
  bool get requireSolutions => cubit.state.solutionIndicator != SolutionIndicator.none;
}
