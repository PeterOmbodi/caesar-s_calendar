import 'dart:async';
import 'dart:math' as math;

import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/help/how_to_play_sheet.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/solution_indicator_difficulty_x.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_session_difficulty_x.dart';
import 'package:caesar_puzzle/presentation/widgets/glass_surface.dart';
import 'package:caesar_puzzle/presentation/widgets/inset_section.dart';
import 'package:caesar_puzzle/presentation/widgets/spotlight_painter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// [dateCells] is re-read on [boardChanges] and on resize.
Future<SolutionIndicator> showStartCard(
  final BuildContext context, {
  required final List<Rect> Function() dateCells,
  required final Stream<Object?> boardChanges,
  required final SolutionIndicator initial,
}) async =>
    await showGeneralDialog<SolutionIndicator>(
      context: context,
      barrierColor: Colors.transparent,
      transitionDuration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) => _StartCard(dateCells: dateCells, boardChanges: boardChanges, initial: initial),
      transitionBuilder: (_, final animation, _, final child) => FadeTransition(opacity: animation, child: child),
    ) ??
    initial;

class _StartCard extends StatefulWidget {
  const _StartCard({required this.dateCells, required this.boardChanges, required this.initial});

  final List<Rect> Function() dateCells;
  final Stream<Object?> boardChanges;
  final SolutionIndicator initial;

  @override
  State<_StartCard> createState() => _StartCardState();
}

class _StartCardState extends State<_StartCard> with WidgetsBindingObserver {
  late var _level = widget.initial;
  late var _cells = widget.dateCells();
  late final StreamSubscription<Object?> _boardSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _boardSubscription = widget.boardChanges.listen((_) => _refreshCells());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _boardSubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeMetrics() => _refreshCells();

  // The board relayouts a frame later.
  void _refreshCells() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) {
      return;
    }
    final cells = widget.dateCells();
    if (!listEquals(cells, _cells)) {
      setState(() => _cells = cells);
    }
  });

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final spec = ScreenSpec.of(context);
    final isCompact = spec.window == WindowClass.compact && !spec.isLandscape;
    final holes = [for (final cell in _cells) cell.inflate(2)];
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: SpotlightPainter(holes: holes))),
        Positioned.fill(
          child: CustomSingleChildLayout(
            delegate: _CardLayout(holes: holes, padding: MediaQuery.paddingOf(context)),
            child: GlassSurface(
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              color: colors.menu,
              allowLiquid: false,
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Semantics(
                                header: true,
                                child: Text(
                                  S.current.onboardingGoalTitle,
                                  style: TextStyle(
                                    fontSize: 22,
                                    height: 28 / 22,
                                    fontWeight: FontWeight.w700,
                                    color: colors.text,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                S.current.onboardingGoalDescription,
                                style: TextStyle(fontSize: 15, height: 20 / 15, color: colors.textSecondary),
                              ),
                            ),
                            SizedBox(height: isCompact ? 16 : 20),
                            if (isCompact) _compactLevels(colors) else _levels(colors),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 16, 16),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () => showHowToPlaySheet(context),
                            style: TextButton.styleFrom(foregroundColor: colors.accent),
                            child: Text(S.current.howToPlayTitle),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(_level),
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.active,
                              foregroundColor: colors.onActive,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            child: Text(S.current.startPlay),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _levels(final GameColors colors) => InsetSection(
    header: S.current.onboardingDifficultyTitle,
    footer: S.current.onboardingDifficultySettingsNote,
    children: [
      for (final level in SolutionIndicator.values)
        Semantics(
          selected: level == _level,
          child: InsetRow(
            icon: level.icon,
            title: level.sessionDifficulty.label,
            subtitle: level.description,
            trailing: Icon(Icons.check, size: 20, color: level == _level ? colors.accent : Colors.transparent),
            onTap: () => setState(() => _level = level),
          ),
        ),
    ],
  );

  Widget _compactLevels(final GameColors colors) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            S.current.onboardingDifficultyTitle,
            style: TextStyle(fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w600, color: colors.text),
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(color: colors.board, borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                for (final level in SolutionIndicator.values)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: level == _level,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _level = level),
                        child: AnimatedContainer(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: level == _level ? colors.active : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            level.sessionDifficulty.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: level == _level ? colors.onActive : colors.text,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // The longest description sets the height.
        Stack(
          children: [
            for (final level in SolutionIndicator.values)
              Visibility.maintain(
                visible: level == _level,
                child: Text(
                  level.description,
                  style: TextStyle(fontSize: 14, height: 19 / 14, color: colors.textSecondary),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class _CardLayout extends SingleChildLayoutDelegate {
  const _CardLayout({required this.holes, required this.padding});

  static const double _margin = 16;
  static const double _gap = 12;
  static const double _maxWidth = 400;

  final List<Rect> holes;
  final EdgeInsets padding;

  @override
  BoxConstraints getConstraintsForChild(final BoxConstraints constraints) => BoxConstraints(
    maxWidth: math.min(_maxWidth, constraints.maxWidth - padding.horizontal - 2 * _margin),
    maxHeight: constraints.maxHeight - padding.vertical - 2 * _margin,
  );

  @override
  Offset getPositionForChild(final Size size, final Size childSize) {
    final safe = padding.deflateRect(Offset.zero & size).deflate(_margin);
    double x(final double left) => left.clamp(safe.left, math.max(safe.left, safe.right - childSize.width));
    double y(final double top) => top.clamp(safe.top, math.max(safe.top, safe.bottom - childSize.height));
    if (holes.isEmpty) {
      return Offset(x(safe.center.dx - childSize.width / 2), y(safe.center.dy - childSize.height / 2));
    }
    final cells = holes.reduce((final a, final b) => a.expandToInclude(b));
    final cx = x(cells.center.dx - childSize.width / 2);
    final cy = y(cells.center.dy - childSize.height / 2);
    final candidates = [
      Offset(cx, y(cells.bottom + _gap)),
      Offset(cx, y(cells.top - _gap - childSize.height)),
      Offset(x(cells.right + _gap), cy),
      Offset(x(cells.left - _gap - childSize.width), cy),
      Offset(cx, safe.top),
      Offset(cx, y(safe.bottom)),
    ];
    double covered(final Offset at) => holes.fold(0, (final sum, final hole) {
      final overlap = (at & childSize).intersect(hole);
      return overlap.width > 0 && overlap.height > 0 ? sum + overlap.width * overlap.height : sum;
    });
    // First spot clear of the date cells, else the least covering one.
    return candidates.reduce((final best, final next) => covered(next) < covered(best) ? next : best);
  }

  @override
  bool shouldRelayout(covariant final _CardLayout oldDelegate) =>
      oldDelegate.padding != padding || !listEquals(oldDelegate.holes, holes);
}
