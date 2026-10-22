import 'package:caesar_puzzle/presentation/widgets/glass_surface.dart';
import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged, this.semanticLabel});

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;

  @override
  Widget build(final BuildContext context) {
    if (!GlassSurface.isLiquid(context)) {
      return CupertinoSwitch(value: value, onChanged: onChanged);
    }
    return GlassSwitch(value: value, onChanged: onChanged, useOwnLayer: true, semanticLabel: semanticLabel);
  }
}
