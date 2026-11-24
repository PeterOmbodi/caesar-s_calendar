import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/widgets/glass_surface.dart';
import 'package:material_ui/material_ui.dart';

/// The look of the app's glass menus; callers position it themselves.
class GlassMenuPanel extends StatelessWidget {
  const GlassMenuPanel({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(final BuildContext context) => GlassSurface(
    borderRadius: const BorderRadius.all(Radius.circular(22)),
    color: GameColors.of(context).menu,
    child: Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    ),
  );
}

class GlassMenuRow extends StatelessWidget {
  const GlassMenuRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.destructive = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool destructive;
  final Widget? trailing;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final trailing = this.trailing;
    final textColor = !enabled
        ? colors.iconDisabled
        : destructive
        ? colors.bad
        : colors.text;
    final iconColor = !enabled
        ? colors.iconDisabled
        : destructive
        ? colors.bad
        : colors.icon;
    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          spacing: 12,
          children: [
            Icon(icon, size: 22, color: iconColor),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 16, height: 21 / 16, color: textColor),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
