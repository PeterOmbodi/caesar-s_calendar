import 'package:flutter/material.dart';

class FloatingPanel extends StatelessWidget {
  const FloatingPanel({super.key, required this.children, required this.morePanel});

  static const double panelRadius = 28.0;
  static const double compactPanelRadius = 16.0;
  static const double buttonSize = 40.0;
  static const double itemPadding = 2.0;
  static const double itemExtent = buttonSize + itemPadding * 2;
  static const double verticalPadding = 6.0;
  static const double horizontalPadding = 12.0;
  static const double verticalItemSpacing = 12.0;
  static const double screenMargin = 24.0;
  static const double panelGap = 8.0;
  static const double morePanelWidth = 56.0;
  static const Duration itemDelay = Duration(milliseconds: 80);
  static const Duration itemAnimationDuration = Duration(milliseconds: 100);
  static const Duration surfaceAnimationDuration = Duration(milliseconds: 300);

  final List<Widget> children;
  final Widget morePanel;

  @override
  Widget build(final BuildContext context) {
    final viewWidth = MediaQuery.of(context).size.width;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: viewWidth - screenMargin),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(child: FloatingHorizontalToolbar(children: children)),
          const SizedBox(width: panelGap),
          SizedBox(width: morePanelWidth, child: morePanel),
        ],
      ),
    );
  }
}

class FloatingHorizontalToolbar extends StatefulWidget {
  const FloatingHorizontalToolbar({super.key, required this.children});

  final List<Widget> children;

  @override
  State<FloatingHorizontalToolbar> createState() => _FloatingHorizontalToolbarState();
}

class _FloatingHorizontalToolbarState extends State<FloatingHorizontalToolbar>
    with _ToolbarExpansionState<FloatingHorizontalToolbar> {
  @override
  List<Widget> get items => widget.children;

  @override
  bool get initiallyOpen => true;

  @override
  Widget build(final BuildContext context) => _ToolbarSurface(
    isOpen: _isOpen,
    child: SizedBox(
      height: FloatingPanel.itemExtent,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: AnimatedSize(
          duration: FloatingPanel.surfaceAnimationDuration,
          curve: Curves.easeInOut,
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...List.generate(itemCount, (final index) {
                final child = items[index];
                return _AnimatedHorizontalToolbarItem(
                  isVisible: index < _visibleItems,
                  width: _horizontalItemWidth(child),
                  child: _asHorizontalToolbarItem(child),
                );
              }),
              _HorizontalToolbarItem(
                child: IconButton(icon: Icon(_isOpen ? Icons.chevron_right : Icons.chevron_left), onPressed: _toggle),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ToolbarControlGroup extends StatelessWidget {
  const ToolbarControlGroup({super.key, required this.children, this.showOutline = false});

  final List<Widget> children;
  final bool showOutline;

  int get controlCount => children.length;

  double get width => controlCount * FloatingPanel.itemExtent;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      height: FloatingPanel.itemExtent,
      child: CustomPaint(
        foregroundPainter: showOutline
            ? _ToolbarGroupOutlinePainter(color: colorScheme.onPrimaryContainer.withValues(alpha: 0.72))
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: children.map((final child) => _HorizontalToolbarItem(child: child)).toList(),
        ),
      ),
    );
  }
}

class FloatingVerticalMoreToolbar extends StatefulWidget {
  const FloatingVerticalMoreToolbar({
    super.key,
    required this.children,
    required this.moreTooltip,
    required this.closeTooltip,
  });

  final List<Widget> children;
  final String moreTooltip;
  final String closeTooltip;

  @override
  State<FloatingVerticalMoreToolbar> createState() => _FloatingVerticalMoreToolbarState();
}

mixin _ToolbarExpansionState<T extends StatefulWidget> on State<T> {
  var _isOpen = false;
  var _visibleItems = 0;
  var _animationId = 0;

  List<Widget> get items;

  int get itemCount => items.length;

  bool get initiallyOpen => false;

  @override
  void initState() {
    super.initState();
    _isOpen = initiallyOpen;
    _visibleItems = initiallyOpen ? itemCount : 0;
  }

  @override
  void didUpdateWidget(covariant final T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isOpen) {
      _visibleItems = itemCount;
    } else if (_visibleItems > itemCount) {
      _visibleItems = itemCount;
    }
  }

  Future<void> _toggle() async {
    if (_isOpen) {
      await _animateClose();
    } else {
      await _animateOpen();
    }
  }

  Future<void> _animateOpen() async {
    final id = ++_animationId;
    setState(() => _isOpen = true);

    for (var i = _visibleItems; i < itemCount; i++) {
      if (!mounted || id != _animationId) {
        return;
      }
      setState(() => _visibleItems = i + 1);
      await Future<void>.delayed(FloatingPanel.itemDelay);
    }
  }

  Future<void> _animateClose() async {
    final id = ++_animationId;
    setState(() => _isOpen = false);

    for (var i = _visibleItems; i > 0; i--) {
      if (!mounted || id != _animationId) {
        return;
      }
      setState(() => _visibleItems = i - 1);
      await Future<void>.delayed(FloatingPanel.itemDelay);
    }
  }
}

class _FloatingVerticalMoreToolbarState extends State<FloatingVerticalMoreToolbar>
    with _ToolbarExpansionState<FloatingVerticalMoreToolbar> {
  @override
  List<Widget> get items => widget.children;

  @override
  Widget build(final BuildContext context) => _ToolbarSurface(
    isOpen: _isOpen,
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: _isOpen ? FloatingPanel.itemPadding : 0),
      child: AnimatedSize(
        duration: FloatingPanel.surfaceAnimationDuration,
        curve: Curves.easeInOut,
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(
              itemCount,
              (final index) => _AnimatedVerticalToolbarItem(
                isVisible: index < _visibleItems,
                child: _CloseOnPointerUp(
                  onClose: _animateClose,
                  child: _VerticalToolbarItem(child: items[index]),
                ),
              ),
            ),
            _VerticalToolbarItem(
              child: IconButton(
                style: _isOpen ? selectedToolbarIconButtonStyle(context) : null,
                icon: const Icon(Icons.more_vert),
                onPressed: _toggle,
                tooltip: _isOpen ? widget.closeTooltip : widget.moreTooltip,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

ButtonStyle selectedToolbarIconButtonStyle(final BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(colorScheme.onPrimaryContainer),
    foregroundColor: WidgetStatePropertyAll(colorScheme.primaryContainer),
    overlayColor: WidgetStatePropertyAll(colorScheme.primaryContainer.withValues(alpha: 0.10)),
    shape: const WidgetStatePropertyAll(CircleBorder()),
    padding: const WidgetStatePropertyAll(EdgeInsets.zero),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    minimumSize: const WidgetStatePropertyAll(Size.square(FloatingPanel.buttonSize)),
    fixedSize: const WidgetStatePropertyAll(Size.square(FloatingPanel.buttonSize)),
  );
}

class _ToolbarSurface extends StatelessWidget {
  const _ToolbarSurface({required this.child, required this.isOpen});

  final Widget child;
  final bool isOpen;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = isOpen ? FloatingPanel.panelRadius : FloatingPanel.compactPanelRadius;
    final borderRadius = BorderRadius.circular(radius);
    return AnimatedContainer(
      duration: FloatingPanel.surfaceAnimationDuration,
      curve: Curves.easeInOut,
      decoration: ShapeDecoration(
        color: colorScheme.primaryContainer,
        shadows: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.24),
            blurRadius: isOpen ? 12 : 8,
            offset: Offset(0, isOpen ? 4 : 2),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      ),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        clipBehavior: Clip.antiAlias,
        child: IconButtonTheme(
          data: _toolbarIconButtonTheme(context),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: FloatingPanel.verticalPadding,
              horizontal: isOpen ? FloatingPanel.horizontalPadding : FloatingPanel.verticalPadding,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

IconButtonThemeData _toolbarIconButtonTheme(final BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return IconButtonThemeData(
    style: IconButton.styleFrom(
      backgroundColor: Colors.transparent,
      disabledBackgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onPrimaryContainer,
      disabledForegroundColor: colorScheme.onPrimaryContainer.withValues(alpha: 0.38),
      hoverColor: colorScheme.onPrimaryContainer.withValues(alpha: 0.08),
      focusColor: colorScheme.onPrimaryContainer.withValues(alpha: 0.10),
      highlightColor: colorScheme.onPrimaryContainer.withValues(alpha: 0.10),
      shape: const CircleBorder(),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: const Size.square(FloatingPanel.buttonSize),
      fixedSize: const Size.square(FloatingPanel.buttonSize),
    ),
  );
}

class _HorizontalToolbarItem extends StatelessWidget {
  const _HorizontalToolbarItem({required this.child});

  final Widget child;

  @override
  Widget build(final BuildContext context) => SizedBox(
    width: FloatingPanel.itemExtent,
    height: FloatingPanel.itemExtent,
    child: Padding(padding: const EdgeInsets.all(FloatingPanel.itemPadding), child: child),
  );
}

class _VerticalToolbarItem extends StatelessWidget {
  const _VerticalToolbarItem({required this.child});

  final Widget child;

  @override
  Widget build(final BuildContext context) => SizedBox(
    width: FloatingPanel.morePanelWidth,
    height: FloatingPanel.itemExtent,
    child: Center(child: child),
  );
}

class _CloseOnPointerUp extends StatelessWidget {
  const _CloseOnPointerUp({required this.child, required this.onClose});

  final Widget child;
  final Future<void> Function() onClose;

  @override
  Widget build(final BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerUp: (final event) {
      Future<void>.delayed(Duration.zero, onClose);
    },
    child: child,
  );
}

class _AnimatedHorizontalToolbarItem extends StatelessWidget {
  const _AnimatedHorizontalToolbarItem({required this.isVisible, required this.width, required this.child});

  final bool isVisible;
  final double width;
  final Widget child;

  @override
  Widget build(final BuildContext context) => IgnorePointer(
    ignoring: !isVisible,
    child: AnimatedContainer(
      duration: FloatingPanel.itemAnimationDuration,
      curve: Curves.easeInOut,
      width: isVisible ? width : 0,
      height: FloatingPanel.itemExtent,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(),
      child: OverflowBox(alignment: Alignment.centerRight, minWidth: width, maxWidth: width, child: child),
    ),
  );
}

class _AnimatedVerticalToolbarItem extends StatelessWidget {
  const _AnimatedVerticalToolbarItem({required this.isVisible, required this.child});

  final bool isVisible;
  final Widget child;

  @override
  Widget build(final BuildContext context) => IgnorePointer(
    ignoring: !isVisible,
    child: AnimatedContainer(
      duration: FloatingPanel.itemAnimationDuration,
      curve: Curves.easeInOut,
      width: FloatingPanel.morePanelWidth,
      height: isVisible ? FloatingPanel.itemExtent + FloatingPanel.verticalItemSpacing : 0,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: FloatingPanel.verticalItemSpacing),
          child: child,
        ),
      ),
    ),
  );
}

class _ToolbarGroupOutlinePainter extends CustomPainter {
  const _ToolbarGroupOutlinePainter({required this.color});

  final Color color;

  @override
  void paint(final Canvas canvas, final Size size) {
    const strokeWidth = 1.0;
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final radius = FloatingPanel.buttonSize / 2 + FloatingPanel.itemPadding - strokeWidth / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), paint);
  }

  @override
  bool shouldRepaint(final _ToolbarGroupOutlinePainter oldDelegate) => oldDelegate.color != color;
}

Widget _asHorizontalToolbarItem(final Widget child) =>
    child is ToolbarControlGroup ? child : _HorizontalToolbarItem(child: child);

double _horizontalItemWidth(final Widget child) =>
    child is ToolbarControlGroup ? child.width : FloatingPanel.itemExtent;
