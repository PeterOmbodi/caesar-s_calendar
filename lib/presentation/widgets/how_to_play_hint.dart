import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:flutter/material.dart';

class HowToPlayHint extends StatelessWidget {
  const HowToPlayHint({super.key});

  @override
  Widget build(final BuildContext context) {

    final textTheme = Theme.of(context).textTheme;
    final steps = <String>[
      S.current.howToPlayStepDrag,
      S.current.howToPlayStepRotate,
      S.current.howToPlayStepFlip,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.current.howToPlayGoalTitle,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(S.current.howToPlayGoalDescription),
                        const SizedBox(height: 4),
                        Text(S.current.howToPlayGoalDailyChange),
                      ],
                    ),
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
              child: Text(
                '${index + 1}. ${steps[index]}',
                style: textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(S.current.howToPlayControlsTitle, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          _ActionRow(
            icon: Icons.menu,
            title: S.current.howToPlayMenuTitle,
            description: S.current.howToPlayMenuDescription,
          ),
          _ActionRow(
            icon: Icons.lightbulb,
            title: S.current.howToPlaySolveTitle,
            description: S.current.howToPlaySolveDescription,
          ),
          _ActionRow(
            icon: Icons.tips_and_updates_outlined,
            title: S.current.howToPlayHintTitle,
            description: S.current.howToPlayHintDescription,
          ),
          _ActionRow(
            icon: Icons.undo,
            title: S.current.howToPlayUndoTitle,
            description: S.current.howToPlayUndoDescription,
          ),
          _ActionRow(
            icon: Icons.redo,
            title: S.current.howToPlayRedoTitle,
            description: S.current.howToPlayRedoDescription,
          ),
          _ActionRow(
            icon: Icons.refresh,
            title: S.current.howToPlayResetTitle,
            description: S.current.howToPlayResetDescription,
          ),
          const SizedBox(height: 16),
          Text(S.current.howToPlaySettingsTitle, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          _ActionRow(
            icon: Icons.settings,
            title: S.current.howToPlaySettingsPanelTitle,
            description: S.current.howToPlaySettingsPanelDescription,
          ),
          _ActionRow(
            icon: Icons.check_circle,
            iconColor: Colors.green,
            title: S.current.howToPlaySolvableTitle,
            description: S.current.howToPlaySolvableDescription,
          ),
          _ActionRow(
            icon: Icons.cancel,
            iconColor: Colors.red,
            title: S.current.howToPlayUnsolvableTitle,
            description: S.current.howToPlayUnsolvableDescription,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.description,
    this.iconColor,
  });

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
