import 'package:flutter/material.dart';

class FlapUnit extends StatelessWidget {
  const FlapUnit({
    super.key,
    required this.text,
    required this.constraints,
    this.textStyle,
    this.decoration,
  });

  final String text;
  final TextStyle? textStyle;
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
              border: Border.all(
                color:
                    textStyle?.color ??
                    Theme.of(context).textTheme.bodyLarge!.color!,
              ),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
        child: Center(
          child: Text(
            text,
            style: textStyle ?? Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    ),
  );
}
