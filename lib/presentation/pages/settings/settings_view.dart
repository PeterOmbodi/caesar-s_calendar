import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/auth/bloc/auth_cubit.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/locale_labels.dart';
import 'package:caesar_puzzle/presentation/pages/settings/solution_indicator_difficulty_x.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_section_sheet.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_summary_button.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/cupertino_settings_panel.dart';
import 'package:caesar_puzzle/presentation/services/haptics_support.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_session_difficulty_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(final BuildContext context) =>
      ScreenSpec.of(context).family == ChromeFamily.glass ? const CupertinoSettingsPanel() : const _MaterialSettings();
}

class _MaterialSettings extends StatelessWidget {
  const _MaterialSettings();

  @override
  Widget build(final BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final supportedLocales = S.delegate.supportedLocales;
    final currentLocale = Localizations.localeOf(context);

    return SafeArea(
      child: Material(
        child: BlocBuilder<SettingsCubit, SettingsState>(
          buildWhen: (final p, final n) => p.localeCode != n.localeCode,
          builder: (final context, final localeState) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(S.current.settings, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              BlocBuilder<AuthCubit, AuthState>(
                buildWhen: (final p, final n) =>
                    p.isAvailable != n.isAvailable ||
                    p.user?.uid != n.user?.uid ||
                    p.isLoading != n.isLoading ||
                    p.errorMessage != n.errorMessage ||
                    p.pendingCloudReplace != n.pendingCloudReplace,
                builder: (final context, final auth) => AccountSummaryButton(
                  auth: auth,
                  onPressed: () => showAccountSectionSheet(context, closeDrawerFirst: true),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              BlocBuilder<SettingsCubit, SettingsState>(
                buildWhen: (final p, final n) => p.theme != n.theme,
                builder: (final context, final state) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.current.theme, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SegmentedButton<AppTheme>(
                      segments: [
                        ButtonSegment(
                          value: AppTheme.system,
                          label: Text(S.current.system),
                          icon: const Icon(Icons.phone_android),
                        ),
                        ButtonSegment(
                          value: AppTheme.light,
                          label: Text(S.current.light),
                          icon: const Icon(Icons.light_mode),
                        ),
                        ButtonSegment(
                          value: AppTheme.dark,
                          label: Text(S.current.dark),
                          icon: const Icon(Icons.dark_mode),
                        ),
                      ],
                      selected: {state.theme},
                      onSelectionChanged: (final selected) => cubit.setTheme(selected.first),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(S.current.solvability, style: const TextStyle(fontWeight: FontWeight.w600)),
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
                          title: Text(SolutionIndicator.none.sessionDifficulty.label),
                          subtitle: Text(S.current.solutionIndicatorHiddenSubtitle),
                          value: SolutionIndicator.none,
                          controlAffinity: ListTileControlAffinity.trailing,
                        ),
                        RadioListTile<SolutionIndicator>(
                          title: Text(SolutionIndicator.solvability.sessionDifficulty.label),
                          subtitle: Text(S.current.solutionIndicatorSolvabilitySubtitle),
                          value: SolutionIndicator.solvability,
                          controlAffinity: ListTileControlAffinity.trailing,
                        ),
                        RadioListTile<SolutionIndicator>(
                          title: Text(SolutionIndicator.countSolutions.sessionDifficulty.label),
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
              Text(S.current.additional, style: const TextStyle(fontWeight: FontWeight.w600)),
              BlocBuilder<SettingsCubit, SettingsState>(
                buildWhen: (final p, final n) => p.showTimer != n.showTimer,
                builder: (final context, final state) => SwitchListTile(
                  title: Text(S.current.timerToggleTitle),
                  subtitle: Text(S.current.timerToggleSubtitle),
                  value: state.showTimer,
                  onChanged: cubit.toggleShowTimer,
                ),
              ),
              ValueListenableBuilder(
                valueListenable: HapticsSupport.instance.available,
                builder: (final context, final available, _) => !available
                    ? const SizedBox.shrink()
                    : BlocBuilder<SettingsCubit, SettingsState>(
                        buildWhen: (final p, final n) => p.haptics != n.haptics,
                        builder: (final context, final state) => SwitchListTile(
                          title: Text(S.current.hapticsTitle),
                          subtitle: Text(S.current.hapticsSubtitle),
                          value: state.haptics,
                          onChanged: cubit.toggleHaptics,
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              Text(S.current.general, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
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
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(languageSectionTitle(currentLocale), style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    key: ValueKey(localeState.localeCode),
                    initialValue: localeState.localeCode,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    selectedItemBuilder: (final context) => [
                      Text(S.current.auto, overflow: TextOverflow.ellipsis),
                      ...supportedLocales.map(
                        (final locale) => Text(
                          localeLabels[locale.languageCode]?.native ?? locale.languageCode.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    items: [
                      DropdownMenuItem<String?>(
                        child: _LocaleDropdownItem(
                          title: S.current.auto,
                          subtitle: currentLocale.languageCode == 'en' ? null : S.current.language,
                        ),
                      ),
                      ...supportedLocales.map(
                        (final locale) => DropdownMenuItem<String?>(
                          value: locale.languageCode,
                          child: _LocaleDropdownItem(
                            title: localeLabels[locale.languageCode]?.native ?? locale.languageCode.toUpperCase(),
                            subtitle: currentLocale.languageCode == 'en'
                                ? null
                                : localeLabels[locale.languageCode]?.english,
                          ),
                        ),
                      ),
                    ],
                    onChanged: cubit.setLocaleCode,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
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
      ),
    );
  }
}

class _LocaleDropdownItem extends StatelessWidget {
  const _LocaleDropdownItem({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, overflow: TextOverflow.ellipsis),
        if (subtitle != null)
          Text(
            subtitle!,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
      ],
    );
  }
}
