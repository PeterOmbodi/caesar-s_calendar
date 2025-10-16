import 'package:flutter/material.dart';

class LetterPlate extends StatelessWidget {
  const LetterPlate({super.key, required this.symbol, required this.constraints, this.symbolStyle, this.decoration});

  final String symbol;
  final TextStyle? symbolStyle;
  final Decoration? decoration;
  final BoxConstraints constraints;

  @override
  Widget build(final BuildContext context) => Material(
    color: Colors.transparent,
    child: Container(
      constraints: constraints,
      child: DecoratedBox(
        decoration:
            decoration ??
            BoxDecoration(
              color: Theme.of(context).primaryColor,
              border: Border.all(color: symbolStyle?.color ?? Theme.of(context).textTheme.bodyLarge!.color!),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
        child: Center(child: Text(symbol, style: symbolStyle ?? Theme.of(context).textTheme.bodyLarge)),
      ),
    ),
  );
}
