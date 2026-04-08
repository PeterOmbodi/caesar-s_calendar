import 'package:caesar_puzzle/infrastructure/sync/sync_status.dart';
import 'package:caesar_puzzle/presentation/auth/bloc/auth_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/profile/profile_screen.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/public_profile_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        title: const Text('Replace local sessions?'),
        content: const Text(
          'This account already has cloud sessions. If you continue, the current local sessions on this device will be lost and replaced with cloud data.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Stay guest')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Continue')),
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
          title: const Text('Delete account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This permanently deletes your cloud account and synced data from this app. '
                'You will be signed out and local data on this device will be cleared.',
              ),
              if (providerLabel != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Next, $providerLabel will ask you to confirm your identity. '
                  'Although it may look like sign-in, that step is only used to authorize account deletion.',
                ),
              ],
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: confirmed,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('I understand this cannot be undone.'),
                onChanged: (final value) => setState(() => confirmed = value ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(
              onPressed: confirmed ? () => Navigator.of(context).pop(true) : null,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: Text(providerLabel == null ? 'Delete account' : 'Continue to $providerLabel'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || shouldDelete != true) return;
    await cubit.deleteAccount();
  }

  @override
  Widget build(final BuildContext context) {
    final auth = widget.auth;
    final cubit = context.read<AuthCubit>();
    final publicProfile = context.watch<PublicProfileCubit>().state;
    final user = auth.user;
    final canStartProviderSignIn = !auth.isLoading && user == null;
    final displayName = _bestDisplayName(user);
    final photoUrl = _bestPhotoUrl(user);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Account & Sync', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (!auth.isAvailable)
          const Text('Firebase is not configured on this build. Sign-in and cloud sync are disabled.')
        else ...[
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  _AccountAvatar(photoUrl: photoUrl, fallbackLabel: _avatarInitial(displayName)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName ?? 'Signed-in account',
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(user.uid, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Text(user == null ? (auth.isLoading ? 'Signing in...' : 'Local profile') : 'User: ${user.uid}'),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Public profile'),
            subtitle: const Text('Allow other users to view your progress'),
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
              label: const Text('Sync now'),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(publicProfile.syncStatus.isSyncing ? 'Sync: syncing…' : 'Sync: idle'),
                Text(
                  'Last success: ${_lastSyncLabel(publicProfile.syncStatus)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (publicProfile.syncStatus.lastError != null)
                  Text(
                    'Last error: ${publicProfile.syncStatus.lastError}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
              ],
            ),
          ),
          if (auth.errorMessage != null) ...[
            Text(auth.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (publicProfile.errorMessage != null) ...[
            Text(publicProfile.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: canStartProviderSignIn ? cubit.signInWithGoogle : null,
                child: const Text('Continue with Google'),
              ),
              if (_supportsAppleSignIn(context))
                FilledButton(
                  onPressed: canStartProviderSignIn ? cubit.signInWithApple : null,
                  child: const Text('Continue with Apple'),
                ),
              OutlinedButton(
                onPressed: (user == null || !publicProfile.enabled)
                    ? null
                    : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileScreen(uid: user.uid))),
                child: const Text('Open profile'),
              ),
              OutlinedButton(
                onPressed: auth.isLoading || user == null ? null : cubit.signOut,
                child: const Text('Sign out'),
              ),
              OutlinedButton(
                onPressed: auth.isLoading || user == null ? null : _showDeleteAccountDialog,
                style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                child: const Text('Delete account'),
              ),
            ],
          ),
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

  String? _bestDisplayName(final dynamic user) {
    final direct = user?.displayName?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
    for (final profile in user?.providerData ?? const []) {
      final candidate = profile.displayName?.trim();
      if (candidate != null && candidate.isNotEmpty) return candidate;
    }
    return null;
  }

  String? _bestPhotoUrl(final dynamic user) {
    final direct = user?.photoURL?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
    for (final profile in user?.providerData ?? const []) {
      final candidate = profile.photoURL?.trim();
      if (candidate != null && candidate.isNotEmpty) return candidate;
    }
    return null;
  }

  String _avatarInitial(final String? displayName) {
    final normalized = displayName?.trim();
    if (normalized == null || normalized.isEmpty) return '?';
    return normalized.characters.first.toUpperCase();
  }

  String _lastSyncLabel(final SyncStatus status) {
    final last = status.lastSuccessAtMs == null ? null : DateTime.fromMillisecondsSinceEpoch(status.lastSuccessAtMs!);
    return last == null ? 'never' : '${last.toLocal()}';
  }
}

class _AccountAvatar extends StatefulWidget {
  const _AccountAvatar({required this.photoUrl, required this.fallbackLabel});

  final String? photoUrl;
  final String fallbackLabel;

  @override
  State<_AccountAvatar> createState() => _AccountAvatarState();
}

class _AccountAvatarState extends State<_AccountAvatar> {
  static final Set<String> _failedUrls = <String>{};

  @override
  Widget build(final BuildContext context) {
    final photoUrl = widget.photoUrl;
    if (photoUrl == null || photoUrl.isEmpty || _failedUrls.contains(photoUrl)) {
      return CircleAvatar(radius: 22, child: Text(widget.fallbackLabel));
    }

    return CircleAvatar(
      radius: 22,
      child: ClipOval(
        child: Image.network(
          photoUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (final context, final error, final stackTrace) {
            _failedUrls.add(photoUrl);
            return Center(child: Text(widget.fallbackLabel));
          },
        ),
      ),
    );
  }
}
