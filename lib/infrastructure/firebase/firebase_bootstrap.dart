import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult({required this.enabled, this.error});

  final bool enabled;
  final Object? error;
}

class FirebaseBootstrap {
  static bool _initialized = false;
  static FirebaseBootstrapResult? _result;

  static FirebaseBootstrapResult? get result => _result;

  static Future<FirebaseBootstrapResult> ensureInitialized() async {
    if (_initialized && _result != null) return _result!;
    _initialized = true;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _result = const FirebaseBootstrapResult(enabled: true);
      return _result!;
    } catch (e) {
      // Keep app usable without Firebase config (local-only mode).
      debugPrint('Firebase init skipped/failed: $e');
      _result = FirebaseBootstrapResult(enabled: false, error: e);
      return _result!;
    }
  }
}

