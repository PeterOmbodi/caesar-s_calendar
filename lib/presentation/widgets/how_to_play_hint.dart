import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flip_flap/models/flip_flap_item.dart';
import 'package:flutter_flip_flap/split_flap_theme.dart';
import 'package:flutter_flip_flap/widgets/flip_flap_display.dart';

class HowToPlayHint extends StatelessWidget {
  const HowToPlayHint({
    super.key,
    this.onReplayOnboarding,
  });

  final VoidCallback? onReplayOnboarding;

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final steps = <String>[S.current.howToPlayStepDrag, S.current.howToPlayStepRotate, S.current.howToPlayStepFlip, S.current.howToPlayShadow];
    final viewWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      padding: EdgeInsets.all(viewWidth < 600 ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Text(S.current.howToPlayGoalTitle, style: textTheme.titleMedium),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(S.current.howToPlayGoalDescription),
                      const SizedBox(height: 4),
                      Text(S.current.howToPlayGoalDailyChange),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(S.current.howToPlayBasicsTitle, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          ...List.generate(
            steps.length,
            (final index) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${index + 1}. ${steps[index]}', style: textTheme.bodyMedium),
            ),
          ),
          const SizedBox(height: 16),
          Text(S.current.howToPlayControlsTitle, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.menu,
            title: S.current.howToPlayMenuTitle,
            description: S.current.howToPlayMenuDescription,
          ),
          _InfoRow(
            icon: Icons.history,
            title: S.current.howToPlayHistoryTitle,
            description: S.current.howToPlayHistoryDescription,
          ),
          _InfoRow(
            icon: Icons.lightbulb,
            title: S.current.howToPlaySolveTitle,
            description: S.current.howToPlaySolveDescription,
          ),
          _InfoRow(
            icon: Icons.tips_and_updates_outlined,
            title: S.current.howToPlayHintTitle,
            description: S.current.howToPlayHintDescription,
          ),
          _InfoRow(
            icon: Icons.undo,
            title: S.current.howToPlayUndoTitle,
            description: S.current.howToPlayUndoDescription,
          ),
          _InfoRow(
            icon: Icons.redo,
            title: S.current.howToPlayRedoTitle,
            description: S.current.howToPlayRedoDescription,
          ),
          _InfoRow(
            icon: Icons.refresh,
            title: S.current.howToPlayResetTitle,
            description: S.current.howToPlayResetDescription,
          ),
          const SizedBox(height: 16),
          Text(S.current.howToPlaySettingsTitle, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.settings,
            title: S.current.howToPlaySettingsPanelTitle,
            description: S.current.howToPlaySettingsPanelDescription,
          ),
          _InfoRow(
            icon: Icons.check_circle,
            iconColor: Colors.green,
            title: S.current.howToPlaySolvableTitle,
            description: S.current.howToPlaySolvableDescription,
          ),
          _InfoRow(
            icon: Icons.cancel,
            iconColor: Colors.red,
            title: S.current.howToPlayUnsolvableTitle,
            description: S.current.howToPlayUnsolvableDescription,
          ),
          _InfoColumn(
            leadWidget: FlipFlapDisplay.fromText(
              text: '42',
              unitsInPack: 4,
              unitConstraints: BoxConstraints(
                minWidth: 20,
                minHeight: 32,
              ),
              unitType: UnitType.number,
              useShortestWay: false,
            ),
            title: S.current.howToPlaySolutionsTitle,
            description: S.current.howToPlaySolutionsDescription,
          ),
          _InfoColumn(
            leadWidget: Row(
              children: [
                FlipFlapDisplay(
                  items: [
                    FlipFlapWidgetItem.flip(
                      flipAxis: Axis.horizontal,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(S.current.time, style: FlipFlapTheme.of(context).textStyle.copyWith(fontSize: 14)),
                        ),
                      ),
                    ),
                  ],
                  unitConstraints: const BoxConstraints(minWidth: 20, minHeight: 32),
                ),
                FlipFlapDisplay.fromText(
                  text: '01:23',
                  unitConstraints: const BoxConstraints(minWidth: 20, minHeight: 32),
                )
              ],
            ),
            title: S.current.howToPlayTimerTitle,
            description: S.current.howToPlayTimerDescription,
          ),
          _InfoColumn(
            leadWidget: Row(
              children: [
                FlipFlapDisplay(
                  items: [
                    FlipFlapWidgetItem.flip(
                      flipAxis: Axis.horizontal,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(S.current.solutionShort, style: FlipFlapTheme.of(context).textStyle.copyWith(fontSize: 14)),
                        ),
                      ),
                    ),
                  ],
                  unitConstraints: const BoxConstraints(minWidth: 20, minHeight: 32),
                ),
                FlipFlapDisplay.fromText(
                  text: ' #01',
                  unitConstraints: const BoxConstraints(minWidth: 20, minHeight: 32),
                )
              ],
            ),
            title: S.current.howToPlaySolutionNumbTitle,
            description: S.current.howToPlaySolutionNumbDescription,
          ),
          if (onReplayOnboarding != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onReplayOnboarding,
              icon: const Icon(Icons.play_circle_outline),
              label: Text(S.current.onboardingReplayButton),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, required this.description, this.iconColor});

  final IconData icon;
  final String title;
  final String description;
  final Color? iconColor;

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(description, style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({
    required this.leadWidget,
    required this.title,
    required this.description,
  });

  final Widget leadWidget;
  final String title;
  final String description;

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              leadWidget,
              const SizedBox(width: 12),
              Text(title, style: textTheme.titleSmall),
            ],
          ) ,

          Padding(
            padding: const EdgeInsets.only(left: 36, top: 4),
            child: Text(description, style: textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
