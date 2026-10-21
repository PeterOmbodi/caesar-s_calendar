import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/widgets/glass_circle_button.dart';
import 'package:flutter/material.dart';

/// A sheet on a phone in portrait, a centered panel elsewhere. Sized to its content.
Future<T?> showGameSheet<T>(
  final BuildContext context, {
  required final String title,
  required final WidgetBuilder builder,
}) {
  final spec = ScreenSpec.of(context);
  if (spec.window == WindowClass.compact && !spec.isLandscape) {
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (final sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.96),
        child: _GameSheetPanel(isSheet: true, title: title, builder: builder),
      ),
    );
  }
  return showDialog<T>(
    context: context,
    builder: (_) => SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
            child: _GameSheetPanel(isSheet: false, title: title, builder: builder),
          ),
        ),
      ),
    ),
  );
}

class _GameSheetPanel extends StatelessWidget {
  const _GameSheetPanel({required this.isSheet, required this.title, required this.builder});

  final bool isSheet;
  final String title;
  final WidgetBuilder builder;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final radius = isSheet
        ? const BorderRadius.vertical(top: Radius.circular(30))
        : const BorderRadius.all(Radius.circular(24));
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
            mainAxisSize: MainAxisSize.min,
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
                          title,
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
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + MediaQuery.paddingOf(context).bottom),
                  child: Builder(builder: builder),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
