import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Transparent system bars over the app background.
class SystemBars extends StatefulWidget {
  const SystemBars({super.key, required this.child});

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
  @override
  void initState() {
    super.initState();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  Widget build(final BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemBars.styleFor(Theme.of(context).brightness),
    child: widget.child,
  );
}
