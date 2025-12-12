import 'package:flutter/widgets.dart';

typedef LifecycleCallback = void Function(AppLifecycleState state);

class LifecycleService {
  LifecycleService(this._onStateChanged) {
    _listener = AppLifecycleListener(
      onStateChange: _onStateChanged,
    );
  }

  final LifecycleCallback _onStateChanged;

  late final AppLifecycleListener _listener;

  void dispose() {
    _listener.dispose();
  }
}