import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:caesar_puzzle/presentation/widgets/how_to_play_hint.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../../generated/l10n.dart';

class FloatingPanel extends StatefulWidget {
  const FloatingPanel({super.key, required this.children});

  static const double widgetSpacing = 0.0;
  static const double panelElevation = 8.0;
  static const double panelBorderRadius = 16.0;
  static const double panelAlpha = 0.5;
  static const double itemWidth = 48.0;
  static const double itemHeight = 40.0;
  static const double itemPadding = 4.0;
  static const double verticalPadding = 8.0;
  static const double horizontalPadding = 4.0;
  static const double screenMargin = 24.0;

  static const Duration openAnimationDelay = Duration(milliseconds: 100);
  static const Duration closeAnimationDelay = Duration(milliseconds: 80);
  static const Duration animationDuration = Duration(milliseconds: 200);
  static const Duration switcherDuration = Duration(milliseconds: 300);

  final List<Widget> children;

  @override
  FloatingPanelState createState() => FloatingPanelState();
}

class FloatingPanelState extends State<FloatingPanel> with TickerProviderStateMixin {
  bool _isPanelOpen = false;
  int _visibleChildren = 0;
  int _animationId = 0;

  @override
  void didUpdateWidget(final FloatingPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_visibleChildren > widget.children.length) {
      setState(() => _visibleChildren = widget.children.length);
    }
  }

  Future<void> _togglePanel() async {
    if (_isPanelOpen) {
      await _animateClose();
    } else {
      await _animateOpen();
    }
  }

  Future<void> _animateOpen() async {
    final id = ++_animationId;
    setState(() => _isPanelOpen = true);

    for (var i = _visibleChildren; i < widget.children.length; i++) {
      if (!mounted || id != _animationId) return;
      setState(() => _visibleChildren = i + 1);
      await Future<void>.delayed(FloatingPanel.openAnimationDelay);
    }
  }

  Future<void> _animateClose() async {
    final id = ++_animationId;
    setState(() => _isPanelOpen = false);

    for (var i = _visibleChildren; i > 0; i--) {
      if (!mounted || id != _animationId) return;
      setState(() => _visibleChildren = i - 1);
      await Future<void>.delayed(FloatingPanel.closeAnimationDelay);
    }
  }

  Future<void> _showHowToPlayDialog() async {
    await showDialog(
      context: context,
      builder: (final context) => PlatformAlertDialog(
        title: const Text('How to Play'),
        content: const HowToPlayHint(),
        actions: [PlatformDialogAction(onPressed: () => Navigator.of(context).pop(), child: Text(S.of(context).ok))],
      ),
    );
  }

  @override
  Widget build(final BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - FloatingPanel.screenMargin),
    child: Material(
      elevation: FloatingPanel.panelElevation,
      borderRadius: BorderRadius.circular(FloatingPanel.panelBorderRadius),
      color: AppColors.current.primary.withValues(alpha: FloatingPanel.panelAlpha),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: FloatingPanel.verticalPadding,
          horizontal: FloatingPanel.horizontalPadding,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: AnimatedSize(
                duration: FloatingPanel.switcherDuration,
                curve: Curves.easeInOut,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  height: FloatingPanel.itemHeight,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(widget.children.length + 1, (final i) {
                        final isFirst = i == 0;
                        final isLast = i == widget.children.length;
                        final item = isFirst
                            ? IconButton(icon: const Icon(Icons.info_outline_rounded), onPressed: _showHowToPlayDialog)
                            : _AnimatedPanelItem(
                                index: i,
                                isVisible: i <= _visibleChildren,
                                child: widget.children[i - 1],
                              );
                        return Padding(
                          padding: kIsWeb && (isFirst || isLast)
                              ? EdgeInsets.only(right: 4)
                              : EdgeInsets.symmetric(horizontal: FloatingPanel.widgetSpacing),
                          child: item,
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: AnimatedSwitcher(
                duration: FloatingPanel.switcherDuration,
                child: Icon(_isPanelOpen ? Icons.close : Icons.menu, key: ValueKey(_isPanelOpen)),
              ),
              onPressed: _togglePanel,
              tooltip: _isPanelOpen ? S.current.hideControls : S.current.showControls,
            ),
          ],
        ),
      ),
    ),
  );
}

class _AnimatedPanelItem extends StatelessWidget {
  const _AnimatedPanelItem({required this.index, required this.isVisible, required this.child});

  final int index;
  final bool isVisible;
  final Widget child;

  @override
  Widget build(final BuildContext context) => AnimatedSize(
    duration: FloatingPanel.animationDuration,
    curve: Curves.easeInOut,
    alignment: Alignment.centerLeft,
    child: AnimatedSwitcher(
      duration: FloatingPanel.animationDuration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (final widgetChild, final animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: widgetChild),
      ),
      child: isVisible
          ? SizedBox(
              key: ValueKey('floating-panel-item-$index-visible'),
              width: FloatingPanel.itemWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: FloatingPanel.itemPadding),
                child: child,
              ),
            )
          : SizedBox(key: ValueKey('floating-panel-item-$index-hidden'), width: 0),
    ),
  );
}
