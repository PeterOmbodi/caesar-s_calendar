import 'dart:async';

import 'package:caesar_puzzle/infrastructure/sync/sync_status.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SyncStatusService {
  SyncStatus _state = SyncStatus.initial();
  final _controller = StreamController<SyncStatus>.broadcast();

  SyncStatus get state => _state;
  Stream<SyncStatus> get stream => _controller.stream;

  void setSyncing() => _emit(_state.copyWith(isSyncing: true, clearError: true));

  void setSuccess() => _emit(
        _state.copyWith(
          isSyncing: false,
          lastSuccessAtMs: DateTime.now().millisecondsSinceEpoch,
          clearError: true,
        ),
      );

  void setError(final Object error) => _emit(_state.copyWith(isSyncing: false, lastError: error.toString()));

  void _emit(final SyncStatus next) {
    _state = next;
    _controller.add(_state);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

