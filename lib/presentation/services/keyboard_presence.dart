import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Whether a hardware keyboard is attached, for showing shortcut hints.
///
/// iOS reports it through a platform channel. Android has no such signal, so a
/// keyboard counts as attached after its first key press. Web and desktop
/// always have one.
class KeyboardPresence {
  KeyboardPresence._() {
    switch (defaultTargetPlatform) {
      case _ when kIsWeb:
        connected.value = true;
      case TargetPlatform.iOS:
        _channel.receiveBroadcastStream().listen(
          (final value) => connected.value = value == true,
          onError: (final Object _) {},
        );
      case TargetPlatform.android || TargetPlatform.fuchsia:
        HardwareKeyboard.instance.addHandler(_onKey);
      case TargetPlatform.macOS || TargetPlatform.windows || TargetPlatform.linux:
        connected.value = true;
    }
  }

  static final KeyboardPresence instance = KeyboardPresence._();

  static const _channel = EventChannel('caesar_puzzle/keyboard');

  final ValueNotifier<bool> connected = ValueNotifier(false);

  bool _onKey(final KeyEvent event) {
    connected.value = true;
    HardwareKeyboard.instance.removeHandler(_onKey);
    return false;
  }
}
