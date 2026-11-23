import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/infrastructure/debug/debug_tools.dart';
import 'package:caesar_puzzle/presentation/auth/bloc/auth_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/locale_labels.dart';
import 'package:caesar_puzzle/presentation/pages/settings/solution_indicator_difficulty_x.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_section_sheet.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_summary_button.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/app_check_status.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/store_links.dart';
import 'package:caesar_puzzle/presentation/services/haptics_support.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_session_difficulty_x.dart';
import 'package:caesar_puzzle/presentation/widgets/controls/app_segmented_control.dart';
import 'package:caesar_puzzle/presentation/widgets/inset_section.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

const double _sectionGap = 24;

/// Settings as a Material 3 list.
class MaterialSettingsPanel extends StatelessWidget {
  const MaterialSettingsPanel({super.key});

  @override
  Widget build(final BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (final context, final state) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 20, 8, 16),
                child: Semantics(header: true, child: Text(S.current.settings, style: theme.textTheme.headlineSmall)),
              ),
              BlocBuilder<AuthCubit, AuthState>(
                buildWhen: (final p, final n) =>
                    p.isAvailable != n.isAvailable || p.user?.uid != n.user?.uid || p.isLoading != n.isLoading,
                builder: (final context, final auth) => AccountSummaryButton(
                  auth: auth,
                  onPressed: () => showAccountSectionSheet(context, closeDrawerFirst: true),
                ),
              ),
              const SizedBox(height: _sectionGap),
              InsetHeader(S.current.theme),
              AppSegmentedControl<AppTheme>(
                value: state.theme,
                segments: {
                  AppTheme.system: S.current.system,
                  AppTheme.light: S.current.light,
                  AppTheme.dark: S.current.dark,
                },
                onChanged: cubit.setTheme,
              ),
              const SizedBox(height: _sectionGap),
              RadioGroup<SolutionIndicator>(
                groupValue: state.solutionIndicator,
                onChanged: cubit.setSolutionIndicator,
                child: InsetSection(
                  header: S.current.solvability,
                  children: [
                    for (final MapEntry(key: indicator, value: subtitle) in {
                      SolutionIndicator.none: S.current.solutionIndicatorHiddenSubtitle,
                      SolutionIndicator.solvability: S.current.solutionIndicatorSolvabilitySubtitle,
                      SolutionIndicator.countSolutions: S.current.solutionIndicatorCountSubtitle,
                    }.entries)
                      RadioListTile<SolutionIndicator>(
                        title: Text(indicator.sessionDifficulty.label),
                        subtitle: Text(subtitle),
                        value: indicator,
                        controlAffinity: ListTileControlAffinity.trailing,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: _sectionGap),
              ValueListenableBuilder(
                valueListenable: HapticsSupport.instance.available,
                builder: (final context, final hapticsAvailable, _) => InsetSection(
                  header: S.current.additional,
                  children: [
                    SwitchListTile(
                      title: Text(S.current.timerToggleTitle),
                      subtitle: Text(S.current.timerToggleSubtitle),
                      value: state.showTimer,
                      onChanged: cubit.toggleShowTimer,
                    ),
                    if (hapticsAvailable)
                      SwitchListTile(
                        title: Text(S.current.hapticsTitle),
                        subtitle: Text(S.current.hapticsSubtitle),
                        value: state.haptics,
                        onChanged: cubit.toggleHaptics,
                      ),
                    SwitchListTile(
                      title: Text(S.current.soundsTitle),
                      subtitle: Text(S.current.soundsSubtitle),
                      value: state.sounds,
                      onChanged: cubit.toggleSounds,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _sectionGap),
              InsetSection(
                header: S.current.general,
                children: [
                  SwitchListTile(
                    title: Text(S.current.preventOverlapping),
                    subtitle: Text(S.current.preventOverlappingDescription),
                    value: state.preventOverlap,
                    onChanged: cubit.togglePreventOverlap,
                  ),
                  SwitchListTile(
                    title: Text(S.current.snapToGrid),
                    subtitle: Text(S.current.snapToGridDescription),
                    value: state.snapToGridOnTransform,
                    onChanged: cubit.toggleSnapToGrid,
                  ),
                  SwitchListTile(
                    title: Text(S.current.borderConfig),
                    subtitle: Text(S.current.borderConfigDescription),
                    value: state.separateMoveColors,
                    onChanged: cubit.toggleSeparateColors,
                  ),
                ],
              ),
              const SizedBox(height: _sectionGap),
              InsetSection(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(languageSectionTitle(Localizations.localeOf(context))),
                    subtitle: Text(_languageName(state.localeCode)),
                    onTap: () => _pickLanguage(context, state.localeCode),
                  ),
                ],
              ),
              if (webStoreLinks() case final links when links.isNotEmpty) ...[
                const SizedBox(height: _sectionGap),
                InsetSection(
                  header: S.current.storeGetApp,
                  children: [
                    for (final link in links)
                      ListTile(
                        leading: Icon(link.icon),
                        title: Text(link.title),
                        subtitle: link.subtitle == null ? null : Text(link.subtitle!),
                        trailing: link.url == null ? null : const Icon(Icons.open_in_new),
                        enabled: link.url != null,
                        onTap: () => openStoreLink(link),
                      ),
                  ],
                ),
              ],
              if (kDebugMode) ...[
                const SizedBox(height: _sectionGap),
                InsetSection(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.restart_alt),
                      title: const Text('Reset help for today'),
                      onTap: () => _resetTodayHelp(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.verified_user_outlined),
                      title: const Text('App Check'),
                      onTap: () => showAppCheckStatus(context),
                    ),
                  ],
                ),
              ],
              FutureBuilder(
                future: PackageInfo.fromPlatform(),
                builder: (final context, final snapshot) => snapshot.hasData
                    ? AppCheckSecretTap(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Text(
                            'Version ${snapshot.data!.version}+${snapshot.data!.buildNumber}',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _languageName(final String? code) =>
      code == null ? S.current.auto : localeLabels[code]?.native ?? code.toUpperCase();

  Future<void> _pickLanguage(final BuildContext context, final String? current) async {
    final cubit = context.read<SettingsCubit>();
    final picked = await showDialog<({String? code})>(
      context: context,
      builder: (_) => _LanguageDialog(current: current),
    );
    if (picked != null) {
      cubit.setLocaleCode(picked.code);
    }
  }
}

class _LanguageDialog extends StatelessWidget {
  const _LanguageDialog({required this.current});

  final String? current;

  @override
  Widget build(final BuildContext context) {
    final codes = [null, ...S.delegate.supportedLocales.map((final l) => l.languageCode)];
    final showEnglish = Localizations.localeOf(context).languageCode != 'en';
    return AlertDialog(
      title: Text(languageSectionTitle(Localizations.localeOf(context))),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      content: SizedBox(
        width: double.maxFinite,
        child: RadioGroup<String?>(
          groupValue: current,
          onChanged: (final code) => Navigator.of(context).pop((code: code)),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final code in codes)
                RadioListTile<String?>(
                  value: code,
                  title: Text(MaterialSettingsPanel._languageName(code)),
                  subtitle: showEnglish && code != null && localeLabels[code] != null
                      ? Text(localeLabels[code]!.english)
                      : null,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
      ],
    );
  }
}

Future<void> _resetTodayHelp(final BuildContext context) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  await DebugTools.resetTodayHelp();
  messenger?.showSnackBar(const SnackBar(content: Text('Help for today reset')));
}
