import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/actions/game_action.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/actions/game_action_visuals.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/chrome/game_chrome.dart';
import 'package:caesar_puzzle/presentation/theme/chrome_theme.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/widgets/glass_surface.dart';
import 'package:flutter/material.dart';

class GlassChrome extends GameChrome {
  const GlassChrome({super.key, required super.actions, required super.spec, required super.onInvoke});

  static const double edgeMargin = 16;
  static const double barMaxWidth = 480;
  static const double slotWidth = 64;
  static const double slotHeight = 54;
  static const double sideRailMargin = 24;
  static const double sideRailWidth = 226;
  static const double sideRailGap = 20;

  static EdgeInsets reservedInsets(final BuildContext context) {
    final extent = ChromeTheme.of(context).barHeight + edgeMargin;
    return switch (ScreenSpec.of(context).toolbar) {
      ToolbarPlacement.compactRail => EdgeInsets.only(right: extent),
      ToolbarPlacement.labeledRail => const EdgeInsets.only(left: sideRailMargin + sideRailWidth + sideRailGap),
      ToolbarPlacement.bottomBar => EdgeInsets.only(bottom: extent),
    };
  }

  bool get _isRail => spec.toolbar == ToolbarPlacement.compactRail;

  @override
  Widget build(final BuildContext context) {
    if (spec.toolbar == ToolbarPlacement.labeledRail) {
      return Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(sideRailMargin),
          child: _LabeledRail(actions: actions, onInvoke: onInvoke),
        ),
      );
    }
    final chrome = ChromeTheme.of(context);
    final overflow = actions.where((final a) => a.slot == ActionSlot.overflow).toList();
    final slots = <Widget>[
      for (final action in actions.where((final a) => a.slot == ActionSlot.primary))
        _ActionSlot(action: action, onPressed: () => onInvoke(action)),
      if (overflow.isNotEmpty) _MoreSlot(items: overflow, isRail: _isRail, onInvoke: onInvoke),
    ];
    final radius = BorderRadius.circular(chrome.barRadius);

    if (_isRail) {
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: edgeMargin),
          child: GlassSurface(
            borderRadius: radius,
            child: SizedBox(
              width: chrome.barHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(mainAxisSize: MainAxisSize.min, spacing: 2, children: slots),
              ),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(edgeMargin, 0, edgeMargin, edgeMargin),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: spec.window == WindowClass.compact ? double.infinity : barMaxWidth),
          child: GlassSurface(
            borderRadius: radius,
            child: SizedBox(
              height: chrome.barHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: slots),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionSlot extends StatelessWidget {
  const _ActionSlot({required this.action, required this.onPressed});

  final GameAction action;
  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    if (action.id == GameActionId.solutionCounter) {
      return SizedBox(
        width: GlassChrome.slotWidth,
        height: GlassChrome.slotHeight,
        child: Center(
          child: Text.rich(
            TextSpan(
              text: '${action.count}',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colors.text),
              children: [
                TextSpan(
                  text: ' / ${action.total}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: colors.textSecondary),
                ),
              ],
            ),
            style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
          ),
        ),
      );
    }
    return _SlotButton(
      icon: action.id.icon,
      label: action.id.label,
      tooltip: action.id.tooltip,
      enabled: action.enabled,
      active: action.active,
      busy: action.busy,
      onPressed: onPressed,
    );
  }
}

class _SlotButton extends StatelessWidget {
  const _SlotButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
    this.enabled = true,
    this.active = false,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onPressed;
  final bool enabled;
  final bool active;
  final bool busy;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final foreground = !enabled
        ? colors.iconDisabled
        : active
        ? colors.onActive
        : colors.icon;
    const radius = BorderRadius.all(Radius.circular(GlassChrome.slotHeight / 2));
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? colors.active : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            width: GlassChrome.slotWidth,
            height: GlassChrome.slotHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 2,
              children: [
                if (busy)
                  SizedBox.square(
                    dimension: 24,
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
                    ),
                  )
                else
                  Icon(icon, size: 24, color: foreground),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(fontSize: 11, height: 13 / 11, fontWeight: FontWeight.w500, color: foreground),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreSlot extends StatefulWidget {
  const _MoreSlot({required this.items, required this.isRail, required this.onInvoke});

  final List<GameAction> items;
  final bool isRail;
  final ValueChanged<GameAction> onInvoke;

  @override
  State<_MoreSlot> createState() => _MoreSlotState();
}

class _MoreSlotState extends State<_MoreSlot> {
  static const double _menuWidth = 236;
  static const double _menuGap = 8;

  var _isOpen = false;

  Future<void> _open() async {
    final box = context.findRenderObject()! as RenderBox;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    final screen = MediaQuery.sizeOf(context);
    setState(() => _isOpen = true);
    final picked = await showGeneralDialog<GameAction>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (final dialogContext, _, _) => Stack(
        children: [
          Positioned(
            right: widget.isRail ? screen.width - anchor.left + _menuGap : screen.width - anchor.right,
            bottom: widget.isRail ? screen.height - anchor.bottom : screen.height - anchor.top + _menuGap,
            width: _menuWidth,
            child: _MoreMenu(items: widget.items, onPick: (final a) => Navigator.of(dialogContext).pop(a)),
          ),
        ],
      ),
      transitionBuilder: (final context, final animation, _, final child) =>
          FadeTransition(opacity: animation, child: child),
    );
    if (!mounted) {
      return;
    }
    setState(() => _isOpen = false);
    if (picked != null) {
      widget.onInvoke(picked);
    }
  }

  @override
  Widget build(final BuildContext context) => _SlotButton(
    icon: Icons.more_horiz,
    label: S.current.toolbarMore,
    tooltip: S.current.toolbarMore,
    active: _isOpen,
    onPressed: _open,
  );
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.items, required this.onPick});

  final List<GameAction> items;
  final ValueChanged<GameAction> onPick;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    const radius = BorderRadius.all(Radius.circular(22));
    return GlassSurface(
      borderRadius: radius,
      color: colors.menu,
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in items)
                InkWell(
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
                  onTap: item.enabled ? () => onPick(item) : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    child: Row(
                      spacing: 12,
                      children: [
                        Icon(item.id.icon, size: 22, color: item.enabled ? colors.icon : colors.iconDisabled),
                        Expanded(
                          child: Text(
                            item.id.label,
                            style: TextStyle(
                              fontSize: 16,
                              height: 21 / 16,
                              color: item.enabled ? colors.text : colors.iconDisabled,
                            ),
                          ),
                        ),
                        if (item.count != null)
                          Text(
                            '${item.count}',
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.textSecondary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledRail extends StatelessWidget {
  const _LabeledRail({required this.actions, required this.onInvoke});

  final List<GameAction> actions;
  final ValueChanged<GameAction> onInvoke;

  String get _title {
    final ids = actions.map((final a) => a.id);
    if (ids.contains(GameActionId.solutionCounter)) {
      return S.current.railSectionSolutions;
    }
    if (ids.contains(GameActionId.saveLayout)) {
      return S.current.railSectionLayout;
    }
    return ids.contains(GameActionId.rotate) ? S.current.railSectionPiece : S.current.railSectionGame;
  }

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final platform = Theme.of(context).platform;
    final apple = platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    final primary = actions.where((final a) => a.slot == ActionSlot.primary);
    final overflow = actions.where((final a) => a.slot == ActionSlot.overflow);

    Widget row(final GameAction action) => _RailRow(
      action: action,
      shortcut: action.id.shortcutLabel(apple: apple),
      onPressed: () => onInvoke(action),
    );

    return SizedBox(
      width: GlassChrome.sideRailWidth,
      child: GlassSurface(
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 2,
              children: [
                _RailHeader(_title),
                for (final action in primary) row(action),
                if (overflow.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Divider(height: 1, thickness: 1, color: colors.gridLine),
                  ),
                  _RailHeader(S.current.railSectionPuzzle),
                  for (final action in overflow) row(action),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RailHeader extends StatelessWidget {
  const _RailHeader(this.text);

  final String text;

  @override
  Widget build(final BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        height: 1,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.9,
        color: GameColors.of(context).textSecondary,
      ),
    ),
  );
}

class _RailRow extends StatelessWidget {
  const _RailRow({required this.action, required this.shortcut, required this.onPressed});

  final GameAction action;
  final String? shortcut;
  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final isCounter = action.id == GameActionId.solutionCounter;
    final foreground = !action.enabled
        ? colors.iconDisabled
        : action.active
        ? colors.onActive
        : colors.icon;
    final meta = isCounter
        ? '${action.count} / ${action.total}'
        : action.count != null
        ? '${action.count}'
        : null;
    const radius = BorderRadius.all(Radius.circular(12));
    return Material(
      color: action.active ? colors.active : Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: action.enabled && !isCounter ? onPressed : null,
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              spacing: 12,
              children: [
                SizedBox.square(
                  dimension: 22,
                  child: isCounter
                      ? null
                      : action.busy
                      ? Padding(
                          padding: const EdgeInsets.all(3),
                          child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
                        )
                      : Icon(action.id.icon, size: 22, color: foreground),
                ),
                Expanded(
                  child: Text(
                    isCounter ? S.current.railSolution : action.id.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w500, color: foreground),
                  ),
                ),
                if (meta != null)
                  Text(
                    meta,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  )
                else if (shortcut != null)
                  _Kbd(shortcut!, active: action.active),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Kbd extends StatelessWidget {
  const _Kbd(this.text, {required this.active});

  final String text;
  final bool active;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final color = active ? colors.onActive : colors.textSecondary;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        border: Border.all(color: active ? colors.onActive.withValues(alpha: 0.4) : colors.gridLine),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(text, style: TextStyle(fontSize: 12, height: 1, fontWeight: FontWeight.w500, color: color)),
      ),
    );
  }
}
