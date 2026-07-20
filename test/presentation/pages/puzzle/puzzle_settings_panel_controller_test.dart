import 'package:caesar_puzzle/presentation/pages/puzzle/puzzle_settings_panel_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toggles inline settings panel on wide screens', () {
    const controller = PuzzleSettingsPanelController();

    final opened = controller.toggle(isWideScreen: true);
    final closed = opened.toggle(isWideScreen: true);

    expect(opened.isInlinePanelVisible, isTrue);
    expect(closed.isInlinePanelVisible, isFalse);
  });

  test('closes inline settings panel when screen becomes narrow', () {
    const controller = PuzzleSettingsPanelController(isInlinePanelVisible: true);

    final updated = controller.forScreenWidth(isWideScreen: false);

    expect(updated.isInlinePanelVisible, isFalse);
  });

  test('centers gameplay area when wide inline panel is closed', () {
    const controller = PuzzleSettingsPanelController();

    final insets = controller.gameplayInsets(isWideScreen: true, sidePanelWidth: 340);

    expect(insets.left, 170);
    expect(insets.right, 170);
  });

  test('moves gameplay area left when wide inline panel is open', () {
    const controller = PuzzleSettingsPanelController(isInlinePanelVisible: true);

    final insets = controller.gameplayInsets(isWideScreen: true, sidePanelWidth: 340);

    expect(insets.left, 0);
    expect(insets.right, 340);
  });

  test('uses full width gameplay area on narrow screens', () {
    const controller = PuzzleSettingsPanelController(isInlinePanelVisible: true);

    final insets = controller.gameplayInsets(isWideScreen: false, sidePanelWidth: 340);

    expect(insets.left, 0);
    expect(insets.right, 0);
  });

  test('uses gameplay left inset as onboarding coordinate offset', () {
    const controller = PuzzleSettingsPanelController();

    final offset = controller.onboardingCoordinateOffset(isWideScreen: true, sidePanelWidth: 340);

    expect(offset.dx, 170);
    expect(offset.dy, 0);
  });
}
