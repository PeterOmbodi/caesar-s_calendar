import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/pages/achievements/achievements_screen.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HistoryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HistoryAppBar({super.key, required this.onPickDate});

  final VoidCallback onPickDate;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(final BuildContext context) => switch (ScreenSpec.of(context).family) {
    ChromeFamily.glass => _GlassHistoryAppBar(onPickDate: onPickDate),
    ChromeFamily.material || ChromeFamily.web => _MaterialHistoryAppBar(onPickDate: onPickDate),
  };
}

class _GlassHistoryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _GlassHistoryAppBar({required this.onPickDate});

  final VoidCallback onPickDate;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(final BuildContext context) => CupertinoNavigationBar(
    backgroundColor: GameColors.of(context).background,
    brightness: Theme.of(context).brightness,
    leading: _CupertinoHistoryNavigationButton(
      semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
      icon: CupertinoIcons.back,
      onPressed: () => Navigator.of(context).maybePop(),
    ),
    middle: Text(S.current.historyTitle),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CupertinoHistoryNavigationButton(
          semanticLabel: S.current.achievementsTitle,
          icon: Icons.emoji_events_outlined,
          onPressed: () =>
              Navigator.of(context).push(CupertinoPageRoute<void>(builder: (_) => const AchievementsScreen())),
        ),
        _CupertinoHistoryNavigationButton(
          semanticLabel: S.current.historyPickDate,
          icon: CupertinoIcons.calendar,
          onPressed: onPickDate,
        ),
      ],
    ),
  );
}

class _MaterialHistoryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _MaterialHistoryAppBar({required this.onPickDate});

  final VoidCallback onPickDate;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(final BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    leading: _HistoryBackButton(icon: Icons.arrow_back_ios_new_rounded),
    title: Text(S.current.historyTitle),
    actions: [
      _HistoryActionButton(
        tooltip: S.current.achievementsTitle,
        icon: Icons.emoji_events_outlined,
        onPressed: () =>
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AchievementsScreen())),
      ),
      _HistoryActionButton(
        tooltip: S.current.historyPickDate,
        icon: Icons.calendar_month_outlined,
        onPressed: onPickDate,
      ),
    ],
  );
}

class _HistoryBackButton extends StatelessWidget {
  const _HistoryBackButton({required this.icon});

  final IconData icon;

  @override
  Widget build(final BuildContext context) => IconButton(
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    icon: Icon(icon),
    onPressed: () => Navigator.of(context).maybePop(),
  );
}

class _HistoryActionButton extends StatelessWidget {
  const _HistoryActionButton({required this.tooltip, required this.icon, required this.onPressed});

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) => IconButton(tooltip: tooltip, icon: Icon(icon), onPressed: onPressed);
}

class _CupertinoHistoryNavigationButton extends StatelessWidget {
  const _CupertinoHistoryNavigationButton({required this.semanticLabel, required this.icon, required this.onPressed});

  final String semanticLabel;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    minimumSize: const Size.square(kMinInteractiveDimensionCupertino),
    onPressed: onPressed,
    child: Icon(icon, semanticLabel: semanticLabel),
  );
}
