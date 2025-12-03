import 'package:flutter/material.dart';

class HowToPlayHint extends StatelessWidget {
  const HowToPlayHint({super.key});

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final steps = <String>[
      'Drag & Drop pieces onto the board.',
      'Rotate pieces with a single tap/click.',
      'Flip pieces with a double tap/click.',
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
                        Text('Goal', style: textTheme.titleMedium),
                        const SizedBox(height: 4),
                        const Text(
                          'Place all puzzle pieces on the board so that exactly two cells remain free — the ones '
                          'corresponding to the current month and current day.',
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Every day the target cells change, creating a new unique challenge. Move the predefined '
                          'blocks to reshape the board when you want extra variety.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Basics', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          ...List.generate(
            steps.length,
            (final index) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${index + 1}. ${steps[index]}', style: textTheme.bodyMedium),
            ),
          ),
          const SizedBox(height: 16),
          Text('Controls & buttons', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          const _ActionRow(
            icon: Icons.menu,
            title: 'Menu',
            description: 'Open menu panel',
          ),
          const _ActionRow(
            icon: Icons.lightbulb,
            title: 'Solve',
            description: 'Shows the automatic solution for the current layout.',
          ),
          const _ActionRow(
            icon: Icons.tips_and_updates_outlined,
            title: 'Hint',
            description: 'Reveals one move for a random piece.',
          ),
          const _ActionRow(
            icon: Icons.undo,
            title: 'Undo',
            description: 'Reverts your last action.',
          ),
          const _ActionRow(
            icon: Icons.redo,
            title: 'Redo',
            description: 'Repeats the last reverted action.',
          ),
          const _ActionRow(
            icon: Icons.refresh,
            title: 'Reset',
            description: 'Returns the puzzle to its initial state.',
          ),
          const SizedBox(height: 16),
          Text('Settings & indicators', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          const _ActionRow(
            icon: Icons.settings,
            title: 'Settings panel',
            description:
                'Switch theme, lock/unlock the configuration, toggle overlapping and snapping, highlight pieces when '
                'a hint is shown, display solvability status, show the number of possible solutions, and track solving '
                'time.',
          ),
          const _ActionRow(
            icon: Icons.check_circle,
            iconColor: Colors.green,
            title: 'Solvable layout',
            description: 'Green indicator appears when the current configuration has at least one solution.',
          ),
          const _ActionRow(
            icon: Icons.cancel,
            iconColor: Colors.red,
            title: 'Unsolvable layout',
            description: 'Red indicator warns that the current configuration has no solutions — adjust the setup.',
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
