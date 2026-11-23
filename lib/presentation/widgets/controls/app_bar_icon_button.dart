import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

class AppBarIconButton extends StatelessWidget {
  const AppBarIconButton({
    super.key,
    required this.icon,
    required this.cupertinoIcon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final IconData cupertinoIcon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(final BuildContext context) => ScreenSpec.of(context).family == ChromeFamily.glass
      ? CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size.square(kMinInteractiveDimensionCupertino),
          onPressed: onPressed,
          child: Icon(cupertinoIcon, semanticLabel: label),
        )
      : IconButton(tooltip: label, icon: Icon(icon), onPressed: onPressed);
}
