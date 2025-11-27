import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'settings_cubit.freezed.dart';
part 'settings_cubit.g.dart';
part 'settings_state.dart';

enum SolutionIndicator {
  none,
  solvability,
  countSolutions,
}

class SettingsCubit extends HydratedCubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  void setTheme(final AppTheme theme) {
    debugPrint('setTheme: $theme');
    emit(state.copyWith(theme: theme));
  }
  void toggleUnlockConfig(final bool v) => emit(state.copyWith(unlockConfig: v));
  void togglePreventOverlap(final bool v) => emit(state.copyWith(preventOverlap: v));
  void toggleAutoLockConfig(final bool v) => emit(state.copyWith(autoLockConfig: v));
  void toggleSnapToGrid(final bool v) => emit(state.copyWith(snapToGridOnTransform: v));
  void toggleSeparateColors(final bool v) => emit(state.copyWith(separateMoveColors: v));
  void setSolutionIndicator(final SolutionIndicator? v) => emit(state.copyWith(solutionIndicator: v ?? SolutionIndicator.none));
  void toggleShowTimer(final bool v) => emit(state.copyWith(showTimer: v));

  @override
  SettingsState? fromJson(final Map<String, dynamic> json) {
    try { return SettingsState.fromJson(json); } catch (_) { return null; }
  }

  @override
  Map<String, dynamic>? toJson(final SettingsState state) {
    try { return state.toJson(); } catch (_) { return null; }
  }
}
