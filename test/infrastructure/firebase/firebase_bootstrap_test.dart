import 'package:caesar_puzzle/firebase_options.dart';
import 'package:caesar_puzzle/infrastructure/firebase/firebase_bootstrap.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses web Firebase options for web running on iOS browser', () {
    final options = FirebaseBootstrap.firebaseOptionsForPlatform(isWeb: true, targetPlatform: TargetPlatform.iOS);

    expect(options?.appId, DefaultFirebaseOptions.web.appId);
  });

  test('keeps native iOS Firebase initialization delegated to platform config', () {
    final options = FirebaseBootstrap.firebaseOptionsForPlatform(isWeb: false, targetPlatform: TargetPlatform.iOS);

    expect(options, isNull);
  });
}
