import 'package:flutter/material.dart';

class PuzzleSettingsPanelController {
  const PuzzleSettingsPanelController({this.isInlinePanelVisible = false});

  final bool isInlinePanelVisible;

  PuzzleSettingsPanelController toggle({required final bool isWideScreen}) {
    if (!isWideScreen) {
      return const PuzzleSettingsPanelController();
    }
    return PuzzleSettingsPanelController(isInlinePanelVisible: !isInlinePanelVisible);
  }

  PuzzleSettingsPanelController forScreenWidth({required final bool isWideScreen}) {
    if (isWideScreen || !isInlinePanelVisible) {
      return this;
    }
    return const PuzzleSettingsPanelController();
  }

  ({double left, double right}) gameplayInsets({
    required final bool isWideScreen,
    required final double sidePanelWidth,
  }) {
    if (!isWideScreen) {
      return (left: 0, right: 0);
    }
    if (isInlinePanelVisible) {
      return (left: 0, right: sidePanelWidth);
    }
    final centeredInset = sidePanelWidth / 2;
    return (left: centeredInset, right: centeredInset);
  }

  Offset onboardingCoordinateOffset({required final bool isWideScreen, required final double sidePanelWidth}) {
    final insets = gameplayInsets(isWideScreen: isWideScreen, sidePanelWidth: sidePanelWidth);
    return Offset(insets.left, 0);
  }
}
