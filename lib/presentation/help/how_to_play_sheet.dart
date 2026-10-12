import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/help/gesture_demo.dart';
import 'package:caesar_puzzle/presentation/help/how_to_play_content.dart';
import 'package:caesar_puzzle/presentation/services/keyboard_presence.dart';
import 'package:caesar_puzzle/presentation/widgets/game_sheet.dart';
import 'package:caesar_puzzle/presentation/widgets/inset_section.dart';
import 'package:caesar_puzzle/presentation/widgets/key_cap.dart';
import 'package:flutter/material.dart';

Future<void> showHowToPlaySheet(final BuildContext context) =>
    showGameSheet(context, title: S.current.howToPlayTitle, builder: (_) => const _HowToPlayBody());

class _HowToPlayBody extends StatelessWidget {
  const _HowToPlayBody();

  @override
  Widget build(final BuildContext context) {
    final platform = Theme.of(context).platform;
    final apple = platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    return ValueListenableBuilder(
      valueListenable: KeyboardPresence.instance.connected,
      builder: (final context, final hasKeyboard, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, section) in howToPlaySections(apple: apple, hasKeyboard: hasKeyboard).indexed) ...[
            if (index > 0) const SizedBox(height: 28),
            InsetSection(
              header: section.title,
              footer: section.footer,
              children: [
                for (final item in section.items)
                  InsetRow(
                    icon: item.icon,
                    title: item.title,
                    subtitle: item.body,
                    trailing: item.shortcut == null ? null : KeyCap(item.shortcut!),
                    illustration: item.demo == null ? null : GestureDemo(item.demo!),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
