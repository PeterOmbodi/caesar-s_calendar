import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_state.dart';

part 'settings_cubit.freezed.dart';
part 'settings_cubit.g.dart';


class SettingsCubit extends HydratedCubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  void setTheme(AppTheme theme) {
    debugPrint('setTheme: $theme');
    emit(state.copyWith(theme: theme));
  }
  void toggleUnlockConfig(bool v) => emit(state.copyWith(unlockConfig: v));
  void togglePreventOverlap(bool v) => emit(state.copyWith(preventOverlap: v));

  @override
  SettingsState? fromJson(Map<String, dynamic> json) {
    try { return SettingsState.fromJson(json); } catch (_) { return null; }
  }

  @override
  Map<String, dynamic>? toJson(SettingsState state) {
    try { return state.toJson(); } catch (_) { return null; }
  }
}
