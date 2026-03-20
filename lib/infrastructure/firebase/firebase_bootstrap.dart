import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult({required this.enabled, this.error});

  final bool enabled;
  final Object? error;
}

class FirebaseBootstrap {
  static const _webAppCheckSiteKey = String.fromEnvironment('FIREBASE_APPCHECK_WEB_SITE_KEY');

  static bool _initialized = false;
  static FirebaseBootstrapResult? _result;

  static FirebaseBootstrapResult? get result => _result;

  static Future<FirebaseBootstrapResult> ensureInitialized() async {
    if (_initialized && _result != null) return _result!;
    _initialized = true;

    try {
      if (Firebase.apps.isEmpty) {
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          await Firebase.initializeApp();
        } else {
          await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
        }
      }
      await _activateAppCheck();
      _result = const FirebaseBootstrapResult(enabled: true);
      return _result!;
    } catch (e) {
      // Keep app usable without Firebase config (local-only mode).
      debugPrint('Firebase init skipped/failed: $e');
      _result = FirebaseBootstrapResult(enabled: false, error: e);
      return _result!;
    }
  }

  static Future<void> _activateAppCheck() async {
    if (kIsWeb) {
      if (_webAppCheckSiteKey.isEmpty) {
        debugPrint('Firebase App Check skipped on web: FIREBASE_APPCHECK_WEB_SITE_KEY is not set.');
        return;
      }
      await FirebaseAppCheck.instance.activate(providerWeb: ReCaptchaEnterpriseProvider(_webAppCheckSiteKey));
      return;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        await FirebaseAppCheck.instance.activate();
        return;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        await FirebaseAppCheck.instance.activate(providerApple: const AppleAppAttestWithDeviceCheckFallbackProvider());
        return;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        debugPrint('Firebase App Check is not configured for this platform.');
        return;
    }
  }
}
