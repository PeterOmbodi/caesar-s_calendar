import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:material_ui/material_ui.dart';

/// Sizes shared by the app's own controls, per platform family.
@immutable
class ControlsTheme {
  const ControlsTheme({required this.largeHeight, required this.regularHeight, required this.fieldRadius});

  factory ControlsTheme.of(final BuildContext context) =>
      ScreenSpec.of(context).family == ChromeFamily.glass ? cupertino : material;

  static const material = ControlsTheme(largeHeight: 48, regularHeight: 40, fieldRadius: 12);
  static const cupertino = ControlsTheme(largeHeight: 50, regularHeight: 44, fieldRadius: 16);

  final double largeHeight;
  final double regularHeight;
  final double fieldRadius;
}
