import 'package:caesar_puzzle/application/race/race_board.dart';
import 'package:caesar_puzzle/application/race/race_player.dart';
import 'package:caesar_puzzle/application/race/race_result.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/race/race_time_format.dart';
import 'package:caesar_puzzle/presentation/pages/race/widgets/race_board_preview.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_display.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

/// Folds down to its title so that the final board can be seen.
class RaceResultSheet extends StatefulWidget {
  const RaceResultSheet({
    super.key,
    required this.standings,
    required this.myUid,
    required this.myBoard,
    required this.totalPieces,
    required this.shownUid,
    required this.onShowBoard,
    this.note,
  });

  static const double maxWidth = 480;
  static const double _boardMaxHeight = 280;

  final List<RaceStanding> standings;
  final String myUid;

  /// From the game, not from the room.
  final RaceBoard myBoard;
  final int totalPieces;

  /// Null shows the table.
  final String? shownUid;
  final ValueChanged<String?> onShowBoard;

  final String? note;

  @override
  State<RaceResultSheet> createState() => _RaceResultSheetState();
}

class _RaceResultSheetState extends State<RaceResultSheet> {
  var _isExpanded = true;

  var _isOpening = true;

  @override
  void didUpdateWidget(final RaceResultSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shownUid != oldWidget.shownUid) {
      _isOpening = widget.shownUid != null;
    }
  }

  // An online player publishes the board in a moment.
  bool _hasBoard(final RacePlayer player) => player.uid == widget.myUid || player.board != null || player.online;

  RaceStanding? get _me => widget.standings.firstWhereOrNull((final s) => s.player.uid == widget.myUid);

  bool get _isSoleWinner => (_me?.isWinner ?? false) && widget.standings.where((final s) => s.isWinner).length == 1;

  String get _title {
    final me = _me;
    if (me == null) {
      return S.current.raceResultNotFinished;
    }
    if (me.isWinner) {
      return _isSoleWinner ? S.current.raceResultWin : S.current.raceResultDraw;
    }
    if (me.place case final place?) {
      return S.current.raceResultPlace(place);
    }
    return _outcomeText(me.outcome);
  }

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final shown = widget.standings.firstWhereOrNull((final s) => s.player.uid == widget.shownUid);
    final titleStyle = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colors.text);
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
          // Ink is drawn on the nearest Material; it must lie above the sheet's colour.
          child: Material(
            type: MaterialType.transparency,
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
                                if (_isSoleWinner)
                                  _LaurelTitle(title: _title, style: titleStyle, color: colors.accent)
                                else
                                  Text(_title, style: titleStyle),
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
                      ? _SlidingPages(
                          isOpening: _isOpening,
                          child: shown == null
                              ? _ResultTable(
                                  key: const ValueKey<String?>(null),
                                  standings: widget.standings,
                                  myUid: widget.myUid,
                                  onShowBoard: (final player) =>
                                      _hasBoard(player) ? () => widget.onShowBoard(player.uid) : null,
                                )
                              : _BoardPage(
                                  key: ValueKey<String?>(shown.player.uid),
                                  standing: shown,
                                  board: shown.player.uid == widget.myUid ? widget.myBoard : shown.player.board,
                                  totalPieces: widget.totalPieces,
                                  onBack: () => widget.onShowBoard(null),
                                ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
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

/// Slides the new page in from the right when opening a board, from the left when going back.
class _SlidingPages extends StatelessWidget {
  const _SlidingPages({required this.isOpening, required this.child});

  final bool isOpening;
  final Widget child;

  @override
  Widget build(final BuildContext context) => AnimatedSwitcher(
    duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    // Only the incoming page sizes the sheet, so its height follows the new page alone.
    layoutBuilder: (final current, final previous) => Stack(
      children: [
        for (final page in previous) Positioned(left: 0, top: 0, right: 0, child: page),
        ?current,
      ],
    ),
    transitionBuilder: (final page, final animation) {
      final isIncoming = page.key == child.key;
      final dx = (isIncoming ? 1.0 : -1.0) * (isOpening ? 1 : -1);
      return ClipRect(
        child: SlideTransition(
          position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(animation),
          child: page,
        ),
      );
    },
    child: child,
  );
}

class _ResultTable extends StatelessWidget {
  const _ResultTable({super.key, required this.standings, required this.myUid, required this.onShowBoard});

  final List<RaceStanding> standings;
  final String myUid;

  /// Null for a player without a board.
  final VoidCallback? Function(RacePlayer player) onShowBoard;

  @override
  Widget build(final BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      children: [
        for (final standing in standings)
          _ResultRow(
            standing: standing,
            isMe: standing.player.uid == myUid,
            onTap: onShowBoard(standing.player),
          ),
      ],
    ),
  );
}

class _BoardPage extends StatelessWidget {
  const _BoardPage({
    super.key,
    required this.standing,
    required this.board,
    required this.totalPieces,
    required this.onBack,
  });

  static const double _backSwipeVelocity = 300;

  final RaceStanding standing;

  /// Null until the player's board arrives.
  final RaceBoard? board;
  final int totalPieces;
  final VoidCallback onBack;

  String get _result {
    final time = standing.player.durationMs;
    final board = this.board;
    return [
      if (time != null) formatRaceTime(time, tenths: true) else if (!standing.isWinner) _outcomeText(standing.outcome),
      if (time == null && board != null) S.current.raceProgress(board.pieces.length, totalPieces),
    ].join(' · ');
  }

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final player = standing.player;
    final board = this.board;
    return GestureDetector(
      onHorizontalDragEnd: (final details) {
        if ((details.primaryVelocity ?? 0) > _backSwipeVelocity) {
          onBack();
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: onBack,
                  icon: Icon(Icons.chevron_left, color: colors.icon),
                ),
                _PlayerAvatar(player: player),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.nickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.text),
                      ),
                      if (_result.isNotEmpty)
                        Text(
                          _result,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: RaceResultSheet._boardMaxHeight),
              child: board == null
                  ? const SizedBox(
                      height: RaceResultSheet._boardMaxHeight,
                      child: Center(child: CircularProgressIndicator.adaptive()),
                    )
                  : RaceBoardPreview(board: board),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({required this.player});

  final RacePlayer player;

  @override
  Widget build(final BuildContext context) => AccountAvatar(
    photoUrl: null,
    fallbackLabel: AccountDisplay.avatarInitials(player.nickname),
    radius: 15,
    backgroundColor: GameColors.of(context).player(player.colorIndex),
    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
  );
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.standing, required this.isMe, required this.onTap});

  final RaceStanding standing;
  final bool isMe;

  final VoidCallback? onTap;

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
      button: onTap != null,
      hint: onTap == null ? null : S.current.raceShowBoard,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          color: isMe ? colors.accent.withValues(alpha: 0.12) : Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
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
                _PlayerAvatar(player: player),
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
                // The same width with or without the arrow keeps the times aligned.
                SizedBox(
                  width: 28,
                  child: onTap == null
                      ? null
                      : Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Icon(Icons.chevron_right, color: colors.textSecondary),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LaurelTitle extends StatelessWidget {
  const _LaurelTitle({required this.title, required this.style, required this.color});

  final String title;
  final TextStyle style;
  final Color color;

  @override
  Widget build(final BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 450),
    curve: Curves.easeOutBack,
    builder: (final context, final value, final child) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LaurelBranch(color: color, mirrored: false, grow: value),
        const SizedBox(width: 6),
        Flexible(child: child!),
        const SizedBox(width: 6),
        _LaurelBranch(color: color, mirrored: true, grow: value),
      ],
    ),
    child: Text(title, style: style),
  );
}

class _LaurelBranch extends StatelessWidget {
  const _LaurelBranch({required this.color, required this.mirrored, required this.grow});

  final Color color;
  final bool mirrored;
  final double grow;

  @override
  Widget build(final BuildContext context) => SizedBox(
    width: 18,
    height: 28,
    child: CustomPaint(
      painter: _LaurelBranchPainter(color: color, mirrored: mirrored, grow: grow),
    ),
  );
}

/// Drawn as the left branch; [mirrored] gives the right one.
class _LaurelBranchPainter extends CustomPainter {
  const _LaurelBranchPainter({required this.color, required this.mirrored, required this.grow});

  static const int _leaves = 5;

  final Color color;
  final bool mirrored;
  final double grow;

  @override
  void paint(final Canvas canvas, final Size size) {
    if (grow <= 0) {
      return;
    }
    if (mirrored) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    final start = Offset(size.width * 0.9, size.height * 0.95);
    final control = Offset(size.width * 0.05, size.height * 0.65);
    final end = Offset(size.width * 0.6, size.height * 0.1);
    Offset point(final double t) => start * ((1 - t) * (1 - t)) + control * (2 * (1 - t) * t) + end * (t * t);
    Offset tangent(final double t) => (control - start) * (2 * (1 - t)) + (end - control) * (2 * t);

    final stem = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final tip = grow.clamp(0.0, 1.0);
    final path = Path()..moveTo(start.dx, start.dy);
    for (var i = 1; i <= 12; i++) {
      final p = point(tip * i / 12);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, stem);

    final leaf = Paint()..color = color;
    final length = size.height * 0.22;
    void drawLeaf(final Offset at, final double angle, final double scale) {
      canvas
        ..save()
        ..translate(at.dx, at.dy)
        ..rotate(angle)
        ..scale(scale);
      canvas.drawOval(Rect.fromLTWH(0, -length * 0.2, length, length * 0.4), leaf);
      canvas.restore();
    }

    for (var i = 1; i <= _leaves; i++) {
      final t = i / (_leaves + 1);
      if (t > tip) {
        break;
      }
      final at = point(t);
      final direction = tangent(t).direction;
      final scale = (1 - t * 0.35) * grow;
      drawLeaf(at, direction - 0.7, scale);
      drawLeaf(at, direction + 0.7, scale);
    }
    if (tip >= 1) {
      drawLeaf(end, tangent(1).direction, 0.8 * grow);
    }
  }

  @override
  bool shouldRepaint(final _LaurelBranchPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.mirrored != mirrored || oldDelegate.grow != grow;
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
