import 'package:caesar_puzzle/presentation/auth/bloc/auth_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_display.dart';
import 'package:flutter/material.dart';

class AccountSummaryButton extends StatelessWidget {
  const AccountSummaryButton({
    super.key,
    required this.auth,
    required this.onPressed,
  });

  final AuthState auth;
  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) {
    final user = auth.user;
    final displayName = AccountDisplay.bestDisplayName(user);
    final photoUrl = AccountDisplay.bestPhotoUrl(user);
    final title = user == null
        ? auth.isLoading
            ? 'Signing in...'
            : 'Local profile'
        : displayName ?? 'Signed-in account';
    final subtitle = user == null
        ? auth.isAvailable
            ? 'Tap to sign in and sync'
            : 'Sign-in unavailable'
        : user.uid;

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              AccountAvatar(
                photoUrl: photoUrl,
                fallbackLabel: AccountDisplay.avatarInitial(displayName),
                placeholderIcon: user == null ? Icons.person_outline : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
