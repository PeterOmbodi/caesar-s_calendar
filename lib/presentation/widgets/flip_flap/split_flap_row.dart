import 'package:caesar_puzzle/presentation/theme/theme.dart';
import 'package:caesar_puzzle/presentation/widgets/flip_flap/split_flap.dart';
import 'package:flutter/material.dart';

class SplitFlapPanel extends StatelessWidget {
  SplitFlapPanel({
    super.key,
    required this.text,
    this.cardsInPack,
    this.symbolStyle,
    this.panelDecoration,
    this.tileDecoration,
    required this.tileConstraints,
    this.tileType = TileInfo.number,
  }) : splittedText = tileType == TileInfo.text ? [text] : text.characters.toList();

  final String text;
  final int? cardsInPack;
  final TextStyle? symbolStyle;
  final Decoration? panelDecoration;
  final Decoration? tileDecoration;
  final BoxConstraints tileConstraints;
  final TileInfo tileType;
  late final List<String> splittedText;

  @override
  Widget build(final BuildContext context) {
    final theme = SplitFlapTheme.of(context);

    return DecoratedBox(
      decoration: panelDecoration ?? theme.panelDecoration,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: splittedText
              .map(
                (final e) => SplitFlapTile(
                  text: e,
                  cardsInPack: cardsInPack ?? 1,
                  tileConstraints: tileConstraints,
                  symbolStyle: symbolStyle ?? theme.symbolStyle,
                  tileDecoration: tileDecoration ?? theme.tileDecoration,
                  tileType: tileType,
                  useShortestWay: false,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
