import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/help/how_to_play_content.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/services/keyboard_presence.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/widgets/glass_circle_button.dart';
import 'package:caesar_puzzle/presentation/widgets/inset_section.dart';
import 'package:caesar_puzzle/presentation/widgets/key_cap.dart';
import 'package:flutter/material.dart';

Future<void> showHowToPlaySheet(final BuildContext context, {final VoidCallback? onReplayOnboarding}) {
  final spec = ScreenSpec.of(context);
  if (spec.window == WindowClass.compact && !spec.isLandscape) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.96,
        child: _HowToPlayPanel(isSheet: true, onReplayOnboarding: onReplayOnboarding),
      ),
    );
  }
  return showDialog<void>(
    context: context,
    builder: (_) => SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
            child: _HowToPlayPanel(isSheet: false, onReplayOnboarding: onReplayOnboarding),
          ),
        ),
      ),
    ),
  );
}

class _HowToPlayPanel extends StatelessWidget {
  const _HowToPlayPanel({required this.isSheet, required this.onReplayOnboarding});

  final bool isSheet;
  final VoidCallback? onReplayOnboarding;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final platform = Theme.of(context).platform;
    final apple = platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    final radius = isSheet
        ? const BorderRadius.vertical(top: Radius.circular(30))
        : const BorderRadius.all(Radius.circular(24));
    final onReplayOnboarding = this.onReplayOnboarding;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: radius,
        boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isSheet)
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: colors.textSecondary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, isSheet ? 10 : 18, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          S.current.howToPlayTitle,
                          style: TextStyle(
                            fontSize: 28,
                            height: 34 / 28,
                            fontWeight: FontWeight.w700,
                            color: colors.text,
                          ),
                        ),
                      ),
                    ),
                    GlassCircleButton(
                      tooltip: S.current.toolbarClose,
                      size: 36,
                      onPressed: () => Navigator.of(context).pop(),
                      child: Icon(Icons.close, size: 20, color: colors.icon),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: KeyboardPresence.instance.connected,
                  builder: (final context, final hasKeyboard, _) {
                    final sections = howToPlaySections(apple: apple, hasKeyboard: hasKeyboard);
                    return ListView(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + MediaQuery.paddingOf(context).bottom),
                      children: [
                        for (final section in sections) ...[
                          InsetSection(
                            header: section.title,
                            footer: section.footer,
                            children: [
                              for (final item in section.items)
                                InsetRow(
                                  icon: item.icon,
                                  title: item.title,
                                  subtitle: item.body,
                                  trailing: item.shortcut == null ? null : KeyCap(item.shortcut!),
                                ),
                            ],
                          ),
                          const SizedBox(height: 28),
                        ],
                        if (onReplayOnboarding != null)
                          InsetSection(
                            children: [
                              InsetRow(
                                icon: Icons.play_circle_outline,
                                title: S.current.onboardingReplayButton,
                                titleColor: colors.accent,
                                onTap: onReplayOnboarding,
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
