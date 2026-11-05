import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/widgets/glass_surface.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged, required this.semanticLabel});

  final bool value;

  /// Null disables the switch: it ignores taps and keys and is announced as disabled.
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  @override
  Widget build(final BuildContext context) {
    final onChanged = this.onChanged;
    if (ScreenSpec.of(context).family != ChromeFamily.glass) {
      return _Labeled(label: semanticLabel, child: Switch(value: value, onChanged: onChanged));
    }
    if (!GlassSurface.isLiquid(context)) {
      return _Labeled(label: semanticLabel, child: CupertinoSwitch(value: value, onChanged: onChanged));
    }
    if (onChanged != null) {
      return GlassSwitch(value: value, onChanged: onChanged, useOwnLayer: true, semanticLabel: semanticLabel);
    }
    // GlassSwitch has no disabled state.
    return Semantics(
      label: semanticLabel,
      toggled: value,
      enabled: false,
      child: ExcludeSemantics(
        child: ExcludeFocus(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.5,
              child: GlassSwitch(value: value, onChanged: (_) {}, useOwnLayer: true),
            ),
          ),
        ),
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(final BuildContext context) => MergeSemantics(
    child: Semantics(label: label, child: child),
  );
}
