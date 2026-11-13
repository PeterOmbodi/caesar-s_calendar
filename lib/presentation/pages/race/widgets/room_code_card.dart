import 'package:caesar_puzzle/application/race/race_room_code.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.board,
        border: Border.all(color: colors.boardBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
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
              style: TextStyle(fontSize: 13, height: 18 / 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 12),
            Semantics(
              label: code.split('').join(' '),
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: SelectableText(
                  code,
                  style: TextStyle(
                    fontSize: 36,
                    height: 42 / 36,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 10,
                    color: colors.text,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (final buttonContext) => OutlinedButton.icon(
                onPressed: () => _share(buttonContext),
                icon: Icon(Icons.adaptive.share, size: 18),
                label: Text(S.current.raceShare),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  backgroundColor: colors.glass,
                  foregroundColor: colors.accent,
                  side: BorderSide(color: colors.glassLine),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
