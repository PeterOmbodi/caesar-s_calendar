import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

typedef _LocaleLabel = ({String native, String english});

const Map<String, _LocaleLabel> _localeLabels = {
  'bg': (native: 'Български', english: 'Bulgarian'),
  'cs': (native: 'Čeština', english: 'Czech'),
  'da': (native: 'Dansk', english: 'Danish'),
  'de': (native: 'Deutsch', english: 'German'),
  'en': (native: 'English', english: 'English'),
  'es': (native: 'Español', english: 'Spanish'),
  'et': (native: 'Eesti', english: 'Estonian'),
  'fi': (native: 'Suomi', english: 'Finnish'),
  'fr': (native: 'Français', english: 'French'),
  'hr': (native: 'Hrvatski', english: 'Croatian'),
  'hu': (native: 'Magyar', english: 'Hungarian'),
  'is': (native: 'Íslenska', english: 'Icelandic'),
  'it': (native: 'Italiano', english: 'Italian'),
  'lt': (native: 'Lietuvių', english: 'Lithuanian'),
  'lv': (native: 'Latviešu', english: 'Latvian'),
  'mk': (native: 'Македонски', english: 'Macedonian'),
  'nb': (native: 'Norsk Bokmal', english: 'Norwegian Bokmal'),
  'nl': (native: 'Nederlands', english: 'Dutch'),
  'pl': (native: 'Polski', english: 'Polish'),
  'pt': (native: 'Português', english: 'Portuguese'),
  'ro': (native: 'Română', english: 'Romanian'),
  'sk': (native: 'Slovenčina', english: 'Slovak'),
  'sl': (native: 'Slovenščina', english: 'Slovenian'),
  'sq': (native: 'Shqip', english: 'Albanian'),
  'sv': (native: 'Svenska', english: 'Swedish'),
  'uk': (native: 'Українська', english: 'Ukrainian'),
};

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

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
              Text(S.current.general, style: const TextStyle(fontWeight: FontWeight.w600)),
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
                buildWhen: (final p, final n) =>
                    p.unlockConfig != n.unlockConfig || p.autoLockConfig != n.autoLockConfig,
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
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_buildLanguageSectionTitle(currentLocale), style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    key: ValueKey(localeState.localeCode),
                    initialValue: localeState.localeCode,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    selectedItemBuilder: (final context) => [
                      Text(S.current.auto, overflow: TextOverflow.ellipsis),
                      ...supportedLocales.map(
                        (final locale) => Text(
                          _localeLabels[locale.languageCode]?.native ?? locale.languageCode.toUpperCase(),
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
                            title: _localeLabels[locale.languageCode]?.native ?? locale.languageCode.toUpperCase(),
                            subtitle: currentLocale.languageCode == 'en'
                                ? null
                                : _localeLabels[locale.languageCode]?.english,
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

String _buildLanguageSectionTitle(final Locale currentLocale) {
  if (currentLocale.languageCode == 'en') return S.current.language;
  return '${S.current.language} (Language)';
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
