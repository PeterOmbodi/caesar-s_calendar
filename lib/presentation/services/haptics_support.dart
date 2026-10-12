import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// iPads have no haptic engine, so iOS asks the system.
class HapticsSupport {
  HapticsSupport._() {
    if (kIsWeb) {
      return;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        _channel
            .invokeMethod<bool>('supportsHaptics')
            .then((final value) => available.value = value ?? false, onError: (final Object _) {});
      case TargetPlatform.android:
        available.value = true;
      case TargetPlatform.fuchsia || TargetPlatform.macOS || TargetPlatform.windows || TargetPlatform.linux:
        break;
    }
  }

  static final HapticsSupport instance = HapticsSupport._();

  static const _channel = MethodChannel('caesar_puzzle/device');

  final ValueNotifier<bool> available = ValueNotifier(false);
}
