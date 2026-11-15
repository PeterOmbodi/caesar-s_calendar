import 'package:caesar_puzzle/application/race/race_room_code.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/widgets/inset_section.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// The room's QR code, its code in large type and a share button.
class RoomCodeCard extends StatelessWidget {
  const RoomCodeCard({super.key, required this.code});

  final String code;

  Future<void> _share(final BuildContext buttonContext) async {
    final button = buttonContext.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: S.current.raceShareText(S.current.appTitle, code, '${RaceRoomCode.link(code)}'),
        // iPad shows the share sheet as a popover from this button.
        sharePositionOrigin: button == null ? null : button.localToGlobal(Offset.zero) & button.size,
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final theme = Theme.of(context);
    final isMaterial = ScreenSpec.of(context).family != ChromeFamily.glass;
    final hintStyle = isMaterial
        ? theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)
        : TextStyle(fontSize: 13, height: 18 / 13, color: colors.textSecondary);
    final codeStyle = isMaterial
        ? theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 10)
        : TextStyle(fontSize: 36, height: 42 / 36, fontWeight: FontWeight.w700, letterSpacing: 10, color: colors.text);
    return InsetSection(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Semantics(
                label: S.current.raceRoomCodeHint,
                image: true,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: QrImageView(
                    data: '${RaceRoomCode.link(code)}',
                    size: 126,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                S.current.raceRoomCodeHint,
                textAlign: TextAlign.center,
                style: hintStyle,
              ),
              const SizedBox(height: 12),
              Semantics(
                label: code.split('').join(' '),
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: SelectableText(code, style: codeStyle),
                ),
              ),
              const SizedBox(height: 12),
              Builder(builder: (final buttonContext) => _ShareButton(onPressed: () => _share(buttonContext))),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) {
    final label = Text(S.current.raceShare);
    if (ScreenSpec.of(context).family != ChromeFamily.glass) {
      return FilledButton.tonalIcon(onPressed: onPressed, icon: const Icon(Icons.share), label: label);
    }
    return CupertinoButton.tinted(
      onPressed: onPressed,
      color: GameColors.of(context).active,
      sizeStyle: CupertinoButtonSize.medium,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [const Icon(CupertinoIcons.share, size: 18), label],
      ),
    );
  }
}
