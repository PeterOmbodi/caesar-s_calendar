import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/pages/achievements/achievements_screen.dart';
import 'package:caesar_puzzle/presentation/pages/leaderboard/leaderboard_screen.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/widgets/controls/app_bar_icon_button.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

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
    leading: AppBarIconButton(
      icon: Icons.arrow_back,
      cupertinoIcon: CupertinoIcons.back,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () => Navigator.of(context).maybePop(),
    ),
    middle: Text(S.current.historyTitle),
    trailing: _HistoryActions(onPickDate: onPickDate),
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
    leading: const BackButton(),
    title: Text(S.current.historyTitle),
    actions: [_HistoryActions(onPickDate: onPickDate)],
  );
}

class _HistoryActions extends StatelessWidget {
  const _HistoryActions({required this.onPickDate});

  final VoidCallback onPickDate;

  @override
  Widget build(final BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      AppBarIconButton(
        icon: Icons.leaderboard_outlined,
        cupertinoIcon: Icons.leaderboard_outlined,
        label: S.current.leaderboardTitle,
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LeaderboardScreen())),
      ),
      AppBarIconButton(
        icon: Icons.emoji_events_outlined,
        cupertinoIcon: Icons.emoji_events_outlined,
        label: S.current.achievementsTitle,
        onPressed: () =>
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AchievementsScreen())),
      ),
      AppBarIconButton(
        icon: Icons.calendar_month_outlined,
        cupertinoIcon: CupertinoIcons.calendar,
        label: S.current.historyPickDate,
        onPressed: onPickDate,
      ),
    ],
  );
}
