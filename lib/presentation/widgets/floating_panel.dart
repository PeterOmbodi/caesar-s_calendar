import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:flutter/material.dart';

import '../../generated/l10n.dart';

class FloatingPanel extends StatefulWidget {

  const FloatingPanel({super.key, required this.children});

  static const widgetSpacing = 4.0;

  final List<Widget> children;

  @override
  FloatingPanelState createState() => FloatingPanelState();
}

class FloatingPanelState extends State<FloatingPanel> {


  bool _isPanelOpen = false;

  void _togglePanel() {
    setState(() {
      _isPanelOpen = !_isPanelOpen;
    });
  }

  @override
  Widget build(final BuildContext context) => Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        color: AppColors.current.primary.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: FloatingPanel.widgetSpacing,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                child: _isPanelOpen
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        spacing: FloatingPanel.widgetSpacing,
                        children: widget.children,
                      )
                    : SizedBox.shrink(),
              ),
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isPanelOpen ? Icon(Icons.close) : Icon(Icons.menu),
                ),
                onPressed: _togglePanel,
                tooltip: _isPanelOpen ? S.current.hideControls : S.current.showControls,
              ),
            ],
          ),
        ));
}
