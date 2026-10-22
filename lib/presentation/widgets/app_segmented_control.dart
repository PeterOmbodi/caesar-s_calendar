import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/widgets/glass_surface.dart';
import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class AppSegmentedControl<T extends Object> extends StatelessWidget {
  const AppSegmentedControl({super.key, required this.segments, required this.value, required this.onChanged});

  final Map<T, String> segments;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(final BuildContext context) {
    if (!GlassSurface.isLiquid(context)) {
      return CupertinoSlidingSegmentedControl<T>(
        groupValue: value,
        children: {for (final MapEntry(:key, value: label) in segments.entries) key: Text(label)},
        onValueChanged: (final next) {
          if (next != null) onChanged(next);
        },
      );
    }
    final keys = segments.keys.toList();
    final text = GameColors.of(context).text;
    return GlassSegmentedControl(
      useOwnLayer: true,
      segments: [for (final label in segments.values) GlassSegment(label: label)],
      selectedIndex: keys.indexOf(value),
      // May fire for the current segment after a cancelled drag.
      onSegmentSelected: (final index) {
        if (keys[index] != value) onChanged(keys[index]);
      },
      selectedTextStyle: TextStyle(color: text),
      unselectedTextStyle: TextStyle(color: text.withValues(alpha: 0.6)),
    );
  }
}
