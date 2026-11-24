import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/theme/controls_theme.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

enum AppButtonVariant { filled, outlined, text }

enum AppButtonSize { large, regular }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.size = AppButtonSize.regular,
    this.icon,
    this.cupertinoIcon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;

  /// Shown instead of [icon] on the glass family.
  final IconData? cupertinoIcon;
  final bool expand;

  @override
  Widget build(final BuildContext context) {
    final controls = ControlsTheme.of(context);
    final height = size == AppButtonSize.large ? controls.largeHeight : controls.regularHeight;
    final button = ScreenSpec.of(context).family == ChromeFamily.glass
        ? _CupertinoAppButton(
            label: label,
            onPressed: onPressed,
            variant: variant,
            height: height,
            icon: cupertinoIcon ?? icon,
          )
        : _MaterialAppButton(label: label, onPressed: onPressed, variant: variant, height: height, icon: icon);
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _MaterialAppButton extends StatelessWidget {
  const _MaterialAppButton({
    required this.label,
    required this.onPressed,
    required this.variant,
    required this.height,
    required this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final double height;
  final IconData? icon;

  @override
  Widget build(final BuildContext context) {
    final style = ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(64, height)));
    final text = Text(label);
    final icon = this.icon;
    if (icon == null) {
      return switch (variant) {
        AppButtonVariant.filled => FilledButton(onPressed: onPressed, style: style, child: text),
        AppButtonVariant.outlined => OutlinedButton(onPressed: onPressed, style: style, child: text),
        AppButtonVariant.text => TextButton(onPressed: onPressed, style: style, child: text),
      };
    }
    final iconWidget = Icon(icon);
    return switch (variant) {
      AppButtonVariant.filled => FilledButton.icon(onPressed: onPressed, style: style, icon: iconWidget, label: text),
      AppButtonVariant.outlined => OutlinedButton.icon(
        onPressed: onPressed,
        style: style,
        icon: iconWidget,
        label: text,
      ),
      AppButtonVariant.text => TextButton.icon(onPressed: onPressed, style: style, icon: iconWidget, label: text),
    };
  }
}

class _CupertinoAppButton extends StatelessWidget {
  const _CupertinoAppButton({
    required this.label,
    required this.onPressed,
    required this.variant,
    required this.height,
    required this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final double height;
  final IconData? icon;

  @override
  Widget build(final BuildContext context) {
    final active = GameColors.of(context).active;
    final minimumSize = Size(height, height);
    final icon = this.icon;
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Icon(icon, size: 18),
              Flexible(child: Text(label)),
            ],
          );
    return switch (variant) {
      AppButtonVariant.filled => CupertinoButton.filled(
        onPressed: onPressed,
        color: active,
        minimumSize: minimumSize,
        child: child,
      ),
      AppButtonVariant.outlined => _CupertinoOutlinedButton(
        onPressed: onPressed,
        minimumSize: minimumSize,
        child: child,
      ),
      AppButtonVariant.text => CupertinoButton(onPressed: onPressed, minimumSize: minimumSize, child: child),
    };
  }
}

/// A tinted fill turns murky on dark backgrounds and reads as disabled, so secondary buttons get an outline.
class _CupertinoOutlinedButton extends StatelessWidget {
  const _CupertinoOutlinedButton({required this.onPressed, required this.minimumSize, required this.child});

  static const _radius = BorderRadius.all(Radius.circular(12));

  final VoidCallback? onPressed;
  final Size minimumSize;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = onPressed == null ? scheme.outline : scheme.onSecondaryContainer;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: _radius,
        border: Border.all(color: scheme.outline),
      ),
      child: CupertinoButton(
        onPressed: onPressed,
        minimumSize: minimumSize,
        borderRadius: _radius,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: foreground),
          child: IconTheme.merge(data: IconThemeData(color: foreground), child: child),
        ),
      ),
    );
  }
}
