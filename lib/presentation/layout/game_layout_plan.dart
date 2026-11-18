import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/chrome/game_chrome.dart';
import 'package:caesar_puzzle/presentation/services/layout_service.dart';
import 'package:flutter/widgets.dart';

@immutable
class GameLayoutPlan {
  const GameLayoutPlan._({
    required this.isHeaderBesideBoard,
    required this.isLandscape,
    required this.contentInsets,
    required this.trayTopInset,
    required this.trayStartInset,
    required this.reserved,
    required this.sidePanelOnLeft,
  });

  factory GameLayoutPlan.of(
    final BuildContext context,
    final Size size, {
    final double headerHeight = 0,
    final bool wideRail = false,
    final double sidePanelWidth = 0,
    final bool sidePanelOnLeft = true,
  }) {
    final spec = ScreenSpec.of(context);
    final reserved = GameChrome.reservedInsets(context, wideRail: wideRail);
    final aboveAndBelow = EdgeInsets.only(top: headerHeight, bottom: LayoutService.statusLineExtent);
    bool isLandscapeWith(final EdgeInsets insets) {
      final room = (reserved + insets).deflateSize(size);
      return room.width - sidePanelWidth > room.height;
    }

    // Beside the board only while the board and the tray still stand side by side.
    final isHeaderBesideBoard =
        spec.window == WindowClass.compact && spec.isLandscape && isLandscapeWith(EdgeInsets.zero);
    final headerInsets = isHeaderBesideBoard ? EdgeInsets.zero : aboveAndBelow;
    final isLandscape = isLandscapeWith(headerInsets);
    final sidePanelInsets = !isLandscape || sidePanelWidth == 0
        ? EdgeInsets.zero
        : sidePanelOnLeft
        ? EdgeInsets.only(left: sidePanelWidth)
        : EdgeInsets.only(right: sidePanelWidth);
    return GameLayoutPlan._(
      isHeaderBesideBoard: isHeaderBesideBoard,
      isLandscape: isLandscape,
      contentInsets: headerInsets + reserved + sidePanelInsets,
      trayTopInset: isHeaderBesideBoard ? headerHeight : 0,
      trayStartInset: isLandscape ? 0 : sidePanelWidth,
      reserved: reserved,
      sidePanelOnLeft: sidePanelOnLeft,
    );
  }

  final bool isHeaderBesideBoard;

  final bool isLandscape;

  final EdgeInsets contentInsets;

  final double trayTopInset;
  final double trayStartInset;

  final EdgeInsets reserved;

  final bool sidePanelOnLeft;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is GameLayoutPlan &&
          other.isHeaderBesideBoard == isHeaderBesideBoard &&
          other.isLandscape == isLandscape &&
          other.contentInsets == contentInsets &&
          other.trayTopInset == trayTopInset &&
          other.trayStartInset == trayStartInset &&
          other.reserved == reserved &&
          other.sidePanelOnLeft == sidePanelOnLeft;

  @override
  int get hashCode => Object.hash(
    isHeaderBesideBoard,
    isLandscape,
    contentInsets,
    trayTopInset,
    trayStartInset,
    reserved,
    sidePanelOnLeft,
  );
}
