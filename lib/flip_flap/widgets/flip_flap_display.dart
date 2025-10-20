import 'package:caesar_puzzle/flip_flap/split_flap_theme.dart';
import 'package:caesar_puzzle/flip_flap/widgets/flap_display.dart';
import 'package:flutter/material.dart';

class FlipFlapDisplay extends StatelessWidget {
  FlipFlapDisplay({
    super.key,
    required this.text,
    this.cardsInPack,
    this.symbolStyle,
    this.panelDecoration,
    this.tileDecoration,
    required this.tileConstraints,
    this.tileType = DisplayType.number,
  }) : splittedText = tileType == DisplayType.text
           ? [text]
           : text.characters.toList();

  final String text;
  final int? cardsInPack;
  final TextStyle? symbolStyle;
  final Decoration? panelDecoration;
  final Decoration? tileDecoration;
  final BoxConstraints tileConstraints;
  final DisplayType tileType;
  late final List<String> splittedText;

  @override
  Widget build(final BuildContext context) {
    final theme = FlipFlapTheme.of(context);

    return DecoratedBox(
      decoration: panelDecoration ?? theme.panelDecoration,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: splittedText
              .map(
                (final e) => FlapDisplay(
                  text: e,
                  cardsInPack: cardsInPack ?? 1,
                  unitConstraints: tileConstraints,
                  textStyle: symbolStyle ?? theme.symbolStyle,
                  unitDecoration: tileDecoration ?? theme.tileDecoration,
                  displayType: tileType,
                  useShortestWay: false,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
