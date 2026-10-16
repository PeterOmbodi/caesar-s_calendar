import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:caesar_puzzle/application/models/achievement_stats.dart';
import 'package:caesar_puzzle/application/puzzle_history_use_case.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/injection.dart';
import 'package:caesar_puzzle/presentation/auth/bloc/auth_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/actions/game_action.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/actions/game_action_visuals.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_display.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/utils/month_label.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:share_plus/share_plus.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  static const double _maxContentWidth = 600;

  late final Stream<AchievementStats> _stats = getIt<PuzzleHistoryUseCase>().watchAchievements();
  final _cardKey = GlobalKey();

  Future<void> _share(final BuildContext buttonContext) async {
    final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    final button = buttonContext.findRenderObject() as RenderBox?;
    // iPad shows the share sheet as a popover from this button.
    final origin = button == null ? null : button.localToGlobal(Offset.zero) & button.size;
    if (boundary == null) {
      return;
    }
    final image = await boundary.toImage(pixelRatio: MediaQuery.devicePixelRatioOf(context));
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (png == null) {
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        text: S.current.achievementsShareText(S.current.appTitle),
        files: [XFile.fromData(png.buffer.asUint8List(), mimeType: 'image/png')],
        fileNameOverrides: const ['achievements.png'],
        sharePositionOrigin: origin,
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final sidePadding = math.max(16.0, (width - _maxContentWidth) / 2);
    return Scaffold(
      backgroundColor: colors.background,
      body: StreamBuilder<AchievementStats>(
        stream: _stats,
        builder: (final context, final snapshot) {
          final stats = snapshot.data;
          return CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: Text(S.current.achievementsTitle),
                trailing: stats == null || stats.solvedDates.isEmpty
                    ? null
                    : Builder(
                        builder: (final buttonContext) => CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _share(buttonContext),
                          child: Icon(Icons.ios_share, semanticLabel: S.current.achievementsShare),
                        ),
                      ),
                backgroundColor: colors.background,
                border: null,
                transitionBetweenRoutes: false,
              ),
              if (stats == null)
                const SliverFillRemaining(child: Center(child: CupertinoActivityIndicator()))
              else
                SliverSafeArea(
                  top: false,
                  sliver: SliverPadding(
                    padding: EdgeInsets.fromLTRB(sidePadding - 16, 0, sidePadding - 16, 8),
                    sliver: SliverToBoxAdapter(
                      // Captured for sharing, hence its own background.
                      child: RepaintBoundary(
                        key: _cardKey,
                        child: ColoredBox(
                          color: colors.background,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _Header(stats: stats),
                                _CalendarCard(stats: stats),
                                const SizedBox(height: 16),
                                _Tiles(stats: stats),
                                const SizedBox(height: 16),
                                Text(
                                  S.current.appTitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.stats});

  final AchievementStats stats;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final user = context.select<AuthCubit, dynamic>((final cubit) => cubit.state.user);
    final name = AccountDisplay.bestDisplayName(user);
    final since = stats.firstSolvedAt;
    if (name == null && since == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
      child: Row(
        children: [
          if (name != null) ...[
            AccountAvatar(
              photoUrl: AccountDisplay.bestPhotoUrl(user),
              fallbackLabel: AccountDisplay.avatarInitial(name),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name != null)
                  Text(
                    name,
                    style: TextStyle(fontSize: 17, height: 22 / 17, fontWeight: FontWeight.w600, color: colors.text),
                  ),
                if (since != null)
                  Text(
                    S.current.achievementsPlayingSince(DateFormat.yMMMd().format(since)),
                    style: TextStyle(fontSize: 15, height: 20 / 15, color: colors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.stats});

  final AchievementStats stats;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final solved = stats.solvedDates.length;
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.board, borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: '$solved / ${AchievementStats.calendarDates} ${S.current.achievementsDatesSolved}',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: '$solved',
                      style: TextStyle(fontSize: 40, height: 1.1, fontWeight: FontWeight.w700, color: colors.text),
                      children: [
                        TextSpan(
                          text: ' / ${AchievementStats.calendarDates}',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: colors.textSecondary),
                        ),
                      ],
                    ),
                    style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    S.current.achievementsDatesSolved,
                    style: TextStyle(fontSize: 15, height: 20 / 15, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ExcludeSemantics(child: _YearGrid(solved: stats.solvedDates)),
            if (solved == 0) ...[
              const SizedBox(height: 12),
              Text(
                S.current.achievementsEmpty,
                style: TextStyle(fontSize: 13, height: 18 / 13, color: colors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Months as rows, days as columns.
class _YearGrid extends StatelessWidget {
  const _YearGrid({required this.solved});

  static const double _labelWidth = 30;

  final Set<(int, int)> solved;

  @override
  Widget build(final BuildContext context) => LayoutBuilder(
    builder: (final context, final constraints) {
      final cell = (constraints.maxWidth - _labelWidth) / 31;
      return CustomPaint(
        size: Size(constraints.maxWidth, cell * 12),
        painter: _YearGridPainter(solved: solved, cell: cell, colors: GameColors.of(context)),
      );
    },
  );
}

class _YearGridPainter extends CustomPainter {
  _YearGridPainter({required this.solved, required this.cell, required this.colors});

  final Set<(int, int)> solved;
  final double cell;
  final GameColors colors;

  @override
  void paint(final Canvas canvas, final Size size) {
    final done = Paint()..color = colors.active;
    final open = Paint()..color = colors.gridLine;
    final gap = math.max(1.5, cell * 0.18);
    for (var month = 1; month <= 12; month++) {
      final top = (month - 1) * cell;
      final label = TextPainter(
        text: TextSpan(
          text: shortMonthName(month),
          style: TextStyle(fontSize: math.min(11, cell * 0.95), color: colors.textSecondary),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: _YearGrid._labelWidth - 4);
      label.paint(canvas, Offset(0, top + (cell - label.height) / 2));
      // A leap year, so Feb 29 has a cell.
      for (var day = 1; day <= DateUtils.getDaysInMonth(2024, month); day++) {
        final rect = Rect.fromLTWH(_YearGrid._labelWidth + (day - 1) * cell, top, cell - gap, cell - gap);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.2)),
          solved.contains((month, day)) ? done : open,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant final _YearGridPainter oldDelegate) =>
      oldDelegate.solved != solved || oldDelegate.cell != cell || oldDelegate.colors != colors;
}

class _Tiles extends StatelessWidget {
  const _Tiles({required this.stats});

  final AchievementStats stats;

  @override
  Widget build(final BuildContext context) {
    final fastest = stats.fastestSolveMs;
    final tiles = [
      _Tile(icon: Icons.visibility_off_outlined, value: '${stats.solvedHard}', label: S.current.achievementsHard),
      _Tile(
        icon: Icons.local_fire_department_outlined,
        value: '${stats.bestStreakDays}',
        label: S.current.achievementsBestStreak,
      ),
      _Tile(
        icon: GameActionId.showSolutions.icon,
        value: '${stats.solutionsFound}',
        label: S.current.achievementsSolutions,
      ),
      _Tile(
        icon: Icons.timer_outlined,
        value: fastest == null ? '—' : _duration(fastest),
        label: S.current.achievementsFastest,
      ),
      _Tile(icon: Icons.verified_outlined, value: '${stats.cleanSolves}', label: S.current.achievementsClean),
      _Tile(icon: Icons.grid_view, value: '${stats.customLayoutSolves}', label: S.current.achievementsCustom),
    ];
    return LayoutBuilder(
      builder: (final context, final constraints) {
        final columns = constraints.maxWidth > 500 ? 3 : 2;
        return Column(
          spacing: 12,
          children: [
            for (var start = 0; start < tiles.length; start += columns)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [for (final tile in tiles.skip(start).take(columns)) Expanded(child: tile)],
                ),
              ),
          ],
        );
      },
    );
  }

  static String _duration(final int ms) {
    final seconds = ms ~/ 1000;
    final mmss = '${(seconds ~/ 60) % 60}:${'${seconds % 60}'.padLeft(2, '0')}';
    return seconds >= 3600 ? '${seconds ~/ 3600}:${mmss.padLeft(5, '0')}' : mmss;
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: colors.board, borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: colors.accent),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: colors.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 13, height: 17 / 13, color: colors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
