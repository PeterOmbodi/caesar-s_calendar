import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

typedef StoreLink = ({String title, String? subtitle, IconData icon, Uri? url});

/// App stores offered in the web version: the visitor's platform, or both on a desktop.
List<StoreLink> webStoreLinks() {
  if (!kIsWeb) {
    return const [];
  }
  final StoreLink play = (
    title: 'Google Play',
    subtitle: null,
    icon: Icons.shop_outlined,
    url: Uri.parse('https://play.google.com/store/apps/details?id=com.peter_ombodi.caesar_puzzle'),
  );
  final StoreLink appStore = (title: 'App Store', subtitle: S.current.storeComingSoon, icon: Icons.apple, url: null);
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => [play],
    TargetPlatform.iOS => [appStore],
    _ => [play, appStore],
  };
}

Future<void> openStoreLink(final StoreLink link) async {
  final url = link.url;
  if (url != null) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
