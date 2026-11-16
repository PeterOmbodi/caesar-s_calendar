import 'package:app_links/app_links.dart';
import 'package:caesar_puzzle/application/race/race_room_code.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Room codes from links that open the app: the web version's address, or a Universal Link / App Link on a phone.
class RoomLinks {
  RoomLinks() : _appLinks = kIsWeb ? null : AppLinks();

  final AppLinks? _appLinks;

  /// The code of the link that launched the app, if any.
  Future<String?> initialCode() async {
    final appLinks = _appLinks;
    final link = appLinks == null ? Uri.base : await appLinks.getInitialLink();
    return link == null ? null : RaceRoomCode.fromLink(link);
  }

  /// Codes of links opened while the app runs. On a phone the launching link may come here too.
  Stream<String> get codes {
    final appLinks = _appLinks;
    if (appLinks == null) {
      return const Stream.empty();
    }
    return appLinks.uriLinkStream.map(RaceRoomCode.fromLink).where((final code) => code != null).cast<String>();
  }
}
