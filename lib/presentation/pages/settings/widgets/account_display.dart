import 'package:caesar_puzzle/application/leaderboard/nickname_generator.dart';
import 'package:material_ui/material_ui.dart';

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

  /// The account name, or the nickname the player has in rankings when the provider gave none.
  static String? nameOrNickname(final dynamic user) {
    if (user == null) return null;
    return bestDisplayName(user) ?? NicknameGenerator.fromUid(user.uid as String);
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

  /// The first letters of the first two words: "Swift Otter 47" is "SO".
  static String avatarInitials(final String name) {
    final words = name.split(RegExp(r'\s+')).where((final w) => w.isNotEmpty).take(2);
    final initials = words.map((final w) => w.characters.first.toUpperCase()).join();
    return initials.isEmpty ? '?' : initials;
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
    this.placeholderIconSize,
    this.backgroundColor,
    this.labelStyle,
  });

  final String? photoUrl;
  final String fallbackLabel;
  final double radius;
  final IconData? placeholderIcon;
  final double? placeholderIconSize;

  /// Behind the label when there is no photo.
  final Color? backgroundColor;
  final TextStyle? labelStyle;

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
        backgroundColor: widget.backgroundColor,
        child: widget.placeholderIcon == null
            ? Text(widget.fallbackLabel, style: widget.labelStyle)
            : Icon(widget.placeholderIcon, size: widget.placeholderIconSize),
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
            return Center(child: Text(widget.fallbackLabel, style: widget.labelStyle));
          },
        ),
      ),
    );
  }
}
