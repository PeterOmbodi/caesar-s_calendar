import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/widgets/game_background.dart';
import 'package:caesar_puzzle/presentation/widgets/glass_circle_button.dart';
import 'package:flutter/material.dart';

/// Page frame of the race screens: the game's background, a back button with a title, content of limited width.
class RaceScaffold extends StatelessWidget {
  const RaceScaffold({super.key, required this.title, required this.child, this.backTooltip});

  static const double maxContentWidth = 480;

  final String title;
  final Widget child;
  final String? backTooltip;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxContentWidth),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        GlassCircleButton(
                          tooltip: backTooltip ?? MaterialLocalizations.of(context).backButtonTooltip,
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: Icon(Icons.adaptive.arrow_back, size: 22, color: colors.icon),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 22,
                              height: 28 / 22,
                              fontWeight: FontWeight.w700,
                              color: colors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(child: child),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
