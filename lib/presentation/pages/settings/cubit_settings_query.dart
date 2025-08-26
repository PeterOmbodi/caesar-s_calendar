import 'package:caesar_puzzle/application/contracts/settings_query.dart';

import 'bloc/settings_cubit.dart';

class CubitSettingsQuery implements SettingsQuery {
  final SettingsCubit cubit;
  CubitSettingsQuery(this.cubit);

  @override bool get unlockConfig => cubit.state.unlockConfig;
  @override bool get preventOverlap => cubit.state.preventOverlap;
}