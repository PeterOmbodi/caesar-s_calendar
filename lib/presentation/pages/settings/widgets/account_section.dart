import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/infrastructure/sync/sync_status.dart';
import 'package:caesar_puzzle/presentation/auth/bloc/auth_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/achievements/achievements_screen.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/public_profile_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_display.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/widgets/inset_section.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

const _webVersionUri = 'https://peterombodi.github.io/caesar-s_calendar/';

class AccountSection extends StatefulWidget {
  const AccountSection({required this.auth, super.key});

  final AuthState auth;

  @override
  State<AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends State<AccountSection> {
  static const _sectionGap = SizedBox(height: 28);

  @override
  void didUpdateWidget(covariant final AccountSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.auth.pendingCloudReplace;
    final current = widget.auth.pendingCloudReplace;
    if (current != null && previous != current) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showCloudReplaceDialog();
      });
    }
  }

  Future<void> _showCloudReplaceDialog() async {
    final cubit = context.read<AuthCubit>();
    final shouldContinue = await showAdaptiveDialog<bool>(
      context: context,
      builder: (final dialogContext) => PlatformAlertDialog(
        title: Text(S.current.accountCloudReplaceTitle),
        content: Text(S.current.accountCloudReplaceMessage),
        actions: [
          PlatformDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(S.current.accountCloudReplaceCancel),
          ),
          PlatformDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            cupertino: (_, _) => CupertinoDialogActionData(isDefaultAction: true),
            child: Text(S.current.accountCloudReplaceContinue),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (shouldContinue == true) {
      await cubit.confirmCloudReplace();
      return;
    }
    await cubit.cancelCloudReplace();
  }

  Future<void> _showDeleteAccountDialog() async {
    final cubit = context.read<AuthCubit>();
    final provider = _providerLabel(widget.auth.user);
    final shouldDelete = await showAdaptiveDialog<bool>(
      context: context,
      builder: (final dialogContext) => PlatformAlertDialog(
        title: Text(S.current.accountDeleteTitle),
        content: Text(
          [
            S.current.accountDeleteMessage,
            if (provider != null) S.current.accountDeleteConfirmIdentityMessage(provider),
          ].join('\n\n'),
        ),
        actions: [
          PlatformDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(S.current.historySessionDialogCancel),
          ),
          PlatformDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            cupertino: (_, _) => CupertinoDialogActionData(isDestructiveAction: true),
            child: Text(
              provider == null ? S.current.accountDeleteAction : S.current.accountDeleteContinueToProvider(provider),
            ),
          ),
        ],
      ),
    );
    if (!mounted || shouldDelete != true) return;
    await cubit.deleteAccount();
  }

  Future<void> _openWebVersion() async {
    final didLaunch = await launchUrl(Uri.parse(_webVersionUri), mode: LaunchMode.externalApplication);
    if (!mounted || didLaunch) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.current.accountOpenWebVersionError)));
  }

  @override
  Widget build(final BuildContext context) {
    final auth = widget.auth;
    final colors = GameColors.of(context);
    if (!auth.isAvailable) {
      return _note(S.current.accountFirebaseUnavailable, colors.textSecondary);
    }
    final publicProfile = context.watch<PublicProfileCubit>().state;
    final syncError = publicProfile.syncStatus.lastError;
    final errors = [
      auth.errorMessage,
      publicProfile.errorMessage,
      if (syncError != null) S.current.accountSyncLastError(syncError),
    ].nonNulls;
    final user = auth.user;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (user == null) ..._signedOut(colors, auth) else ..._signedIn(colors, auth, publicProfile, user),
        for (final error in errors) Padding(padding: const EdgeInsets.only(top: 12), child: _note(error, colors.bad)),
        if (!kIsWeb) ...[
          _sectionGap,
          InsetSection(
            children: [
              InsetRow(icon: Icons.open_in_new, title: S.current.accountOpenWebVersion, onTap: _openWebVersion),
            ],
          ),
        ],
      ],
    );
  }

  List<Widget> _signedOut(final GameColors colors, final AuthState auth) {
    final cubit = context.read<AuthCubit>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      _note(S.current.accountAndSyncDescription, colors.textSecondary),
      const SizedBox(height: 16),
      if (_supportsAppleSignIn) ...[
        // Apple's button style: black on light, white on dark.
        _SignInButton(
          label: S.current.accountContinueWithApple,
          icon: Icons.apple,
          background: isDark ? Colors.white : Colors.black,
          foreground: isDark ? Colors.black : Colors.white,
          onPressed: auth.isLoading ? null : cubit.signInWithApple,
        ),
        const SizedBox(height: 10),
      ],
      _SignInButton(
        label: S.current.accountContinueWithGoogle,
        background: colors.board,
        foreground: colors.text,
        border: colors.boardBorder,
        onPressed: auth.isLoading ? null : cubit.signInWithGoogle,
      ),
      if (auth.isLoading)
        const Padding(padding: EdgeInsets.only(top: 16), child: Center(child: CircularProgressIndicator.adaptive())),
    ];
  }

  List<Widget> _signedIn(
    final GameColors colors,
    final AuthState auth,
    final PublicProfileState publicProfile,
    final dynamic user,
  ) {
    final cubit = context.read<AuthCubit>();
    final profileCubit = context.read<PublicProfileCubit>();
    final sync = publicProfile.syncStatus;
    final displayName = AccountDisplay.bestDisplayName(user);
    final provider = _providerLabel(user);
    return [
      InsetSection(
        children: [
          InsetRow(
            leading: AccountAvatar(
              photoUrl: AccountDisplay.bestPhotoUrl(user),
              fallbackLabel: AccountDisplay.avatarInitial(displayName),
              radius: 18,
            ),
            title: displayName ?? S.current.accountSignedInFallback,
            subtitle: provider == null ? null : S.current.accountSignedInWith(provider),
          ),
          InsetRow(
            icon: Icons.emoji_events_outlined,
            title: S.current.achievementsTitle,
            trailing: Icon(Icons.chevron_right, color: colors.textSecondary),
            onTap: () =>
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AchievementsScreen())),
          ),
        ],
      ),
      _sectionGap,
      InsetSection(
        children: [
          InsetRow(
            icon: Icons.sync,
            title: S.current.accountSyncNow,
            subtitle: sync.isSyncing ? S.current.accountSyncInProgress : _syncedLabel(sync),
            trailing: sync.isSyncing
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator.adaptive(strokeWidth: 2))
                : null,
            onTap: sync.isSyncing || auth.isLoading ? null : profileCubit.requestSyncNow,
          ),
        ],
      ),
      _sectionGap,
      InsetSection(
        children: [
          InsetRow(
            icon: Icons.logout,
            title: S.current.accountSignOut,
            titleColor: colors.accent,
            onTap: auth.isLoading ? null : cubit.signOut,
          ),
          InsetRow(
            icon: Icons.delete_outline,
            title: S.current.accountDeleteAction,
            titleColor: colors.bad,
            onTap: auth.isLoading ? null : _showDeleteAccountDialog,
          ),
        ],
      ),
    ];
  }

  Widget _note(final String text, final Color color) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(text, style: TextStyle(fontSize: 15, height: 20 / 15, color: color)),
  );

  bool get _supportsAppleSignIn {
    if (kIsWeb) return true;
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  }

  String? _providerLabel(final dynamic user) {
    for (final profile in user?.providerData ?? const []) {
      switch (profile.providerId) {
        case 'google.com':
          return 'Google';
        case 'apple.com':
          return 'Apple';
      }
    }
    return null;
  }

  String _syncedLabel(final SyncStatus status) {
    final ms = status.lastSuccessAtMs;
    if (ms == null) {
      return S.current.accountNotSyncedYet;
    }
    final at = DateTime.fromMillisecondsSinceEpoch(ms);
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(at),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final isToday = DateUtils.isSameDay(at, DateTime.now());
    return S.current.accountSyncedAt(isToday ? time : '${DateFormat.MMMd().format(at)}, $time');
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.icon,
    this.border,
  });

  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final Color? border;
  final VoidCallback? onPressed;

  @override
  Widget build(final BuildContext context) => SizedBox(
    height: 50,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background.withValues(alpha: 0.5),
        disabledForegroundColor: foreground.withValues(alpha: 0.6),
        side: border == null ? null : BorderSide(color: border!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 22), const SizedBox(width: 8)],
          Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    ),
  );
}
