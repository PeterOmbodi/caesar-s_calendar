import 'package:caesar_puzzle/application/race/race_result.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/race/race_time_format.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_display.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

/// Folds down to its title so that the final board can be seen.
class RaceResultSheet extends StatefulWidget {
  const RaceResultSheet({super.key, required this.standings, required this.myUid, this.note});

  static const double maxWidth = 480;

  final List<RaceStanding> standings;
  final String myUid;

  final String? note;

  @override
  State<RaceResultSheet> createState() => _RaceResultSheetState();
}

class _RaceResultSheetState extends State<RaceResultSheet> {
  var _isExpanded = true;

  String get _title {
    final me = widget.standings.firstWhereOrNull((final s) => s.player.uid == widget.myUid);
    if (me == null) {
      return S.current.raceResultNotFinished;
    }
    if (me.isWinner) {
      return widget.standings.where((final s) => s.isWinner).length > 1
          ? S.current.raceResultDraw
          : S.current.raceResultWin;
    }
    if (me.place case final place?) {
      return S.current.raceResultPlace(place);
    }
    return _outcomeText(me.outcome);
  }

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: RaceResultSheet.maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.board,
          border: Border.all(color: colors.boardBorder),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12, child: CustomPaint(painter: _CheckeredPainter())),
              Semantics(
                button: true,
                label: _isExpanded ? S.current.raceResultsHide : S.current.raceResultsShow,
                child: InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _title,
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colors.text),
                              ),
                              if (widget.note case final note?)
                                Text(note, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
                            ],
                          ),
                        ),
                        Icon(_isExpanded ? Icons.expand_more : Icons.expand_less, color: colors.icon),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200),
                alignment: Alignment.topCenter,
                child: _isExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          children: [
                            for (final standing in widget.standings)
                              _ResultRow(standing: standing, isMe: standing.player.uid == widget.myUid),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _outcomeText(final RaceOutcome outcome) => switch (outcome) {
  RaceOutcome.gaveUp => S.current.raceGaveUp,
  RaceOutcome.out => S.current.raceOut,
  RaceOutcome.finished || RaceOutcome.notFinished => S.current.raceResultNotFinished,
};

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.standing, required this.isMe});

  final RaceStanding standing;
  final bool isMe;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final player = standing.player;
    final time = player.durationMs;
    final gap = standing.gapMs;
    const figures = [FontFeature.tabularFigures()];
    final result = time == null
        ? (standing.isWinner ? '' : _outcomeText(standing.outcome))
        : formatRaceTime(time, tenths: true);
    final gapText = gap == null || gap == 0 ? null : formatRaceGap(gap);
    return Semantics(
      label: [?standing.place?.toString(), player.nickname, if (result.isNotEmpty) result, ?gapText].join(', '),
      excludeSemantics: true,
      child: ColoredBox(
        color: isMe ? colors.accent.withValues(alpha: 0.12) : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  standing.place?.toString() ?? '–',
                  style: TextStyle(fontSize: 16, color: colors.textSecondary, fontFeatures: figures),
                ),
              ),
              const SizedBox(width: 8),
              AccountAvatar(
                photoUrl: null,
                fallbackLabel: AccountDisplay.avatarInitials(player.nickname),
                radius: 15,
                backgroundColor: colors.player(player.colorIndex),
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  player.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isMe ? FontWeight.w600 : FontWeight.w400,
                    color: colors.text,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (result.isNotEmpty)
                    Text(
                      result,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: time == null ? FontWeight.w400 : FontWeight.w600,
                        color: time == null ? colors.textSecondary : colors.text,
                        fontFeatures: figures,
                      ),
                    ),
                  if (gapText != null)
                    Text(
                      gapText,
                      style: TextStyle(fontSize: 13, color: colors.textSecondary, fontFeatures: figures),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckeredPainter extends CustomPainter {
  const _CheckeredPainter();

  static const double _square = 6;

  @override
  void paint(final Canvas canvas, final Size size) {
    final dark = Paint()..color = const Color(0xFF1C1B1F);
    final light = Paint()..color = const Color(0xFFF5F2EA);
    canvas.drawRect(Offset.zero & size, light);
    for (var row = 0; row * _square < size.height; row++) {
      for (var column = row % 2; column * _square < size.width; column += 2) {
        canvas.drawRect(Rect.fromLTWH(column * _square, row * _square, _square, _square), dark);
      }
    }
  }

  @override
  bool shouldRepaint(final _CheckeredPainter oldDelegate) => false;
}
