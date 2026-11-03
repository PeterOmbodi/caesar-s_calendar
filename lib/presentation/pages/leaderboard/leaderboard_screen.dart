import 'dart:async';
import 'dart:math' as math;

import 'package:caesar_puzzle/application/leaderboard/day_difficulty.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_period.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/injection.dart';
import 'package:caesar_puzzle/presentation/auth/bloc/auth_cubit.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/pages/history/models/session_summary.dart';
import 'package:caesar_puzzle/presentation/pages/leaderboard/bloc/leaderboard_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/leaderboard/widgets/leaderboard_row_view.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/public_profile_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/solution_indicator_difficulty_x.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_section_sheet.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_session_difficulty_x.dart';
import 'package:caesar_puzzle/presentation/widgets/app_segmented_control.dart';
import 'package:caesar_puzzle/presentation/widgets/inset_section.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  static const double _maxContentWidth = 600;

  @override
  Widget build(final BuildContext context) {
    final level = context.read<SettingsCubit>().state.solutionIndicator.sessionDifficulty;
    final colors = GameColors.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final padding = EdgeInsets.symmetric(horizontal: math.max(16, (width - _maxContentWidth) / 2));
    if (level == PuzzleSessionDifficulty.easy) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: const _LeaderboardAppBar(),
        body: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: padding.copyWith(top: 16),
              sliver: SliverToBoxAdapter(
                child: _Note(
                  S.current.leaderboardEasyNote(
                    PuzzleSessionDifficulty.medium.label,
                    PuzzleSessionDifficulty.hard.label,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: colors.background,
      appBar: const _LeaderboardAppBar(),
      body: BlocBuilder<AuthCubit, AuthState>(
        buildWhen: (final p, final n) => p.user?.uid != n.user?.uid,
        builder: (final context, final auth) => BlocBuilder<PublicProfileCubit, PublicProfileState>(
          buildWhen: (final p, final n) => p.enabled != n.enabled || p.isLoading != n.isLoading,
          builder: (final context, final profile) {
            if (auth.user == null) {
              return _Gate(
                padding: padding,
                text: S.current.leaderboardSignedOutHint(S.current.accountLeaderboardVisibility),
                action: S.current.leaderboardSignIn,
                onPressed: () => unawaited(showAccountSectionSheet(context)),
              );
            }
            if (profile.isLoading) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }
            if (!profile.enabled) {
              return _Gate(
                padding: padding,
                text: S.current.leaderboardHiddenHint(S.current.accountLeaderboardVisibility),
                action: S.current.leaderboardTurnOn,
                onPressed: () => context.read<PublicProfileCubit>().toggleEnabled(true),
              );
            }
            return BlocProvider(
              key: ValueKey(auth.user?.uid),
              create: (_) {
                final cubit = getIt<LeaderboardCubit>();
                unawaited(cubit.open(level));
                return cubit;
              },
              child: BlocBuilder<LeaderboardCubit, LeaderboardState>(
                builder: (final context, final state) => RefreshIndicator.adaptive(
                  onRefresh: context.read<LeaderboardCubit>().load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverSafeArea(
                        top: false,
                        sliver: SliverPadding(
                          padding: padding.copyWith(top: 16, bottom: 16),
                          sliver: SliverList.list(
                            children: [
                              _LevelLine(level: level),
                              const SizedBox(height: 16),
                              _TabSelector(selected: state.tab),
                              const SizedBox(height: 16),
                              _PeriodLine(tab: state.tab, dayTier: state.dayTier),
                              const SizedBox(height: 16),
                              _Body(state: state),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate({required this.padding, required this.text, required this.action, required this.onPressed});

  final EdgeInsets padding;
  final String text;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) => CustomScrollView(
    slivers: [
      SliverPadding(
        padding: padding.copyWith(top: 16),
        sliver: SliverList.list(
          children: [
            Text(
              text,
              style: TextStyle(fontSize: 15, height: 20 / 15, color: GameColors.of(context).text),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton(onPressed: onPressed, child: Text(action)),
            ),
          ],
        ),
      ),
    ],
  );
}

class _LeaderboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _LeaderboardAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(final BuildContext context) {
    final title = Text(S.current.leaderboardTitle);
    if (ScreenSpec.of(context).family != ChromeFamily.glass) {
      return AppBar(leading: const BackButton(), title: title);
    }
    return CupertinoNavigationBar(
      backgroundColor: GameColors.of(context).background,
      brightness: Theme.of(context).brightness,
      border: null,
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size.square(kMinInteractiveDimensionCupertino),
        onPressed: () => Navigator.of(context).maybePop(),
        child: Icon(CupertinoIcons.back, semanticLabel: MaterialLocalizations.of(context).backButtonTooltip),
      ),
      middle: title,
    );
  }
}

class _LevelLine extends StatelessWidget {
  const _LevelLine({required this.level});

  final PuzzleSessionDifficulty level;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${level.stars} ${level.label}',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colors.text),
        ),
        const SizedBox(height: 2),
        _Note(S.current.leaderboardChangeLevel),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(final BuildContext context) => Text(
    text,
    style: TextStyle(fontSize: 13, height: 18 / 13, color: GameColors.of(context).textSecondary),
  );
}

class _TabSelector extends StatelessWidget {
  const _TabSelector({required this.selected});

  final LeaderboardTab selected;

  @override
  Widget build(final BuildContext context) {
    final cubit = context.read<LeaderboardCubit>();
    final labels = {
      LeaderboardTab.today: S.current.leaderboardToday,
      LeaderboardTab.week: S.current.historyPeriodWeek,
      LeaderboardTab.month: S.current.historyPeriodMonth,
      LeaderboardTab.year: S.current.historyPeriodYear,
      LeaderboardTab.streaks: S.current.leaderboardStreaks,
    };
    if (ScreenSpec.of(context).family == ChromeFamily.glass) {
      return AppSegmentedControl<LeaderboardTab>(
        segments: labels,
        value: selected,
        onChanged: (final tab) => unawaited(cubit.selectTab(tab)),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final MapEntry(key: tab, value: label) in labels.entries)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: tab == selected,
                onSelected: (_) => unawaited(cubit.selectTab(tab)),
              ),
            ),
        ],
      ),
    );
  }
}

class _PeriodLine extends StatelessWidget {
  const _PeriodLine({required this.tab, required this.dayTier});

  final LeaderboardTab tab;
  final int? dayTier;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final label = _label(DateTime.now());
    final tier = dayTier;
    return Row(
      children: [
        Expanded(
          child: Text(
            label ?? '',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.text),
          ),
        ),
        if (tier != null)
          Semantics(
            label: '${S.current.leaderboardDayDifficulty}: $tier / ${DayDifficulty.maxTier}',
            excludeSemantics: true,
            child: Row(
              children: [
                Text(S.current.leaderboardDayDifficulty, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
                const SizedBox(width: 8),
                for (var i = DayDifficulty.minTier; i <= DayDifficulty.maxTier; i++)
                  Padding(
                    padding: const EdgeInsets.only(left: 3),
                    child: Icon(
                      i <= tier ? Icons.circle : Icons.circle_outlined,
                      size: 9,
                      color: i <= tier ? colors.accent : colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  String? _label(final DateTime now) {
    switch (tab) {
      case LeaderboardTab.today:
        return DateFormat.MMMMd().format(now);
      case LeaderboardTab.week:
        final range = LeaderboardKeys.range(LeaderboardPeriod.week, now);
        return '${DateFormat.MMMd().format(range.start)} – ${DateFormat.MMMd().format(range.end)}';
      case LeaderboardTab.month:
        return DateFormat.yMMMM().format(now);
      case LeaderboardTab.year:
        return '${now.year}';
      case LeaderboardTab.streaks:
        return null;
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final LeaderboardState state;

  @override
  Widget build(final BuildContext context) {
    if (state.isLoading && state.rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    if (state.error != null) {
      return Column(
        children: [
          const SizedBox(height: 24),
          _Note(S.current.leaderboardLoadFailed),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => unawaited(context.read<LeaderboardCubit>().load()),
            child: Text(S.current.leaderboardRetry),
          ),
        ],
      );
    }
    if (state.rows.isEmpty && state.me == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: _Note(S.current.leaderboardEmpty)),
      );
    }
    final me = state.me;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InsetSection(
          header: _header(state.tab),
          children: [for (final row in state.rows) LeaderboardRowView(row: row, values: _values(row))],
        ),
        if (me != null) ...[
          const SizedBox(height: 16),
          InsetSection(
            children: [LeaderboardRowView(row: me, values: _values(me))],
          ),
        ],
      ],
    );
  }

  String _header(final LeaderboardTab tab) => switch (tab) {
    LeaderboardTab.today => S.current.leaderboardTimeHeader,
    LeaderboardTab.week || LeaderboardTab.month || LeaderboardTab.year => S.current.leaderboardPointsHeader,
    LeaderboardTab.streaks => S.current.leaderboardStreaksHeader,
  };

  static (String, String?) _values(final LeaderboardRow row) => switch (row.value) {
    TimeValue(:final timeMs, :final extraSolutions) => (
      SessionSummary.formatDuration(timeMs),
      extraSolutions > 0 ? '+$extraSolutions' : null,
    ),
    PointsValue(:final points, :final days) => ('$points', '$days'),
    StreakValue(:final best, :final current) => ('$best', current > 0 ? '$current' : null),
  };
}
