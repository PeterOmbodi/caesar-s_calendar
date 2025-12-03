import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:caesar_puzzle/presentation/widgets/how_to_play_hint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../../generated/l10n.dart';

class FloatingPanel extends StatefulWidget {
  const FloatingPanel({super.key, required this.children});

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
  Widget build(final BuildContext context) =>
      ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery
              .of(context)
              .size
              .width - 24,
        ),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          color: AppColors.current.primary.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisSize: _isPanelOpen ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: _isPanelOpen ? 1 : 0,
                  child: SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      padding: EdgeInsetsGeometry.symmetric(vertical: 4),
                      children: [
                        IconButton(
                          icon: const Icon(Icons.info_outline_rounded),
                          onPressed: () async {
                            await showDialog(
                              context: context,
                              builder: (final context) =>
                                  PlatformAlertDialog(
                                    title: const Text('How to Play'),
                                    content: const HowToPlayHint(),
                                    actions: [
                                      PlatformDialogAction(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: Text(S
                                            .of(context)
                                            .ok),
                                      ),
                                    ],
                                  ),
                            );
                          },
                        ),
                        if (_isPanelOpen) ...widget.children,
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isPanelOpen
                        ? const Icon(Icons.close)
                        : const Icon(Icons.menu),
                  ),
                  onPressed: _togglePanel,
                  tooltip: _isPanelOpen
                      ? S.current.hideControls
                      : S.current.showControls,
                ),
              ],
            ),
          ),
        ),
      );
}
