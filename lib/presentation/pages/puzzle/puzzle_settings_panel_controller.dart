
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
    if (!isWideScreen || !isInlinePanelVisible) {
      return (left: 0, right: 0);
    }
    return (left: 0, right: sidePanelWidth);
  }
}
