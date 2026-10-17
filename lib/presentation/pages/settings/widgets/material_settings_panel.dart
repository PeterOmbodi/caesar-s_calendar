import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/auth/bloc/auth_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/locale_labels.dart';
import 'package:caesar_puzzle/presentation/pages/settings/solution_indicator_difficulty_x.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_section_sheet.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_summary_button.dart';
import 'package:caesar_puzzle/presentation/services/haptics_support.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_session_difficulty_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Semantics(header: true, child: Text(S.current.settings, style: theme.textTheme.headlineSmall)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: BlocBuilder<AuthCubit, AuthState>(
                  buildWhen: (final p, final n) =>
                      p.isAvailable != n.isAvailable || p.user?.uid != n.user?.uid || p.isLoading != n.isLoading,
                  builder: (final context, final auth) => AccountSummaryButton(
                    auth: auth,
                    onPressed: () => showAccountSectionSheet(context, closeDrawerFirst: true),
                  ),
                ),
              ),
              _Header(S.current.theme),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<AppTheme>(
                  segments: [
                    ButtonSegment(value: AppTheme.system, label: Text(S.current.system)),
                    ButtonSegment(value: AppTheme.light, label: Text(S.current.light)),
                    ButtonSegment(value: AppTheme.dark, label: Text(S.current.dark)),
                  ],
                  selected: {state.theme},
                  onSelectionChanged: (final selected) => cubit.setTheme(selected.first),
                ),
              ),
              _Header(S.current.solvability),
              RadioGroup<SolutionIndicator>(
                groupValue: state.solutionIndicator,
                onChanged: cubit.setSolutionIndicator,
                child: Column(
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
              _Header(S.current.additional),
              SwitchListTile(
                title: Text(S.current.timerToggleTitle),
                subtitle: Text(S.current.timerToggleSubtitle),
                value: state.showTimer,
                onChanged: cubit.toggleShowTimer,
              ),
              ValueListenableBuilder(
                valueListenable: HapticsSupport.instance.available,
                builder: (final context, final available, _) => available
                    ? SwitchListTile(
                        title: Text(S.current.hapticsTitle),
                        subtitle: Text(S.current.hapticsSubtitle),
                        value: state.haptics,
                        onChanged: cubit.toggleHaptics,
                      )
                    : const SizedBox.shrink(),
              ),
              SwitchListTile(
                title: Text(S.current.soundsTitle),
                subtitle: Text(S.current.soundsSubtitle),
                value: state.sounds,
                onChanged: cubit.toggleSounds,
              ),
              _Header(S.current.general),
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
              const Divider(height: 32),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(languageSectionTitle(Localizations.localeOf(context))),
                subtitle: Text(_languageName(state.localeCode)),
                onTap: () => _pickLanguage(context, state.localeCode),
              ),
              FutureBuilder(
                future: PackageInfo.fromPlatform(),
                builder: (final context, final snapshot) => snapshot.hasData
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Text(
                          'Version ${snapshot.data!.version}+${snapshot.data!.buildNumber}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Semantics(
        header: true,
        child: Text(text, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
      ),
    );
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
