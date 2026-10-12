import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/auth/bloc/auth_cubit.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/layouts/board_layouts_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/solution_indicator_difficulty_x.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_display.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/utils/board_layout_cells.dart';
import 'package:caesar_puzzle/presentation/utils/month_label.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_session_difficulty_x.dart';
import 'package:caesar_puzzle/presentation/widgets/glass_circle_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;

typedef _HeaderType = ({TextStyle title, TextStyle subtitle, TextStyle goal, double goalGap});

class PuzzleHeader extends StatelessWidget {
  const PuzzleHeader({super.key, required this.onLayoutsPressed, required this.onSettingsPressed});

  final VoidCallback onLayoutsPressed;
  final VoidCallback onSettingsPressed;

  static _HeaderType _typeFor(final ScreenSpec spec) => switch (spec.window) {
    WindowClass.compact when spec.isLandscape => (
      title: const TextStyle(fontSize: 18, height: 22 / 18, fontWeight: FontWeight.w700),
      subtitle: const TextStyle(fontSize: 12, height: 15 / 12),
      goal: const TextStyle(fontSize: 13, height: 16 / 13, fontWeight: FontWeight.w500),
      goalGap: 2,
    ),
    WindowClass.compact => (
      title: const TextStyle(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w700),
      subtitle: const TextStyle(fontSize: 13, height: 17 / 13),
      goal: const TextStyle(fontSize: 14, height: 18 / 14, fontWeight: FontWeight.w500),
      goalGap: 4,
    ),
    _ => (
      title: const TextStyle(fontSize: 28, height: 34 / 28, fontWeight: FontWeight.w700),
      subtitle: const TextStyle(fontSize: 15, height: 20 / 15),
      goal: const TextStyle(fontSize: 17, height: 22 / 17, fontWeight: FontWeight.w500),
      goalGap: 6,
    ),
  };

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final spec = ScreenSpec.of(context);
    final type = _typeFor(spec);
    final buttonsRight = spec.toolbar == ToolbarPlacement.labeledRail;
    final indicator = context.select<SettingsCubit, SolutionIndicator>((final c) => c.state.solutionIndicator);
    final (date, customKey) = context.select<PuzzleBloc, (DateTime, String?)>(
      (final bloc) => (bloc.state.selectedDate, bloc.state.isCustomConfig ? cellsKey(bloc.state.blockedCells) : null),
    );
    final isCustomConfig = customKey != null;
    final isEditing = context.select<PuzzleBloc, bool>((final bloc) => bloc.state.isEditingLayout);
    final layoutName = context.select<BoardLayoutsCubit, String?>(
      (final cubit) => customKey == null ? null : cubit.state.entryWithKey(customKey)?.layout.name,
    );
    final layouts = _LayoutsButton(isCustomConfig: isCustomConfig, onPressed: onLayoutsPressed);
    const buttonGap = 12.0;
    final month = shortMonthName(date.month);
    final day = '${date.day}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (buttonsRight)
            const SizedBox(width: GlassCircleButton.defaultSize * 2 + buttonGap)
          else
            layouts,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Text(
                    intl.DateFormat.MMMMd().format(date),
                    style: type.title.copyWith(color: colors.text),
                    textAlign: TextAlign.center,
                  ),
                  Text.rich(
                    TextSpan(
                      style: type.subtitle.copyWith(color: colors.textSecondary),
                      children: [
                        if (isEditing)
                          TextSpan(text: S.current.headerEditingLayout, style: TextStyle(color: colors.customConfig))
                        else
                          TextSpan(text: '${S.current.headerDailyPuzzle} · ${indicator.sessionDifficulty.label}'),
                        if (isCustomConfig && !isEditing)
                          TextSpan(
                            text: ' · ${layoutName ?? S.current.historyConfigCustom}',
                            style: TextStyle(color: colors.customConfig),
                          ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: type.goalGap),
                  Text.rich(
                    TextSpan(
                      style: type.goal.copyWith(color: colors.textSecondary),
                      children: highlight(
                        S.current.headerGoal(month, day),
                        [month, day],
                        TextStyle(color: colors.accent, fontWeight: FontWeight.w700),
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          if (buttonsRight) ...[layouts, const SizedBox(width: buttonGap)],
          _SettingsButton(onPressed: onSettingsPressed),
        ],
      ),
    );
  }

  /// Splits [text] so that the first occurrence of every part in [parts] gets [style].
  @visibleForTesting
  static List<TextSpan> highlight(final String text, final List<String> parts, final TextStyle style) {
    final ranges = <({int start, int end})>[];
    for (final part in parts) {
      final start = part.isEmpty ? -1 : text.indexOf(part);
      if (start >= 0) {
        ranges.add((start: start, end: start + part.length));
      }
    }
    ranges.sort((final a, final b) => a.start.compareTo(b.start));

    final spans = <TextSpan>[];
    var position = 0;
    for (final range in ranges) {
      if (range.start < position) {
        continue;
      }
      if (range.start > position) {
        spans.add(TextSpan(text: text.substring(position, range.start)));
      }
      spans.add(TextSpan(text: text.substring(range.start, range.end), style: style));
      position = range.end;
    }
    if (position < text.length) {
      spans.add(TextSpan(text: text.substring(position)));
    }
    return spans;
  }
}

class _LayoutsButton extends StatelessWidget {
  const _LayoutsButton({required this.isCustomConfig, required this.onPressed});

  final bool isCustomConfig;
  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GlassCircleButton(
          tooltip: S.current.headerLayoutsTooltip,
          onPressed: onPressed,
          child: Icon(Icons.grid_view, size: 22, color: colors.icon),
        ),
        if (isCustomConfig)
          Positioned(
            right: 6,
            top: 6,
            child: IgnorePointer(
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: colors.customConfig,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.background, width: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (final p, final n) => p.user?.uid != n.user?.uid,
      builder: (final context, final auth) {
        final user = auth.user;
        if (user == null) {
          return GlassCircleButton(
            tooltip: S.current.settings,
            onPressed: onPressed,
            child: Icon(Icons.settings, size: 22, color: colors.icon),
          );
        }
        final displayName = AccountDisplay.bestDisplayName(user);
        return GlassCircleButton(
          tooltip: S.current.settings,
          onPressed: onPressed,
          badge: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: colors.background,
              shape: BoxShape.circle,
              border: Border.all(color: colors.glassLine),
            ),
            child: Icon(Icons.settings, size: 12, color: colors.icon),
          ),
          child: AccountAvatar(
            photoUrl: AccountDisplay.bestPhotoUrl(user),
            fallbackLabel: AccountDisplay.avatarInitial(displayName),
            radius: 15,
          ),
        );
      },
    );
  }
}
