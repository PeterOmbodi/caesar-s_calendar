import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/help/gesture_demo.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/actions/game_action.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/actions/game_action_visuals.dart';
import 'package:flutter/material.dart';

@immutable
class HelpItem {
  const HelpItem({required this.icon, required this.title, required this.body, this.shortcut, this.demo});

  /// Same icon, label and shortcut as in the action bar.
  HelpItem.action(final GameActionId id, this.body, {required final bool apple, required final bool hasKeyboard})
    : icon = id.icon,
      title = id.label,
      shortcut = hasKeyboard ? id.shortcutLabel(apple: apple) : null,
      demo = null;

  final IconData icon;
  final String title;
  final String body;
  final String? shortcut;
  final GestureDemoKind? demo;
}

@immutable
class HelpSection {
  const HelpSection({required this.items, this.title, this.footer});

  final String? title;
  final List<HelpItem> items;
  final String? footer;
}

List<HelpSection> howToPlaySections({required final bool apple, required final bool hasKeyboard}) {
  HelpItem action(final GameActionId id, final String body) =>
      HelpItem.action(id, body, apple: apple, hasKeyboard: hasKeyboard);

  return [
    HelpSection(
      items: [
        HelpItem(
          icon: Icons.event_available,
          title: S.current.howToPlayGoalTitle,
          body: S.current.howToPlayGoalDescription,
        ),
      ],
      footer: S.current.howToPlayGoalDailyChange,
    ),
    HelpSection(
      title: S.current.helpGesturesTitle,
      items: [
        HelpItem(
          icon: Icons.pan_tool_alt_outlined,
          title: S.current.helpDragTitle,
          body: S.current.helpDragBody,
          demo: GestureDemoKind.drag,
        ),
        HelpItem(
          icon: Icons.draw_outlined,
          title: S.current.helpDrawTitle,
          body: S.current.helpDrawBody,
          demo: GestureDemoKind.draw,
        ),
        HelpItem(
          icon: Icons.touch_app_outlined,
          title: S.current.helpSelectTitle,
          body: S.current.helpSelectBody,
          demo: GestureDemoKind.rotate,
        ),
        HelpItem(
          icon: GameActionId.flip.icon,
          title: S.current.toolbarFlip,
          body: S.current.helpFlipBody,
          demo: GestureDemoKind.flip,
        ),
        HelpItem(
          icon: Icons.move_down,
          title: S.current.helpTrayTitle,
          body: S.current.helpTrayBody,
          demo: GestureDemoKind.tray,
        ),
      ],
      footer: S.current.howToPlayDrawnGroupDescription,
    ),
    HelpSection(
      title: S.current.helpStatusTitle,
      items: [
        HelpItem(icon: Icons.short_text, title: S.current.helpStatusLineTitle, body: S.current.helpStatusLineBody),
        HelpItem(
          icon: Icons.visibility_outlined,
          title: S.current.historyDifficultyEasy,
          body: S.current.onboardingDifficultyEasyDescription,
        ),
        HelpItem(
          icon: Icons.check_circle_outline,
          title: S.current.historyDifficultyMedium,
          body: S.current.onboardingDifficultyMediumDescription,
        ),
        HelpItem(
          icon: Icons.visibility_off_outlined,
          title: S.current.historyDifficultyHard,
          body: S.current.onboardingDifficultyHardDescription,
        ),
        HelpItem(icon: Icons.schedule, title: S.current.howToPlayTimerTitle, body: S.current.howToPlayTimerDescription),
      ],
      footer: S.current.onboardingDifficultySettingsNote,
    ),
    HelpSection(
      title: S.current.helpActionsTitle,
      items: [
        action(GameActionId.undo, S.current.howToPlayUndoDescription),
        action(GameActionId.redo, S.current.howToPlayRedoDescription),
        action(GameActionId.rotate, S.current.helpRotateBody),
        action(GameActionId.flip, S.current.helpFlipActionBody),
        action(GameActionId.restart, S.current.howToPlayResetDescription),
      ],
      footer: S.current.helpActionsFooter,
    ),
    HelpSection(
      title: S.current.helpAssistsTitle,
      items: [
        action(GameActionId.hint, S.current.helpHintBody),
        action(GameActionId.showSolutions, S.current.helpSolutionsBody),
      ],
      footer: S.current.helpAssistsFooter,
    ),
    HelpSection(
      title: S.current.helpLayoutsTitle,
      items: [
        HelpItem(icon: Icons.grid_view, title: S.current.headerLayoutsTooltip, body: S.current.helpLayoutsBody),
        HelpItem(icon: Icons.edit_outlined, title: S.current.layoutsEditCurrent, body: S.current.helpLayoutEditBody),
      ],
    ),
    HelpSection(
      title: S.current.helpMoreTitle,
      items: [
        action(GameActionId.history, S.current.howToPlayHistoryDescription),
        HelpItem(icon: Icons.settings, title: S.current.settings, body: S.current.helpSettingsBody),
      ],
    ),
  ];
}
