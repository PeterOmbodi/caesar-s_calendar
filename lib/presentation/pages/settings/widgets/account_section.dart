import 'package:caesar_puzzle/infrastructure/achievements/public_profile_service.dart';
import 'package:caesar_puzzle/infrastructure/sync/sync_status.dart';
import 'package:caesar_puzzle/infrastructure/sync/sync_status_service.dart';
import 'package:caesar_puzzle/injection.dart';
import 'package:caesar_puzzle/presentation/auth/bloc/auth_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/profile/profile_screen.dart';
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
  bool? _publicEnabled;
  bool _updatingPublic = false;

  PublicProfileService get _profiles => getIt<PublicProfileService>();
  SyncStatusService get _syncStatus => getIt<SyncStatusService>();

  @override
  void initState() {
    super.initState();
    _loadPublicEnabled();
  }

  Future<void> _loadPublicEnabled() async {
    final value = await _profiles.isEnabled();
    if (!mounted) return;
    setState(() => _publicEnabled = value);
  }

  @override
  void didUpdateWidget(covariant final AccountSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.auth.user?.uid != widget.auth.user?.uid) {
      _loadPublicEnabled();
    }
    final previous = oldWidget.auth.pendingAccountSwitch;
    final current = widget.auth.pendingAccountSwitch;
    if (current != null && previous != current) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showAccountSwitchDialog(current);
      });
    }
  }

  Future<void> _showAccountSwitchDialog(final AccountSwitchRequest request) async {
    final cubit = context.read<AuthCubit>();
    final shouldSwitch = await showDialog<bool>(
      context: context,
      builder: (final context) => AlertDialog(
        title: Text('Switch to existing ${request.providerKind.label} account?'),
        content: Text(
          'This ${request.providerKind.label} account is already linked to another profile. '
          'If you continue, this device will switch to that cloud profile and current local guest data may be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Switch account'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (shouldSwitch == true) {
      await cubit.confirmAccountSwitch();
      return;
    }
    cubit.cancelAccountSwitch();
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
                'You will be signed out and switched to a fresh guest profile on this device.',
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
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: confirmed ? () => Navigator.of(context).pop(true) : null,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: Text(
                providerLabel == null ? 'Delete account' : 'Continue to $providerLabel',
              ),
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
    final user = auth.user;
    final isAnonymous = user?.isAnonymous ?? true;
    final canStartProviderSignIn = !auth.isLoading && (user == null || isAnonymous);
    final displayName = _bestDisplayName(user);
    final photoUrl = _bestPhotoUrl(user);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Account & Sync', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (!auth.isAvailable)
          const Text(
            'Firebase is not configured on this build. Sign-in and cloud sync are disabled.',
          )
        else ...[
          if (user != null && !isAnonymous)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  _AccountAvatar(
                    photoUrl: photoUrl,
                    fallbackLabel: _avatarInitial(displayName),
                  ),
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
                        Text(
                          user.uid,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Text(
            user == null
                ? (auth.isLoading ? 'Signing in...' : 'Signed out on this device.')
                : 'User: ${user.uid}${isAnonymous ? ' (guest)' : ''}',
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Public profile'),
            subtitle: const Text('Allow other users to view your progress by UID.'),
            value: _publicEnabled ?? false,
            onChanged: (user == null || _updatingPublic)
                ? null
                : (final value) async {
                    setState(() {
                      _publicEnabled = value;
                      _updatingPublic = true;
                    });
                    await _profiles.setEnabled(value);
                    if (!mounted) return;
                    setState(() => _updatingPublic = false);
                  },
          ),
          StreamBuilder<SyncStatus>(
            stream: _syncStatus.stream,
            initialData: _syncStatus.state,
            builder: (final context, final snap) {
              final s = snap.data ?? SyncStatus.initial();
              final last = s.lastSuccessAtMs == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(s.lastSuccessAtMs!);
              final lastLabel = last == null ? 'never' : '${last.toLocal()}';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.isSyncing ? 'Sync: syncing…' : 'Sync: idle'),
                    Text('Last success: $lastLabel', style: Theme.of(context).textTheme.bodySmall),
                    if (s.lastError != null)
                      Text(
                        'Last error: ${s.lastError}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                  ],
                ),
              );
            },
          ),
          if (auth.errorMessage != null) ...[
            Text(auth.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
                onPressed: (user == null || !(_publicEnabled ?? false))
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ProfileScreen(uid: user.uid)),
                      ),
                child: const Text('Open profile'),
              ),
              OutlinedButton(
                onPressed: auth.isLoading || user == null || isAnonymous ? null : cubit.signOut,
                child: const Text('Sign out'),
              ),
              OutlinedButton(
                onPressed: auth.isLoading || user == null || isAnonymous ? null : _showDeleteAccountDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete account'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  bool _supportsAppleSignIn(final BuildContext context) {
    if (kIsWeb) return false;
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
}

class _AccountAvatar extends StatefulWidget {
  const _AccountAvatar({
    required this.photoUrl,
    required this.fallbackLabel,
  });

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
      return CircleAvatar(
        radius: 22,
        child: Text(widget.fallbackLabel),
      );
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
            return Center(
              child: Text(widget.fallbackLabel),
            );
          },
        ),
      ),
    );
  }
}
