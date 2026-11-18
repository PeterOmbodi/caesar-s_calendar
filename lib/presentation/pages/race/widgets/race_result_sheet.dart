import 'package:caesar_puzzle/application/race/race_board.dart';
import 'package:caesar_puzzle/application/race/race_player.dart';
import 'package:caesar_puzzle/application/race/race_result.dart';
import 'package:caesar_puzzle/application/race/race_rules.dart';
import 'package:caesar_puzzle/application/race/solver_level.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/race/race_time_format.dart';
import 'package:caesar_puzzle/presentation/pages/race/widgets/race_board_preview.dart';
import 'package:caesar_puzzle/presentation/pages/race/widgets/race_grace_countdown.dart';
import 'package:caesar_puzzle/presentation/pages/race/widgets/race_player_avatar.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/widgets/laurel_wreath.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

/// Folds down to its title so that the final board can be seen.
class RaceResultSheet extends StatefulWidget {
  const RaceResultSheet({
    super.key,
    required this.standings,
    required this.myUid,
    required this.myBoard,
    required this.startAtMs,
    required this.totalPieces,
    required this.shownUid,
    required this.onShowBoard,
    required this.solverLevel,
    required this.graceEndsAtMs,
    required this.now,
    this.note,
  });

  static const double maxWidth = 480;
  static const double _boardMaxHeight = 280;

  final List<RaceStanding> standings;
  final String myUid;

  /// From the game; the published one wins when there is one, since the game's board is empty after a restart.
  final RaceBoard myBoard;

  /// Start of this round, to leave out a board the last round wrote late.
  final int? startAtMs;
  final int totalPieces;

  /// Null shows the table.
  final String? shownUid;
  final ValueChanged<String?> onShowBoard;

  /// Null in a race between people.
  final SolverLevel? solverLevel;

  final int? graceEndsAtMs;
  final DateTime Function() now;

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

  RaceBoard? _publishedBoard(final RacePlayer player) => RaceRules.boardOf(player, startAtMs: widget.startAtMs);

  // An online player publishes the board in a moment.
  bool _hasBoard(final RaceStanding standing) =>
      standing.outcome != RaceOutcome.racing &&
      (standing.player.uid == widget.myUid || _publishedBoard(standing.player) != null || standing.player.online);

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
                                  _LaurelTitle(title: _title, style: titleStyle, color: colors.laurel)
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
                // The pages share what is left of the screen's height: the board shrinks, the table scrolls.
                Flexible(
                  child: AnimatedSize(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 200),
                    alignment: Alignment.topCenter,
                    child: _isExpanded
                        ? _SlidingPages(
                            isOpening: _isOpening,
                            child: shown == null
                                ? _ResultTable(
                                    key: const ValueKey<String?>(null),
                                    standings: widget.standings,
                                    myUid: widget.myUid,
                                    totalPieces: widget.totalPieces,
                                    graceEndsAtMs: widget.graceEndsAtMs,
                                    now: widget.now,
                                    solverLevel: widget.solverLevel,
                                    onShowBoard: (final standing) =>
                                        _hasBoard(standing) ? () => widget.onShowBoard(standing.player.uid) : null,
                                  )
                                : _BoardPage(
                                    key: ValueKey<String?>(shown.player.uid),
                                    standing: shown,
                                    board: shown.player.uid == widget.myUid
                                        ? _publishedBoard(shown.player) ?? widget.myBoard
                                        : _publishedBoard(shown.player),
                                    totalPieces: widget.totalPieces,
                                    solverLevel: widget.solverLevel,
                                    onBack: () => widget.onShowBoard(null),
                                  ),
                          )
                        : const SizedBox(width: double.infinity),
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

String _outcomeText(final RaceOutcome outcome) => switch (outcome) {
  RaceOutcome.gaveUp => S.current.raceGaveUp,
  RaceOutcome.out => S.current.raceOut,
  RaceOutcome.finished || RaceOutcome.notFinished => S.current.raceResultNotFinished,
  RaceOutcome.racing => '',
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
  const _ResultTable({
    super.key,
    required this.standings,
    required this.myUid,
    required this.totalPieces,
    required this.graceEndsAtMs,
    required this.now,
    required this.solverLevel,
    required this.onShowBoard,
  });

  final List<RaceStanding> standings;
  final String myUid;
  final int totalPieces;
  final int? graceEndsAtMs;
  final DateTime Function() now;
  final SolverLevel? solverLevel;

  /// Null for a player without a board.
  final VoidCallback? Function(RaceStanding standing) onShowBoard;

  @override
  Widget build(final BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      children: [
        for (final standing in standings)
          _ResultRow(
            standing: standing,
            isMe: standing.player.uid == myUid,
            totalPieces: totalPieces,
            graceEndsAtMs: standing.outcome == RaceOutcome.racing ? graceEndsAtMs : null,
            now: now,
            solverLevel: solverLevel,
            onTap: onShowBoard(standing),
            hasWreath: standing.isWinner && standings.where((final s) => s.isWinner).length == 1,
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
    required this.solverLevel,
    required this.onBack,
  });

  static const double _backSwipeVelocity = 300;

  final RaceStanding standing;

  /// Null until the player's board arrives.
  final RaceBoard? board;
  final int totalPieces;
  final SolverLevel? solverLevel;
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
                RacePlayerAvatar(player: player, radius: 15, solverLevel: solverLevel),
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
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: RaceResultSheet._boardMaxHeight),
                child: board == null
                    ? const SizedBox(
                        height: RaceResultSheet._boardMaxHeight,
                        child: Center(child: CircularProgressIndicator.adaptive()),
                      )
                    : RaceBoardPreview(board: board),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.standing,
    required this.isMe,
    required this.totalPieces,
    required this.graceEndsAtMs,
    required this.now,
    required this.solverLevel,
    required this.onTap,
    required this.hasWreath,
  });

  static const double _avatarRadius = 15;
  static const double _avatarSlot = _avatarRadius * 2 / LaurelWreath.childShare;

  final RaceStanding standing;
  final bool isMe;
  final bool hasWreath;
  final int totalPieces;
  final int? graceEndsAtMs;
  final DateTime Function() now;
  final SolverLevel? solverLevel;

  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final player = standing.player;
    final time = player.durationMs;
    final gap = standing.gapMs;
    const figures = [FontFeature.tabularFigures()];
    final graceEndsAt = graceEndsAtMs;
    final result = switch (standing) {
      _ when time != null => formatRaceTime(time, tenths: true),
      RaceStanding(outcome: RaceOutcome.racing) => S.current.raceProgress(player.placed, totalPieces),
      _ => standing.isWinner ? '' : _outcomeText(standing.outcome),
    };
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
                // Every row keeps the wreath's width, so that the nicknames line up.
                SizedBox(
                  width: _avatarSlot,
                  child: Center(
                    child: hasWreath
                        ? LaurelWreath(
                            size: _avatarSlot,
                            color: colors.laurel,
                            child: RacePlayerAvatar(player: player, radius: _avatarRadius, solverLevel: solverLevel),
                          )
                        : RacePlayerAvatar(player: player, radius: _avatarRadius, solverLevel: solverLevel),
                  ),
                ),
                const SizedBox(width: 4),
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
                    if (graceEndsAt != null) RaceGraceCountdown(endsAtMs: graceEndsAt, now: now),
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
        LaurelBranch(color: color, mirrored: false, grow: value),
        const SizedBox(width: 6),
        Flexible(child: child!),
        const SizedBox(width: 6),
        LaurelBranch(color: color, mirrored: true, grow: value),
      ],
    ),
    child: Text(title, style: style),
  );
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
