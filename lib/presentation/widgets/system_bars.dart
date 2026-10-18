import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Transparent system bars over the app background.
/// Android phones in landscape hide the status bar, as iOS does.
class SystemBars extends StatefulWidget {
  const SystemBars({super.key, required this.child});

  static const double _phoneMaxHeight = 600;

  final Widget child;

  static SystemUiOverlayStyle styleFor(final Brightness brightness) {
    final icons = brightness == Brightness.dark ? Brightness.light : Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: brightness,
      statusBarIconBrightness: icons,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: icons,
      systemNavigationBarContrastEnforced: false,
    );
  }

  @override
  State<SystemBars> createState() => _SystemBarsState();
}

class _SystemBarsState extends State<SystemBars> {
  bool? _statusBarHidden;

  void _syncMode(final bool hideStatusBar) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android || hideStatusBar == _statusBarHidden) {
      return;
    }
    _statusBarHidden = hideStatusBar;
    SystemChrome.setEnabledSystemUIMode(
      hideStatusBar ? SystemUiMode.manual : SystemUiMode.edgeToEdge,
      overlays: hideStatusBar ? const [SystemUiOverlay.bottom] : null,
    );
  }

  @override
  Widget build(final BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    _syncMode(size.width > size.height && size.height < SystemBars._phoneMaxHeight);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemBars.styleFor(Theme.of(context).brightness),
      child: widget.child,
    );
  }
}
