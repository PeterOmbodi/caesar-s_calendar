import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

bool _isCupertino(final BuildContext context) => switch (Theme.of(context).platform) {
  TargetPlatform.iOS || TargetPlatform.macOS => true,
  _ => false,
};

class AdaptiveDialogAction extends StatelessWidget {
  const AdaptiveDialogAction({
    super.key,
    required this.onPressed,
    required this.child,
    this.isDefault = false,
    this.destructive = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isDefault;
  final bool destructive;

  @override
  Widget build(final BuildContext context) => _isCupertino(context)
      ? CupertinoDialogAction(
          onPressed: onPressed,
          isDefaultAction: isDefault,
          isDestructiveAction: destructive,
          child: child,
        )
      : TextButton(onPressed: onPressed, child: child);
}
