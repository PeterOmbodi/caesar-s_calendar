import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/widgets/controls/app_bar_icon_button.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Page frame of the race lobby and room: the platform's navigation bar and content of limited width.
class RaceScaffold extends StatelessWidget {
  const RaceScaffold({super.key, required this.title, required this.child, this.trailing});

  static const double maxContentWidth = 480;

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(final BuildContext context) => Scaffold(
    backgroundColor: GameColors.of(context).background,
    appBar: _RaceAppBar(title: title, trailing: trailing),
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
  const _RaceAppBar({required this.title, required this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(final BuildContext context) {
    final trailing = this.trailing;
    if (ScreenSpec.of(context).family != ChromeFamily.glass) {
      return AppBar(
        leading: const BackButton(),
        title: Text(title),
        actions: [
          if (trailing != null) Padding(padding: const EdgeInsetsDirectional.only(end: 16), child: trailing),
        ],
      );
    }
    return CupertinoNavigationBar(
      backgroundColor: GameColors.of(context).background,
      brightness: Theme.of(context).brightness,
      border: null,
      leading: AppBarIconButton(
        icon: Icons.arrow_back,
        cupertinoIcon: CupertinoIcons.back,
        label: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      middle: Text(title),
      trailing: trailing,
    );
  }
}
