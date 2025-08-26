import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();

    return SafeArea(
      child: Material(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(S.current.settings, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            BlocBuilder<SettingsCubit, SettingsState>(
              buildWhen: (p, n) => p.theme != n.theme,
              builder: (context, state) {
                return Column(
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
                        ButtonSegment(
                          value: AppTheme.light,
                          label: Text(S.current.light),
                          icon: Icon(Icons.light_mode),
                        ),
                        ButtonSegment(value: AppTheme.dark, label: Text(S.current.dark), icon: Icon(Icons.dark_mode)),
                      ],
                      selected: {state.theme},
                      onSelectionChanged: (s) => cubit.setTheme(s.first),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            BlocBuilder<SettingsCubit, SettingsState>(
              buildWhen: (p, n) => p.unlockConfig != n.unlockConfig,
              builder: (context, state) {
                return SwitchListTile(
                  title: Text(S.current.unlockConfig),
                  subtitle: Text(S.current.unlockConfigDescription),
                  value: state.unlockConfig,
                  onChanged: cubit.toggleUnlockConfig,
                );
              },
            ),
            BlocBuilder<SettingsCubit, SettingsState>(
              buildWhen: (p, n) => p.preventOverlap != n.preventOverlap,
              builder: (context, state) {
                return SwitchListTile(
                  title: Text(S.current.preventOverlapping),
                  subtitle: Text(S.current.preventOverlappingDescription),
                  value: state.preventOverlap,
                  onChanged: cubit.togglePreventOverlap,
                );
              },
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
