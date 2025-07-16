import 'package:flutter/material.dart';

class FloatingPanel extends StatefulWidget {
  const FloatingPanel({super.key, required this.children});

  final List<Widget> children;

  @override
  FloatingPanelState createState() => FloatingPanelState();
}

class FloatingPanelState extends State<FloatingPanel> {
  static const widgetSpacing = 8.0;
  late Color _backgroundColor;
  bool _isPanelOpen = false;

  void _togglePanel() {
    setState(() {
      _isPanelOpen = !_isPanelOpen;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _backgroundColor = (Theme.of(context).primaryColor).withValues(alpha: 0.8);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        color: _backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: _isPanelOpen ? widgetSpacing : 0,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: _isPanelOpen
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: widgetSpacing,
                            children: widget.children,
                          )
                        : SizedBox.shrink(),
                  ),
                  IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isPanelOpen ? Icon(Icons.close) : Icon(Icons.menu),
                      ),
                      onPressed: _togglePanel),
                ],
              ),
            ],
          ),
        ));
  }
}
