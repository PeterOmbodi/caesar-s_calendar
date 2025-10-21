import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(final BuildContext context) {
    final cubit = context.read<SettingsCubit>();

    return SafeArea(
      child: Material(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(S.current.settings, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            BlocBuilder<SettingsCubit, SettingsState>(
              buildWhen: (final p, final n) => p.theme != n.theme,
              builder: (final context, final state) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.current.theme, style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SegmentedButton<AppTheme>(
                    segments: [
                      ButtonSegment(
                        value: AppTheme.system,
                        label: Text(S.current.system),
                        icon: Icon(Icons.phone_android),
                      ),
                      ButtonSegment(value: AppTheme.light, label: Text(S.current.light), icon: Icon(Icons.light_mode)),
                      ButtonSegment(value: AppTheme.dark, label: Text(S.current.dark), icon: Icon(Icons.dark_mode)),
                    ],
                    selected: {state.theme},
                    onSelectionChanged: (final s) => cubit.setTheme(s.first),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(S.current.general, style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            BlocBuilder<SettingsCubit, SettingsState>(
              buildWhen: (final p, final n) => p.unlockConfig != n.unlockConfig,
              builder: (final context, final state) => SwitchListTile(
                title: Text(S.current.unlockConfig),
                subtitle: Text(S.current.unlockConfigDescription),
                value: state.unlockConfig,
                onChanged: cubit.toggleUnlockConfig,
              ),
            ),
            BlocBuilder<SettingsCubit, SettingsState>(
              buildWhen: (final p, final n) => p.unlockConfig != n.unlockConfig || p.autoLockConfig != n.autoLockConfig,
              builder: (final context, final state) => SwitchListTile(
                title: Text(S.current.autoLockConfig),
                subtitle: Text(S.current.autoLockConfigDescription),
                value: state.autoLockConfig,
                onChanged: cubit.state.unlockConfig ? cubit.toggleAutoLockConfig : null,
              ),
            ),
            BlocBuilder<SettingsCubit, SettingsState>(
              buildWhen: (final p, final n) => p.preventOverlap != n.preventOverlap,
              builder: (final context, final state) => SwitchListTile(
                title: Text(S.current.preventOverlapping),
                subtitle: Text(S.current.preventOverlappingDescription),
                value: state.preventOverlap,
                onChanged: cubit.togglePreventOverlap,
              ),
            ),
            BlocBuilder<SettingsCubit, SettingsState>(
              buildWhen: (final p, final n) => p.snapToGridOnTransform != n.snapToGridOnTransform,
              builder: (final context, final state) => SwitchListTile(
                title: Text(S.current.snapToGrid),
                subtitle: Text(S.current.snapToGridDescription),
                value: state.snapToGridOnTransform,
                onChanged: cubit.toggleSnapToGrid,
              ),
            ),
            BlocBuilder<SettingsCubit, SettingsState>(
              buildWhen: (final p, final n) => p.separateMoveColors != n.separateMoveColors,
              builder: (final context, final state) => SwitchListTile(
                title: Text(S.current.borderConfig),
                subtitle: Text(S.current.borderConfigDescription),
                value: state.separateMoveColors,
                onChanged: cubit.toggleSeparateColors,
              ),
            ),
            const SizedBox(height: 8),
            Text(S.current.solvability, style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            BlocBuilder<SettingsCubit, SettingsState>(
              buildWhen: (final p, final n) => p.solutionIndicator != n.solutionIndicator,
              builder: (final context, final state) {
                final cubit = context.read<SettingsCubit>();
                return RadioGroup<SolutionIndicator>(
                  groupValue: state.solutionIndicator,
                  onChanged: cubit.setSolutionIndicator,
                  child: Column(
                    children: [
                      RadioListTile<SolutionIndicator>(
                        title: Text(S.current.solutionIndicatorHiddenTitle),
                        subtitle: Text(S.current.solutionIndicatorHiddenSubtitle),
                        value: SolutionIndicator.none,
                        controlAffinity: ListTileControlAffinity.trailing,
                      ),
                      RadioListTile<SolutionIndicator>(
                        title: Text(S.current.solutionIndicatorSolvabilityTitle),
                        subtitle: Text(S.current.solutionIndicatorSolvabilitySubtitle),
                        value: SolutionIndicator.solvability,
                        controlAffinity: ListTileControlAffinity.trailing,
                      ),
                      RadioListTile<SolutionIndicator>(
                        title: Text(S.current.solutionIndicatorCountTitle),
                        subtitle: Text(S.current.solutionIndicatorCountSubtitle),
                        value: SolutionIndicator.countSolutions,
                        controlAffinity: ListTileControlAffinity.trailing,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(S.current.additional, style: TextStyle(fontWeight: FontWeight.w600)),
            BlocBuilder<SettingsCubit, SettingsState>(
              buildWhen: (final p, final n) => p.showTimer != n.showTimer,
              builder: (final context, final state) => SwitchListTile(
                title: Text(S.current.timerToggleTitle),
                subtitle: Text(S.current.timerToggleSubtitle),
                value: state.showTimer,
                onChanged: cubit.toggleShowTimer,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            FutureBuilder(
              future: PackageInfo.fromPlatform(),
              builder: (final context, final snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final info = snapshot.data!;
                return Text('Version ${info.version}+${info.buildNumber}');
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
