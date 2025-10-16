import 'dart:math';

import 'package:caesar_puzzle/presentation/widgets/flip_flap/letter_plate.dart';
import 'package:flutter/material.dart';

enum TileInfo { character, number, special, mixed }

class SplitFlapTile extends StatefulWidget {
  const SplitFlapTile({
    super.key,
    this.cardsInPack = 1,
    required this.symbol,
    this.symbolStyle,
    this.tileDecoration,
    required this.tileConstraints,
    this.tileType = TileInfo.mixed,
  });

  final String symbol;
  final TileInfo tileType;
  final int cardsInPack;
  final TextStyle? symbolStyle;
  final Decoration? tileDecoration;
  final BoxConstraints tileConstraints;

  @override
  State<SplitFlapTile> createState() => _SplitFlapTileState();
}

class _SplitFlapTileState extends State<SplitFlapTile>
    with TickerProviderStateMixin {
  final _random = Random();
  late AnimationController _controller;
  late Animation _animation;

  List _charCodes = <int>[];
  bool _secondStage = false;
  int _currentCode = 65;
  int _currentIndex = 0;

  int get nextCode => _charCodes[nextIndex];

  int get nextIndex {
    final next = _currentIndex + 1;
    return next < _charCodes.length ? next : 0;
  }

  int get targetCode => widget.symbol.toUpperCase().codeUnitAt(0);

  @override
  void initState() {
    super.initState();

    _currentCode = targetCode;
    _currentIndex = 0;
    _charCodes = [targetCode];
    _controller =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 180),
          )
          ..addStatusListener(_nextStep)
          ..addListener(() {
            //ignore: no-empty-block
            setState(() {});
          });
    _animation = Tween(begin: 0, end: pi / 2).animate(_controller);
  }

  @override
  void didUpdateWidget(final SplitFlapTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol) {
      final prevCode = oldWidget.symbol.toUpperCase().codeUnitAt(0);
      _currentCode = prevCode;
      _currentIndex = 0;
      final flipsPlanned = widget.cardsInPack.clamp(1, 1 << 30);
      final randomCount = flipsPlanned - 1;
      _charCodes = [
        prevCode,
        if (randomCount > 0)
          ...List<int>.generate(
            randomCount,
            (final i) => _randBetweenExcept(widget.tileType, targetCode),
          ),
        targetCode,
      ];
      if (!_controller.isAnimating) {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final nextChar = String.fromCharCode(nextCode);
    final currentChar = String.fromCharCode(_currentCode);
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 0.495,
                    child: LetterPlate(
                      symbol: nextChar,
                      constraints: widget.tileConstraints,
                      decoration: widget.tileDecoration,
                      symbolStyle: widget.symbolStyle,
                    ),
                  ),
                ),
                Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.identity()
                    ..setEntry(2, 2, 0.005)
                    ..rotateX(_secondStage ? pi / 2 : _animation.value / 1),
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: 0.495,
                      child: LetterPlate(
                        symbol: currentChar,
                        constraints: widget.tileConstraints,
                        decoration: widget.tileDecoration,
                        symbolStyle: widget.symbolStyle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(color: Theme.of(context).primaryColor, height: 0.5),
            Stack(
              children: [
                ClipRect(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    heightFactor: 0.495,
                    child: LetterPlate(
                      symbol: currentChar,
                      constraints: widget.tileConstraints,
                      decoration: widget.tileDecoration,
                      symbolStyle: widget.symbolStyle,
                    ),
                  ),
                ),
                Transform(
                  alignment: Alignment.topCenter,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.005)
                    ..rotateX(_secondStage ? -_animation.value / 1 : pi / 2),
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      heightFactor: 0.495,
                      child: LetterPlate(
                        symbol: nextChar,
                        constraints: widget.tileConstraints,
                        decoration: widget.tileDecoration,
                        symbolStyle: widget.symbolStyle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _nextStep(final AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _secondStage = true;
      _controller.reverse();
    }
    if (status == AnimationStatus.dismissed) {
      _currentCode = nextCode;
      _currentIndex = nextIndex;
      _secondStage = false;
      if (_currentCode != targetCode) {
        _controller.forward();
      }
    }
  }

  int _randBetweenExcept(final TileInfo tileType, final int except) {
    final (int min, int max) = switch (tileType) {
      TileInfo.character => (65, 90), // 'A'..'Z'
      TileInfo.number => (48, 57), // '0'..'9'
      TileInfo.special => (33, 47), // '!'..'/'
      TileInfo.mixed => (33, 126), // '!'..'~' (127 — DEL)
    };
    final result = min + _random.nextInt(max - min);
    return result == except ? _randBetweenExcept(tileType, except) : result;
  }
}
