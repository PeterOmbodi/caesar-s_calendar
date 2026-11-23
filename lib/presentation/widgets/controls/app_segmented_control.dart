import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/theme/controls_theme.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/widgets/glass_surface.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';

class AppSegmentedControl<T extends Object> extends StatelessWidget {
  const AppSegmentedControl({super.key, required this.segments, required this.value, required this.onChanged});

  final Map<T, String> segments;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(final BuildContext context) {
    if (ScreenSpec.of(context).family != ChromeFamily.glass) {
      return _MaterialSegmentedControl(segments: segments, value: value, onChanged: onChanged);
    }
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

class _MaterialSegmentedControl<T extends Object> extends StatelessWidget {
  const _MaterialSegmentedControl({required this.segments, required this.value, required this.onChanged});

  static const double _inset = 3;

  final Map<T, String> segments;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final radius = ControlsTheme.material.selectionRadius;
    return Container(
      height: ControlsTheme.material.regularHeight,
      padding: const EdgeInsets.all(_inset),
      decoration: BoxDecoration(
        color: colors.board,
        border: Border.all(color: colors.gridLine),
        borderRadius: BorderRadius.all(Radius.circular(radius + _inset)),
      ),
      child: Row(
        children: [
          for (final MapEntry(:key, value: label) in segments.entries)
            Expanded(
              child: _Segment(
                label: label,
                selected: key == value,
                radius: radius,
                onTap: () {
                  if (key != value) onChanged(key);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.selected, required this.radius, required this.onTap});

  final String label;
  final bool selected;
  final double radius;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(radius)));
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.secondaryContainer : Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
