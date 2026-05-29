import 'package:flutter/material.dart';

class AccountDisplay {
  static String? bestDisplayName(final dynamic user) {
    final direct = user?.displayName?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
    for (final profile in user?.providerData ?? const []) {
      final candidate = profile.displayName?.trim();
      if (candidate != null && candidate.isNotEmpty) return candidate;
    }
    return null;
  }

  static String? bestPhotoUrl(final dynamic user) {
    final direct = user?.photoURL?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
    for (final profile in user?.providerData ?? const []) {
      final candidate = profile.photoURL?.trim();
      if (candidate != null && candidate.isNotEmpty) return candidate;
    }
    return null;
  }

  static String avatarInitial(final String? displayName) {
    final normalized = displayName?.trim();
    if (normalized == null || normalized.isEmpty) return '?';
    return normalized.characters.first.toUpperCase();
  }
}

class AccountAvatar extends StatefulWidget {
  const AccountAvatar({
    super.key,
    required this.photoUrl,
    required this.fallbackLabel,
    this.radius = 22,
    this.placeholderIcon,
  });

  final String? photoUrl;
  final String fallbackLabel;
  final double radius;
  final IconData? placeholderIcon;

  @override
  State<AccountAvatar> createState() => _AccountAvatarState();
}

class _AccountAvatarState extends State<AccountAvatar> {
  static final Set<String> _failedUrls = <String>{};

  @override
  Widget build(final BuildContext context) {
    final photoUrl = widget.photoUrl;
    final size = widget.radius * 2;
    if (photoUrl == null || photoUrl.isEmpty || _failedUrls.contains(photoUrl)) {
      return CircleAvatar(
        radius: widget.radius,
        child: widget.placeholderIcon == null ? Text(widget.fallbackLabel) : Icon(widget.placeholderIcon),
      );
    }

    return CircleAvatar(
      radius: widget.radius,
      child: ClipOval(
        child: Image.network(
          photoUrl,
          width: size,
          height: size,
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
