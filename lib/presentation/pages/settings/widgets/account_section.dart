import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/infrastructure/sync/sync_status.dart';
import 'package:caesar_puzzle/presentation/auth/bloc/auth_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/profile/profile_screen.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/public_profile_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_display.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

const _webVersionUri = 'https://peterombodi.github.io/caesar-s_calendar/';

class AccountSection extends StatefulWidget {
  const AccountSection({required this.auth, super.key});

  final AuthState auth;

  @override
  State<AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends State<AccountSection> {
  @override
  void initState() {
    super.initState();
  }

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
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (final context) => AlertDialog(
        title: Text(S.current.accountCloudReplaceTitle),
        content: Text(S.current.accountCloudReplaceMessage),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(S.current.accountCloudReplaceCancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(S.current.accountCloudReplaceContinue)),
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
    final providerLabel = _deleteConfirmationProviderLabel(widget.auth.user);
    var confirmed = false;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (final context) => StatefulBuilder(
        builder: (final context, final setState) => AlertDialog(
          title: Text(S.current.accountDeleteTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.current.accountDeleteMessage),
              if (providerLabel != null) ...[
                const SizedBox(height: 12),
                Text(S.current.accountDeleteConfirmIdentityMessage(providerLabel)),
              ],
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: confirmed,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(S.current.accountUnderstandDelete),
                onChanged: (final value) => setState(() => confirmed = value ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(S.current.historySessionDialogCancel)),
            FilledButton(
              onPressed: confirmed ? () => Navigator.of(context).pop(true) : null,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: Text(providerLabel == null ? S.current.accountDeleteAction : S.current.accountDeleteContinueToProvider(providerLabel)),
            ),
          ],
        ),
      ),
    );
    if (!mounted || shouldDelete != true) return;
    await cubit.deleteAccount();
  }

  Future<void> _openWebVersion() async {
    final uri = Uri.parse(_webVersionUri);
    final didLaunch = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted || didLaunch) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.current.accountOpenWebVersionError)));
  }

  @override
  Widget build(final BuildContext context) {
    final auth = widget.auth;
    final cubit = context.read<AuthCubit>();
    final publicProfile = context.watch<PublicProfileCubit>().state;
    final user = auth.user;
    final canStartProviderSignIn = !auth.isLoading && user == null;
    final displayName = AccountDisplay.bestDisplayName(user);
    final photoUrl = AccountDisplay.bestPhotoUrl(user);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.current.accountAndSyncTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(S.current.accountAndSyncDescription, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        if (!auth.isAvailable)
          Text(S.current.accountFirebaseUnavailable)
        else ...[
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  AccountAvatar(photoUrl: photoUrl, fallbackLabel: AccountDisplay.avatarInitial(displayName)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName ?? S.current.accountSignedInFallback,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(S.current.accountPublicProfileTitle),
            subtitle: Text(S.current.accountPublicProfileSubtitle),
            value: publicProfile.enabled,
            onChanged: (user == null || publicProfile.isUpdating || publicProfile.isLoading)
                ? null
                : context.read<PublicProfileCubit>().toggleEnabled,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: user == null || auth.isLoading ? null : context.read<PublicProfileCubit>().requestSyncNow,
              icon: const Icon(Icons.cloud_sync),
              label: Text(S.current.accountSyncNow),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(publicProfile.syncStatus.isSyncing ? S.current.accountSyncSyncing : S.current.accountSyncIdle),
                Text(
                  S.current.accountSyncLastSuccess(_lastSyncLabel(publicProfile.syncStatus)),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (publicProfile.syncStatus.lastError != null)
                  Text(
                    S.current.accountSyncLastError(publicProfile.syncStatus.lastError!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
              ],
            ),
          ),
          if (auth.errorMessage != null) ...[Text(auth.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error))],
          if (publicProfile.errorMessage != null) ...[
            Text(publicProfile.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_supportsAppleSignIn(context))
                FilledButton(
                  onPressed: canStartProviderSignIn ? cubit.signInWithApple : null,
                  child: Text(S.current.accountContinueWithApple),
                ),
              FilledButton(
                onPressed: canStartProviderSignIn ? cubit.signInWithGoogle : null,
                child: Text(S.current.accountContinueWithGoogle),
              ),
              OutlinedButton(
                onPressed: (user == null || !publicProfile.enabled)
                    ? null
                    : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileScreen(uid: user.uid))),
                child: Text(S.current.accountOpenProfile),
              ),
              OutlinedButton(onPressed: auth.isLoading || user == null ? null : cubit.signOut, child: Text(S.current.accountSignOut)),
              OutlinedButton(
                onPressed: auth.isLoading || user == null ? null : _showDeleteAccountDialog,
                style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                child: Text(S.current.accountDeleteAction),
              ),
            ],
          ),
          if (!kIsWeb) ...[
            const SizedBox(height: 12),
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _openWebVersion,
                icon: const Icon(Icons.open_in_new),
                label: Text(S.current.accountOpenWebVersion),
              ),
            ),
          ],
        ],
      ],
    );
  }

  bool _supportsAppleSignIn(final BuildContext context) {
    if (kIsWeb) return true;
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  }

  String? _deleteConfirmationProviderLabel(final dynamic user) {
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

  String _lastSyncLabel(final SyncStatus status) {
    final last = status.lastSuccessAtMs == null ? null : DateTime.fromMillisecondsSinceEpoch(status.lastSuccessAtMs!);
    return last == null ? S.current.accountSyncNever : '${last.toLocal()}';
  }
}
