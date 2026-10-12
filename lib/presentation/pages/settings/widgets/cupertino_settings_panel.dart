import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/auth/bloc/auth_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/locale_labels.dart';
import 'package:caesar_puzzle/presentation/pages/settings/solution_indicator_difficulty_x.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_display.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_section_sheet.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_summary_button.dart';
import 'package:caesar_puzzle/presentation/services/haptics_support.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_session_difficulty_x.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Settings as an iOS inset grouped list.
class CupertinoSettingsPanel extends StatelessWidget {
  const CupertinoSettingsPanel({super.key});

  @override
  Widget build(final BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final background = CupertinoColors.systemGroupedBackground.resolveFrom(context);
    return Material(
      color: background,
      child: SafeArea(
        top: false,
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (final context, final state) => CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: Text(S.current.settings),
                automaticallyImplyLeading: false,
                transitionBetweenRoutes: false,
                backgroundColor: background,
                border: null,
              ),
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 24),
                sliver: SliverList.list(
                  children: [
                    const _AccountSection(),
                    CupertinoListSection.insetGrouped(
                      header: Text(S.current.theme),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: CupertinoSlidingSegmentedControl<AppTheme>(
                            groupValue: state.theme,
                            children: {
                              AppTheme.system: Text(S.current.system),
                              AppTheme.light: Text(S.current.light),
                              AppTheme.dark: Text(S.current.dark),
                            },
                            onValueChanged: (final theme) {
                              if (theme != null) {
                                cubit.setTheme(theme);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    CupertinoListSection.insetGrouped(
                      header: Text(S.current.solvability),
                      children: [
                        for (final MapEntry(key: indicator, value: subtitle) in {
                          SolutionIndicator.none: S.current.solutionIndicatorHiddenSubtitle,
                          SolutionIndicator.solvability: S.current.solutionIndicatorSolvabilitySubtitle,
                          SolutionIndicator.countSolutions: S.current.solutionIndicatorCountSubtitle,
                        }.entries)
                          _Row(
                            title: indicator.sessionDifficulty.label,
                            subtitle: subtitle,
                            trailing: _CheckMark(visible: state.solutionIndicator == indicator),
                            onTap: () => cubit.setSolutionIndicator(indicator),
                          ),
                      ],
                    ),
                    ValueListenableBuilder(
                      valueListenable: HapticsSupport.instance.available,
                      builder: (final context, final hapticsAvailable, _) => CupertinoListSection.insetGrouped(
                        header: Text(S.current.additional),
                        children: [
                          _SwitchRow(
                            title: S.current.timerToggleTitle,
                            subtitle: S.current.timerToggleSubtitle,
                            value: state.showTimer,
                            onChanged: cubit.toggleShowTimer,
                          ),
                          if (hapticsAvailable)
                            _SwitchRow(
                              title: S.current.hapticsTitle,
                              subtitle: S.current.hapticsSubtitle,
                              value: state.haptics,
                              onChanged: cubit.toggleHaptics,
                            ),
                          _SwitchRow(
                            title: S.current.soundsTitle,
                            subtitle: S.current.soundsSubtitle,
                            value: state.sounds,
                            onChanged: cubit.toggleSounds,
                          ),
                        ],
                      ),
                    ),
                    CupertinoListSection.insetGrouped(
                      header: Text(S.current.general),
                      children: [
                        _SwitchRow(
                          title: S.current.preventOverlapping,
                          subtitle: S.current.preventOverlappingDescription,
                          value: state.preventOverlap,
                          onChanged: cubit.togglePreventOverlap,
                        ),
                        _SwitchRow(
                          title: S.current.snapToGrid,
                          subtitle: S.current.snapToGridDescription,
                          value: state.snapToGridOnTransform,
                          onChanged: cubit.toggleSnapToGrid,
                        ),
                        _SwitchRow(
                          title: S.current.borderConfig,
                          subtitle: S.current.borderConfigDescription,
                          value: state.separateMoveColors,
                          onChanged: cubit.toggleSeparateColors,
                        ),
                      ],
                    ),
                    CupertinoListSection.insetGrouped(
                      children: [
                        CupertinoListTile.notched(
                          title: Text(languageSectionTitle(Localizations.localeOf(context))),
                          additionalInfo: Text(_languageName(state.localeCode)),
                          trailing: const CupertinoListTileChevron(),
                          onTap: () => _pickLanguage(context, state.localeCode),
                        ),
                      ],
                    ),
                    FutureBuilder(
                      future: PackageInfo.fromPlatform(),
                      builder: (final context, final snapshot) => snapshot.hasData
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              child: Text(
                                'Version ${snapshot.data!.version}+${snapshot.data!.buildNumber}',
                                style: TextStyle(fontSize: 13, color: secondary),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
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
    final picked = await showCupertinoModalPopup<({String? code})>(
      context: context,
      builder: (final popupContext) => _LanguagePicker(current: current),
    );
    if (picked != null) {
      cubit.setLocaleCode(picked.code);
    }
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection();

  @override
  Widget build(final BuildContext context) => BlocBuilder<AuthCubit, AuthState>(
    buildWhen: (final p, final n) =>
        p.isAvailable != n.isAvailable || p.user?.uid != n.user?.uid || p.isLoading != n.isLoading,
    builder: (final context, final auth) {
      final user = auth.user;
      final displayName = AccountDisplay.bestDisplayName(user);
      final (:title, :subtitle) = AccountSummaryButton.textFor(auth);
      return CupertinoListSection.insetGrouped(
        children: [
          CupertinoListTile(
            leadingSize: 40,
            leading: AccountAvatar(
              photoUrl: AccountDisplay.bestPhotoUrl(user),
              fallbackLabel: AccountDisplay.avatarInitial(displayName),
              placeholderIcon: user == null ? CupertinoIcons.person : null,
              radius: 20,
            ),
            title: Text(title),
            subtitle: subtitle.isEmpty ? null : Text(subtitle),
            trailing: const CupertinoListTileChevron(),
            onTap: () => showAccountSectionSheet(context, closeDrawerFirst: true),
          ),
        ],
      );
    },
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.title, required this.subtitle, required this.trailing, this.onTap});

  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context) => CupertinoListTile(
    padding: const EdgeInsetsDirectional.fromSTEB(20, 10, 14, 10),
    title: Text(title, maxLines: 2),
    subtitle: Text(subtitle, maxLines: 3),
    trailing: trailing,
    onTap: onTap,
  );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.title, required this.subtitle, required this.value, required this.onChanged});

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(final BuildContext context) => _Row(
    title: title,
    subtitle: subtitle,
    trailing: CupertinoSwitch(value: value, onChanged: onChanged),
    onTap: () => onChanged(!value),
  );
}

/// Keeps its width when hidden, so the text beside it does not reflow.
class _CheckMark extends StatelessWidget {
  const _CheckMark({required this.visible});

  final bool visible;

  @override
  Widget build(final BuildContext context) => Visibility.maintain(
    visible: visible,
    child: Icon(CupertinoIcons.check_mark, size: 20, color: CupertinoTheme.of(context).primaryColor),
  );
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.current});

  final String? current;

  @override
  Widget build(final BuildContext context) {
    final codes = [null, ...S.delegate.supportedLocales.map((final l) => l.languageCode)];
    final showEnglish = Localizations.localeOf(context).languageCode != 'en';
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.7,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          children: [
            CupertinoListSection.insetGrouped(
              children: [
                for (final code in codes)
                  CupertinoListTile(
                    title: Text(code == null ? S.current.auto : localeLabels[code]?.native ?? code.toUpperCase()),
                    subtitle: showEnglish && code != null && localeLabels[code] != null
                        ? Text(localeLabels[code]!.english)
                        : null,
                    trailing: _CheckMark(visible: code == current),
                    onTap: () => Navigator.of(context).pop((code: code)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
