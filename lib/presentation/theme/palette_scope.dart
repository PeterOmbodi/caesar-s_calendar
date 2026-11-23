import 'package:caesar_puzzle/presentation/theme/app_palette.dart';
import 'package:material_ui/material_ui.dart';

/// The colour schemes the user can pick from; system colours are present only where the platform has them.
class PaletteScope extends InheritedWidget {
  const PaletteScope({super.key, required this.available, required super.child});

  final List<AppPalette> available;

  static List<AppPalette> of(final BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PaletteScope>()?.available ?? AppPalette.presets;

  @override
  bool updateShouldNotify(final PaletteScope oldWidget) => available != oldWidget.available;
}
