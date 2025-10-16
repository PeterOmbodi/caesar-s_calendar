import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:caesar_puzzle/presentation/widgets/flip_flap/split_flap.dart';
import 'package:flutter/material.dart';

class SplitFlapRow extends StatelessWidget {
  const SplitFlapRow({
    super.key,
    required this.text,
    this.cardsInPack,
    this.symbolStyle,
    this.panelDecoration,
    this.tileDecoration,
    required this.tileConstraints,
  });

  final String text;
  final int? cardsInPack;
  final TextStyle? symbolStyle;
  final Decoration? panelDecoration;
  final Decoration? tileDecoration;
  final BoxConstraints tileConstraints;

  @override
  Widget build(final BuildContext context) => DecoratedBox(
    decoration:
        panelDecoration ??
        BoxDecoration(color: AppColors.current.primary, borderRadius: BorderRadius.all(Radius.circular(4))),
    child: Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: text.characters
            .map(
              (final e) => Center(
                child: SplitFlapTile(
                  symbol: e,
                  cardsInPack: cardsInPack ?? 1,
                  tileConstraints: tileConstraints,
                  symbolStyle: symbolStyle,
                  tileDecoration: tileDecoration,
                  tileType: TileInfo.number,
                ),
              ),
            )
            .toList(),
      ),
    ),
  );
}
