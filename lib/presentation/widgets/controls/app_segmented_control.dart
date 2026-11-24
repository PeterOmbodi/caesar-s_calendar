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
    // The track is drawn at the control height; taps are taken over the full touch target.
    final outset = (kMinInteractiveDimension - ControlsTheme.material.regularHeight) / 2;
    final entries = segments.entries.toList();
    return SizedBox(
      height: kMinInteractiveDimension,
      child: Stack(
        children: [
          Positioned.fill(
            top: outset,
            bottom: outset,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.board,
                border: Border.all(color: colors.gridLine),
                borderRadius: BorderRadius.all(Radius.circular(radius + _inset)),
              ),
            ),
          ),
          Row(
            children: [
              for (final (index, MapEntry(:key, value: label)) in entries.indexed)
                Expanded(
                  child: _Segment(
                    label: label,
                    selected: key == value,
                    radius: radius,
                    padding: EdgeInsets.fromLTRB(
                      index == 0 ? _inset : 0,
                      outset + _inset,
                      index == entries.length - 1 ? _inset : 0,
                      outset + _inset,
                    ),
                    onTap: () {
                      if (key != value) onChanged(key);
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.radius,
    required this.padding,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final double radius;
  final EdgeInsets padding;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(radius)));
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: padding,
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
        ),
      ),
    );
  }
}
