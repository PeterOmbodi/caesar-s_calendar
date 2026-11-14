import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Page frame of the race lobby and room: the platform's navigation bar and content of limited width.
class RaceScaffold extends StatelessWidget {
  const RaceScaffold({super.key, required this.title, required this.child});

  static const double maxContentWidth = 480;

  final String title;
  final Widget child;

  @override
  Widget build(final BuildContext context) => Scaffold(
    backgroundColor: GameColors.of(context).background,
    appBar: _RaceAppBar(title: title),
    body: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: child),
        ),
      ),
    ),
  );
}

class _RaceAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _RaceAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(final BuildContext context) {
    if (ScreenSpec.of(context).family != ChromeFamily.glass) {
      return AppBar(leading: const BackButton(), title: Text(title));
    }
    return CupertinoNavigationBar(
      backgroundColor: GameColors.of(context).background,
      brightness: Theme.of(context).brightness,
      border: null,
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size.square(kMinInteractiveDimensionCupertino),
        onPressed: () => Navigator.of(context).maybePop(),
        child: Icon(CupertinoIcons.back, semanticLabel: MaterialLocalizations.of(context).backButtonTooltip),
      ),
      middle: Text(title),
    );
  }
}
