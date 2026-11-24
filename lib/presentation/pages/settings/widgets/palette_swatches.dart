import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/theme/app_palette.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/theme/palette_scope.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

extension AppPaletteIdLabel on AppPaletteId {
  String get label => switch (this) {
    AppPaletteId.classic => S.current.paletteClassic,
    AppPaletteId.purple => S.current.palettePurple,
    AppPaletteId.bronze => S.current.paletteBronze,
    AppPaletteId.laurel => S.current.paletteLaurel,
    AppPaletteId.terracotta => S.current.paletteTerracotta,
    AppPaletteId.system => S.current.paletteSystem,
  };
}

class PaletteSwatches extends StatelessWidget {
  const PaletteSwatches({super.key});

  static const double _maxSize = 36;
  static const double _minSize = 28;
  static const double _minGap = 4;

  @override
  Widget build(final BuildContext context) {
    final palettes = PaletteScope.of(context);
    final selected = context.select<SettingsCubit, AppPaletteId>((final cubit) => cubit.state.palette);
    final cubit = context.read<SettingsCubit>();
    final selectedId = AppPalette.resolve(selected, palettes).id;
    return LayoutBuilder(
      builder: (final context, final constraints) {
        final slot = constraints.maxWidth / palettes.length;
        final size = (slot - _Swatch.ringInset * 2 - _minGap).clamp(_minSize, _maxSize);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final palette in palettes)
              _Swatch(
                palette: palette,
                size: size,
                selected: palette.id == selectedId,
                onTap: () => cubit.setPalette(palette.id),
              ),
          ],
        );
      },
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.palette, required this.size, required this.selected, required this.onTap});

  static const double _ringWidth = 2;

  /// Room taken around the circle by the selection ring and its gap.
  static const double ringInset = _ringWidth + 3;

  final AppPalette palette;
  final double size;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final colors = palette.colors(Theme.of(context).brightness);
    final ring = GameColors.of(context).text;
    return Semantics(
      button: true,
      selected: selected,
      label: palette.id.label,
      child: Tooltip(
        message: palette.id.label,
        excludeFromSemantics: true,
        child: InkResponse(
          onTap: onTap,
          radius: size / 2 + 6,
          child: Container(
            padding: const EdgeInsets.all(ringInset - _ringWidth),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: selected ? ring : Colors.transparent, width: _ringWidth),
            ),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors.active, colors.active, colors.accent, colors.accent],
                  stops: const [0, 0.5, 0.5, 1],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
