import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/widgets/glass_menu.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

@immutable
class AppMenuItem {
  const AppMenuItem({
    required this.label,
    required this.icon,
    required this.cupertinoIcon,
    required this.onSelected,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final IconData cupertinoIcon;
  final VoidCallback onSelected;
  final bool destructive;
}

/// A "more" button with a menu: a popup menu on Material, a glass panel like the game's More menu on glass.
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key, required this.items});

  final List<AppMenuItem> items;

  @override
  Widget build(final BuildContext context) {
    if (ScreenSpec.of(context).family == ChromeFamily.glass) {
      return _GlassMenuButton(items: items);
    }
    final colors = GameColors.of(context);
    return PopupMenuButton<AppMenuItem>(
      icon: Icon(Icons.more_horiz, size: 22, color: colors.textSecondary),
      onSelected: (final item) => item.onSelected(),
      itemBuilder: (_) => [
        for (final item in items)
          PopupMenuItem<AppMenuItem>(
            value: item,
            child: _MenuRow(item: item, icon: item.icon),
          ),
      ],
    );
  }
}

class _GlassMenuButton extends StatelessWidget {
  const _GlassMenuButton({required this.items});

  static const double _menuWidth = 220;
  static const double _gap = 6;

  final List<AppMenuItem> items;

  Future<void> _open(final BuildContext context) async {
    final box = context.findRenderObject()! as RenderBox;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    final screen = MediaQuery.sizeOf(context);
    final opensUp = anchor.center.dy > screen.height / 2;
    final picked = await showGeneralDialog<AppMenuItem>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (final dialogContext, _, _) => Stack(
        children: [
          Positioned(
            right: screen.width - anchor.right,
            top: opensUp ? null : anchor.bottom + _gap,
            bottom: opensUp ? screen.height - anchor.top + _gap : null,
            width: _menuWidth,
            child: _GlassMenu(items: items, onPick: (final item) => Navigator.of(dialogContext).pop(item)),
          ),
        ],
      ),
      transitionBuilder: (final context, final animation, _, final child) =>
          FadeTransition(opacity: animation, child: child),
    );
    picked?.onSelected();
  }

  @override
  Widget build(final BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    minimumSize: const Size.square(kMinInteractiveDimensionCupertino),
    onPressed: () => _open(context),
    child: Icon(
      CupertinoIcons.ellipsis,
      size: 22,
      color: GameColors.of(context).textSecondary,
      semanticLabel: MaterialLocalizations.of(context).showMenuTooltip,
    ),
  );
}

class _GlassMenu extends StatelessWidget {
  const _GlassMenu({required this.items, required this.onPick});

  final List<AppMenuItem> items;
  final ValueChanged<AppMenuItem> onPick;

  @override
  Widget build(final BuildContext context) => GlassMenuPanel(
    children: [
      for (final item in items)
        GlassMenuRow(
          icon: item.cupertinoIcon,
          label: item.label,
          destructive: item.destructive,
          onTap: () => onPick(item),
        ),
    ],
  );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item, required this.icon});

  final AppMenuItem item;
  final IconData icon;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final color = item.destructive ? colors.bad : colors.text;
    return Row(
      spacing: 12,
      children: [
        Icon(icon, size: 22, color: item.destructive ? colors.bad : colors.icon),
        Expanded(
          child: Text(
            item.label,
            style: TextStyle(fontSize: 16, height: 21 / 16, color: color),
          ),
        ),
      ],
    );
  }
}
